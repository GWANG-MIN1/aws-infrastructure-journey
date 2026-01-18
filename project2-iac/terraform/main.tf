# 1. 공급자 설정
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 2. 리전 및 키 설정
provider "aws" {
  region     = "ap-northeast-2"
}

# [데이터 소스] 최신 Amazon Linux 2023 자동 검색
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 3. VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "terraform-vpc" }
}

# 4. Public Subnet 생성 (AZ 지정 삭제: AWS가 알아서 고르게 함)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  # availability_zone     = "ap-northeast-2a" <--- 이거 지웠습니다! (에러 원인 중 하나)

  tags = { Name = "terraform-public-subnet" }
}

# 5. 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "terraform-igw" }
}

# 6. 라우팅 테이블
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "terraform-public-rt" }
}

# 7. 서브넷 연결
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# 8. 보안 그룹
resource "aws_security_group" "web_sg" {
  name        = "terraform-web-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
  tags = { Name = "terraform-sg" }
}

# 9. EC2 인스턴스 (핵심 수정!)
resource "aws_instance" "web" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t3.micro"  # t3로 변경

  # ★ 핵심: t3의 무제한 모드를 끄고 'standard'로 설정 (무료 조건 충족)
  credit_specification {
    cpu_credits = "standard"
  }

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 80:80 nginx
              EOF

  tags = { Name = "terraform-web-server" }
}

# 10. 출력
output "public_ip" {
  value = aws_instance.web.public_ip
}
