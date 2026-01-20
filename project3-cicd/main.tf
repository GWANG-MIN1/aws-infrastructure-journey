terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 1. 가용 영역(AZ) 데이터 가져오기 (a존, c존 등을 자동으로 찾음)
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. VPC 생성 (프로젝트 3 전용)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "project3-vpc" }
}

# 3. 서브넷 2개 생성 (고가용성을 위해 서로 다른 건물(AZ)에 2개 만듦)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0] # 예: a존
  tags = { Name = "project3-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[2] # 예: c존
  tags = { Name = "project3-subnet-2" }
}

# 4. 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "project3-igw" }
}

# 5. 라우팅 테이블
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "project3-rt" }
}

# 6. 서브넷 연결 (두 서브넷 모두 인터넷 되게 설정)
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. 보안 그룹 (로드밸런서용 & 서버용)
resource "aws_security_group" "alb_sg" {
  name   = "project3-alb-sg"
  vpc_id = aws_vpc.main.id
  
  # 누구나 80포트로 들어올 수 있음 (웹사이트 대문)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name   = "project3-instance-sg"
  vpc_id = aws_vpc.main.id

  # ★보안 강화: 오직 '로드밸런서'를 통해서만 접속 가능!
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  # 관리자용 SSH (테스트용 전체 개방)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 8. 시작 템플릿 (Launch Template) - "서버 붕어빵 틀"
# Auto Scaling이 이 설정을 보고 서버를 계속 찍어냅니다.
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_launch_template" "app_template" {
  name_prefix   = "project3-template"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_sg.id]
  }

  # ★ 아래 YOUR_DOCKER_ID를 본인 아이디로 꼭 수정하세요! ★
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 80:80 gwangmon/my-portfolio:v1
              EOF
  )
}

# 9. 로드 밸런서 (ALB) - "교통 정리 경찰관"
resource "aws_lb" "main_alb" {
  name               = "project3-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "project3-alb" }
}

# 10. 타겟 그룹 - "경찰관이 안내할 목적지들"
resource "aws_lb_target_group" "app_tg" {
  name     = "project3-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 11. 리스너 - "경찰관의 귀 (80포트로 오면 타겟그룹으로 가라!)"
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 12. 오토 스케일링 그룹 (ASG) - "서버 자동 증식기"
resource "aws_autoscaling_group" "app_asg" {
  name                = "project3-asg"
  desired_capacity    = 2  # 평소에 2대 유지
  max_size            = 4  # 바쁘면 최대 4대까지
  min_size            = 2  # 한가해도 최소 2대는 유지
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns   = [aws_lb_target_group.app_tg.arn] # 생성된 서버를 로드밸런서에 자동 등록

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }
}

# 13. 출력 (로드밸런서 주소)
output "alb_dns_name" {
  value = aws_lb.main_alb.dns_name
}