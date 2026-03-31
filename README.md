# AWS Infrastructure Journey 🚀

AWS 클라우드 인프라 구축의 정석을 밟아가는 학습 여정입니다.  
**수동 배포 → IaC(Terraform) → CI/CD 자동화**까지 단계별로 고도화하는 과정을 기록합니다.

---

## 🗺️ 전체 아키텍처

```
                          ┌─────────────────────────────────────────┐
                          │              AWS Cloud                   │
                          │                                          │
  User ──── Internet ───▶ │  [Internet Gateway]                      │
                          │        │                                  │
                          │        ▼                                  │
                          │  ┌──────────────────────────────────┐    │
                          │  │  Public Subnet (10.0.1.0/24)     │    │
                          │  │  [ALB - Application Load Balancer]│    │
                          │  │  [Auto Scaling Group]             │    │
                          │  │    └── EC2 (Web Server)           │    │
                          │  └──────────────┬───────────────────┘    │
                          │                 │                         │
                          │  ┌──────────────▼───────────────────┐    │
                          │  │  Private Subnet (10.0.2.0/24)    │    │
                          │  │    RDS (MySQL) - Multi-AZ         │    │
                          │  └──────────────────────────────────┘    │
                          └─────────────────────────────────────────┘
```

---

## 📚 Project Roadmap

### ✅ [Project 1] "맨땅에 헤딩" - 수동 배포 및 네트워크 분리

- **목표:** AWS 콘솔과 리눅스 명령어로 3-Tier 아키텍처 직접 구축
- **핵심 기술:** VPC, Subnet, Route Table, EC2, RDS, Security Group

#### 🏗️ 아키텍처 구성 다이어그램

```
VPC (10.0.0.0/16)
├── Public Subnet  (10.0.1.0/24)  ── EC2 Web Server
│       └── Security Group: 80(HTTP), 443(HTTPS), 22(SSH) 허용
└── Private Subnet (10.0.2.0/24)  ── RDS MySQL
        └── Security Group: 3306 포트, EC2 보안그룹에서만 인바운드 허용
```

#### 💡 의사결정 근거

| 결정 | 이유 |
|------|------|
| RDS를 Private Subnet에 배치 | DB는 외부에서 직접 접근 불가해야 함. Public IP 노출 시 무차별 대입 공격 위험 |
| EC2와 RDS를 별도 Security Group으로 분리 | 최소 권한 원칙(Least Privilege). EC2 SG만 RDS 3306 포트 인바운드 허용 |
| 단일 AZ로 시작 | 학습 목적이므로 비용 최소화. 이후 Project 3에서 Multi-AZ로 확장 |

---

### ✅ [Project 2] "서버를 코드로" - Docker & Terraform (IaC)

- **목표:** 인프라를 코드로 관리(IaC)하고 컨테이너 기반 배포 환경 구성
- **핵심 기술:** Terraform, Docker, Docker-Compose

#### 🏗️ Terraform 리소스 구조

```
project2-iac/
├── main.tf          # Provider 설정, 전체 리소스 참조
├── vpc.tf           # VPC, Subnet, IGW, Route Table
├── ec2.tf           # EC2 인스턴스, Key Pair
├── rds.tf           # RDS 인스턴스, Subnet Group
├── security.tf      # Security Group 규칙
└── variables.tf     # 변수 선언 (AMI ID, 인스턴스 타입 등)
```

#### 💡 의사결정 근거

| 결정 | 이유 |
|------|------|
| Terraform 선택 (vs CloudFormation) | 멀티 클라우드 지원, HCL 가독성이 높음. 실무에서 범용적으로 사용됨 |
| Docker-Compose로 로컬 개발환경 통일 | "내 컴에선 되는데" 문제 제거. EC2 배포와 동일한 환경 보장 |
| `.terraform.lock.hcl` 버전 고정 | provider 버전이 바뀌면 코드가 깨질 수 있음. 재현 가능한 배포를 위해 고정 |

---

### ✅ [Project 3] "절대 죽지 않는 서비스" - 고가용성 & CI/CD 자동화

- **목표:** 트래픽 분산(ELB), 자동 확장(Auto Scaling), 배포 자동화(GitHub Actions)
- **핵심 기술:** ELB, Auto Scaling Group, GitHub Actions CI/CD

#### 🏗️ CI/CD 파이프라인 흐름

```
개발자 Push (main 브랜치)
        │
        ▼
[GitHub Actions 트리거]
        │
        ├── 1. 코드 체크아웃
        ├── 2. Docker 이미지 빌드
        ├── 3. ECR(또는 Docker Hub)에 이미지 Push
        └── 4. EC2 Auto Scaling Group에 Rolling Update 배포
```

#### 💡 의사결정 근거

| 결정 | 이유 |
|------|------|
| ALB + Auto Scaling 조합 | 트래픽 급증 시 EC2 수평 확장. 단일 EC2는 SPOF(단일 장애점)가 됨 |
| Auto Scaling 정책: CPU 70% 기준 | AWS 권고 임계값. 너무 낮으면 불필요한 비용, 너무 높으면 응답 지연 발생 |
| GitHub Actions 선택 (vs Jenkins) | 별도 서버 불필요, GitHub 저장소와 네이티브 통합. 개인 프로젝트에 최적 |
| Rolling Update 배포 전략 | 다운타임 없이 배포 가능. Blue/Green보다 인프라 비용이 적음 |

---

## 🛠️ 사용 기술 스택

| 분류 | 기술 |
|------|------|
| Cloud | AWS (VPC, EC2, RDS, ELB, Auto Scaling, IAM) |
| IaC | Terraform |
| Container | Docker, Docker-Compose |
| CI/CD | GitHub Actions |
| OS | Amazon Linux 2 |
| DB | MySQL (RDS) |
| Language | PHP, Bash |

---

## 📁 디렉토리 구조

```
aws-infrastructure-journey/
├── project1-manual/     # 수동 배포 - 콘솔 설정 스크린샷 및 명령어 정리
├── project2-iac/        # Terraform IaC 코드
├── project3-cicd/       # GitHub Actions 워크플로우
├── my-portfolio/        # 포트폴리오 페이지
└── .github/workflows/   # CI/CD 파이프라인 정의
```

---

## 🚀 실행 방법

### Terraform 배포

```bash
# 초기화
terraform init

# 플랜 확인 (실제 배포 전 변경사항 미리보기)
terraform plan

# 배포
terraform apply

# 리소스 삭제 (비용 절감)
terraform destroy
```

---

## 📈 학습 회고

| 단계 | 핵심 배움 |
|------|-----------|
| Project 1 | 네트워크 분리의 중요성. Security Group이 방화벽 역할을 한다는 것을 직접 체감 |
| Project 2 | "인프라도 코드다." Terraform으로 동일한 환경을 1분 안에 재현할 수 있음을 확인 |
| Project 3 | 고가용성과 자동화의 차이. 수동 배포 시 발생하는 휴먼에러를 CI/CD가 제거함 |
