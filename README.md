# AWS Infrastructure Journey 🚀

> **수동 배포 → IaC(Terraform) → CI/CD 자동화**로 한 걸음씩 고도화하는 AWS 클라우드 인프라 학습 저장소

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-%235835CC.svg?logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-%230db7ed.svg?logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-%232671E5.svg?logo=githubactions&logoColor=white)

---

## 📑 목차
- [개요](#-개요)
- [전체 아키텍처](#-전체-아키텍처-project-3-기준)
- [프로젝트 로드맵](#-프로젝트-로드맵)
- [기술 스택](#-사용-기술-스택)
- [디렉토리 구조](#-디렉토리-구조)
- [실행 방법](#-실행-방법)
- [비용 주의사항](#-비용-주의사항)
- [전체 회고](#-전체-회고-key-takeaways)

---

## 🎯 개요

세 단계의 미니 프로젝트를 통해 클라우드 인프라가 **"콘솔 클릭 → 코드 → 자동화"** 로 진화하는 과정을 직접 체험한 기록입니다. 각 프로젝트는 **이전 단계의 한계**를 해결하는 방향으로 설계되었습니다.

| 단계 | 한계 | 다음 단계의 해결책 |
|------|------|--------------------|
| Project 1 (수동) | 재현 불가, 인적 실수 | → IaC |
| Project 2 (IaC)  | 단일 EC2, 수동 배포 | → ALB + ASG + CI/CD |
| Project 3 (HA + CI/CD) | — (현재 도달 지점) | — |

---

## 🗺️ 전체 아키텍처 (Project 3 기준)

```
                                ┌────────────────────────────────────────────┐
                                │                   AWS Cloud                │
                                │                                            │
  Developer ── git push ──▶ GitHub                                           │
                                │     │                                       │
                                │     ▼                                       │
                                │  GitHub Actions ── Docker Hub ── ASG Refresh
                                │                                             │
  User ──── Internet ─────────▶ │  [ALB] ─┬──▶ [EC2 in AZ-a] ─┐               │
                                │         └──▶ [EC2 in AZ-c] ─┤               │
                                │              (Auto Scaling: 2~4대)          │
                                └────────────────────────────────────────────┘
```

> 📷 Project 1 단계의 상세 다이어그램은 [`project1-manual/diagrams/project1-architecture.png`](./project1-manual/diagrams/project1-architecture.png) 참고

---

## 📚 프로젝트 로드맵

### ✅ Project 1 · "맨땅에 헤딩" — 수동 배포 및 망 분리
> 📂 [`project1-manual/`](./project1-manual/) · 📖 [상세 일지 보기](./project1-manual/README.md)

- **목표:** AWS 콘솔과 리눅스 명령어로 3-Tier 네트워크를 직접 구축
- **핵심 기술:** VPC, Subnet, Route Table, IGW, EC2(Nginx), RDS(MySQL), Security Group

```
VPC (10.0.0.0/16)
├── Public Subnet  (10.0.1.0/24) ── EC2 Web Server (Nginx)
│       └── SG: 80, 443, 22 허용
└── Private Subnet (10.0.2.0/24) ── RDS MySQL
        └── SG: 3306 — EC2 보안그룹에서만 인바운드 허용
```

**의사결정 근거**

| 결정 | 이유 |
|------|------|
| RDS를 Private Subnet에 배치 | DB는 외부 직접 접근 불가. Public 노출 시 무차별 대입 공격 위험 |
| EC2 ↔ RDS 보안그룹 체이닝 | 최소 권한 원칙. IP가 아닌 **SG ID**로 허용해 신규 인스턴스도 자동 적용 |
| 단일 AZ로 시작 | 학습 단계라 비용 최소화. Project 3에서 Multi-AZ로 확장 |

---

### ✅ Project 2 · "서버를 코드로" — Docker & Terraform (IaC)
> 📂 [`project2-iac/`](./project2-iac/) · 📖 [상세 일지 보기](./project2-iac/README.md)

- **목표:** 인프라를 코드로 관리(IaC)하고 컨테이너 기반 배포 환경 구성
- **핵심 기술:** Terraform, Docker, Amazon Linux 2023, Docker Hub

```
project2-iac/
├── terraform/
│   └── main.tf       # VPC, Subnet, IGW, RT, SG, EC2 (단일 파일)
├── docker/           # 컨테이너 관련 리소스
└── src/              # 애플리케이션 소스
```

> 💡 현재 Terraform 코드는 학습 편의를 위해 `main.tf` 단일 파일로 작성되어 있습니다. 다음 단계로 `vpc.tf` / `ec2.tf` / `security.tf` 등으로 모듈 분리 예정.

**의사결정 근거**

| 결정 | 이유 |
|------|------|
| Terraform 선택 (vs CloudFormation) | 멀티 클라우드 지원, HCL 가독성, 실무 범용성 |
| Docker로 환경 표준화 | "내 컴에선 되는데" 문제 제거. 로컬 = 운영 동일 환경 |
| t3.micro + `cpu_credits = "standard"` | 프리티어 조건 충족 (Unlimited 모드 끄기) |
| `.terraform.lock.hcl` 버전 고정 | provider 버전 변경에 따른 재현 불가 방지 |

---

### ✅ Project 3 · "절대 죽지 않는 서비스" — 고가용성 & CI/CD 자동화
> 📂 [`project3-cicd/`](./project3-cicd/) · 📖 [상세 일지 보기](./project3-cicd/README.md)

- **목표:** 트래픽 분산(ALB), 자동 확장(ASG), 무중단 배포(GitHub Actions)
- **핵심 기술:** ALB, Auto Scaling Group, Launch Template, GitHub Actions, Instance Refresh

**CI/CD 파이프라인**

```
git push (main)
    │
    ▼
GitHub Actions (.github/workflows/deploy.yml)
    ├── 1. 체크아웃
    ├── 2. Docker Hub 로그인
    ├── 3. my-portfolio 이미지 빌드 & Push (tag: v1)
    ├── 4. AWS 인증 (aws-actions/configure-aws-credentials)
    └── 5. aws autoscaling start-instance-refresh
              (MinHealthyPercentage: 50, InstanceWarmup: 60s)
                  │
                  ▼
            ASG가 EC2를 순차 교체 → ALB가 새 인스턴스로 트래픽 전환
```

**의사결정 근거**

| 결정 | 이유 |
|------|------|
| ALB + ASG (Min 2 / Max 4) | 단일 EC2는 SPOF. 최소 2대로 가용성 확보, 최대 4대로 비용 통제 |
| ASG 서브넷을 AZ-a / AZ-c에 분산 | 단일 AZ 장애 대비. ALB도 동일한 두 서브넷에 배치 |
| GitHub Actions 선택 (vs Jenkins) | 별도 서버 불필요, Secrets 관리·저장소 통합 |
| Instance Refresh 방식 배포 | Rolling Update — 다운타임 없이 ASG 자체 기능으로 교체 |
| `paths-ignore: README.md` | 문서 수정으로 불필요한 배포 트리거 방지 |

---

## 🛠️ 사용 기술 스택

| 분류 | 기술 |
|------|------|
| Cloud | AWS (VPC, EC2, RDS, ALB, Auto Scaling, IAM) |
| IaC | Terraform `~> 5.0` (AWS Provider) |
| Container | Docker, Docker Hub |
| CI/CD | GitHub Actions |
| OS | Amazon Linux 2023 |
| DB | MySQL (RDS) |
| App | PHP 8.0 + Apache (my-portfolio) |
| Region | `ap-northeast-2` (Seoul) |

---

## 📁 디렉토리 구조

```
aws-infrastructure-journey/
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD 워크플로우 (Project 3)
├── my-portfolio/               # 배포 대상 PHP 애플리케이션
│   ├── Dockerfile              # php:8.0-apache 기반
│   └── index.php
├── project1-manual/            # 수동 배포 기록
│   ├── README.md
│   └── diagrams/
│       └── project1-architecture.png
├── project2-iac/               # Terraform IaC
│   ├── README.md
│   ├── terraform/
│   │   └── main.tf
│   ├── docker/
│   └── src/
├── project3-cicd/              # 고가용성 + CI/CD
│   ├── README.md
│   └── main.tf                 # ALB + ASG + Launch Template
├── .terraform.lock.hcl
├── .gitignore
└── README.md
```

---

## 🚀 실행 방법

### 사전 준비

```bash
# 1. AWS 자격 증명 설정 (코드에 키를 하드코딩하지 마세요)
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=ap-northeast-2

# 2. Terraform 설치 확인
terraform version   # >= 1.5 권장
```

### Project 2 (IaC) 배포

```bash
cd project2-iac/terraform
terraform init
terraform plan
terraform apply
# 출력된 public_ip로 접속 → "Welcome to nginx!" 확인

terraform destroy   # 실습 종료 후 반드시 실행 (비용 절감)
```

### Project 3 (HA + CI/CD) 배포

```bash
cd project3-cicd
terraform init
terraform apply
# 출력된 alb_dns_name으로 접속

terraform destroy
```

### CI/CD 동작시키기

GitHub 저장소 **Settings → Secrets** 에 등록 필요:

| Secret 이름 | 용도 |
|-------------|------|
| `DOCKER_USERNAME` | Docker Hub 계정 |
| `DOCKER_PASSWORD` | Docker Hub 토큰 |
| `AWS_ACCESS_KEY_ID` | ASG Instance Refresh 권한 |
| `AWS_SECRET_ACCESS_KEY` | 동일 |

`main` 브랜치에 push 하면 자동으로 빌드 → 푸시 → 배포가 실행됩니다 (`README.md` / `docs/**` 변경은 제외).

---

## 💸 비용 주의사항

> ⚠️ **모든 실습 종료 후 반드시 `terraform destroy` 를 실행하세요.**

- **ALB**: 시간당 약 $0.0225 + 데이터 처리 비용 (프리티어 미적용)
- **RDS**: 인스턴스 가동 시간만큼 과금
- **EC2 t3.micro**: 프리티어 한도(월 750시간) 초과 시 과금
- **Elastic IP**: 인스턴스에 연결되지 않은 채 보유 시 시간당 과금

`terraform destroy` 후 AWS 콘솔에서 **남아있는 EBS 볼륨, 스냅샷, Elastic IP** 도 확인 권장.

---

## 🧠 전체 회고 (Key Takeaways)

세 프로젝트를 거치며 얻은 인사이트:

1. **IaC의 위력** — 콘솔로 30분 걸리던 환경이 `terraform apply` 1분으로 단축. 더 중요한 건 **재현성**.
2. **컨테이너는 환경 통일의 종결자** — "내 컴에선 되는데" 가 사라짐.
3. **보안은 코드에 적기 전부터 시작** — Push Protection으로 키 노출을 차단당한 경험이 환경변수 분리 습관을 만들어줌. ([Project 2 트러블슈팅](./project2-iac/README.md#-이슈-1-github-push-protection-aws-키-노출-사고))
4. **SPOF 제거의 체감** — 서버 1대 → 2대(ALB+ASG)로 갔을 때, 한 대를 강제 종료해도 서비스가 살아있는 걸 보고 "고가용성"이 와닿음.
5. **Health Check Grace Period** — 배포 직후 503 에러의 원인. 컨테이너 부팅 시간을 인프라가 알아야 한다는 것. ([Project 3 트러블슈팅](./project3-cicd/README.md#-이슈-2-배포-직후-502503-에러))

---

## 🔮 다음 단계 (Backlog)

- [ ] Terraform 코드 모듈 분리 (`vpc.tf`, `ec2.tf`, `security.tf`)
- [ ] Remote State (S3 + DynamoDB Lock) 도입
- [ ] HTTPS (ACM + ALB Listener 443) 적용
- [ ] CloudWatch 알람 + SNS 알림 연동
- [ ] RDS Multi-AZ 전환 및 읽기 전용 복제본 추가
- [ ] Blue/Green 배포 (CodeDeploy) 비교 실습
