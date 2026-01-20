# 🚀 Project 3. "절대 죽지 않는 서비스" - 고가용성(HA) & CI/CD 파이프라인

> **목표:** 트래픽이 몰려도 서버가 터지지 않는 **고가용성 아키텍처**를 구축하고, 코드 수정부터 배포까지의 전 과정을 **100% 자동화**합니다.

---

## 📅 2026.01.20 (화) - Auto Scaling & GitHub Actions 구축

### 1. 아키텍처 변화 (Architecture Evolution)
* **Before (Project 2):** 사용자 ➔ EC2 (1대) (서버 죽으면 서비스 중단)
* **After (Project 3):** 사용자 ➔ **Load Balancer (ALB)** ➔ **Auto Scaling Group** ➔ **EC2 (2대 이상)**
    * **Traffic Distribution:** 로드밸런서가 트래픽을 여러 서버로 분산 처리.
    * **Self-Healing:** 서버 하나가 고장 나면 Auto Scaling이 감지하고 즉시 새 서버를 생성하여 복구.

### 2. 주요 작업 (Work Done)

#### 🏗️ Terraform: 고가용성 인프라 구축
* **ALB (Application Load Balancer):** 외부 트래픽을 받는 단일 진입점 생성.
* **Auto Scaling Group (ASG):**
    * `Min: 2`, `Max: 4` 설정으로 항상 최소 2대의 서버가 가동되도록 유지.
    * **Launch Template:** "Amazon Linux 2023 + Docker + 최신 웹 이미지"가 포함된 서버 붕어빵 틀 정의.
* **VPC & Subnet:** 가용 영역(AZ) A와 C에 서브넷을 분산 배치하여 데이터 센터 재해에 대비.

#### 🤖 GitHub Actions: CI/CD 파이프라인 완성
* **Workflow (`deploy.yml`) 작성:**
    1.  `git push` 감지 시 자동 실행.
    2.  **Docker Build & Push:** 코드를 기반으로 이미지를 새로 굽고 Docker Hub에 업로드.
    3.  **Deploy to AWS:** AWS API를 호출하여 ASG에게 **"Instance Refresh(인스턴스 물갈이)"** 명령 전달.
    4.  **Zero-Touch Deployment:** 개발자가 서버에 접속하지 않아도 최신 버전이 라이브 서버에 반영됨.

### 3. 트러블 슈팅 (Troubleshooting)

#### 📛 이슈 1: Docker 이미지 네이밍 규칙 위반
* **문제:** `Docker build` 시 대문자가 포함된 아이디(`GWANG-MIN1`)를 사용하여 빌드 실패.
* **원인:** Docker Registry는 이미지 태그에 **소문자**만 허용함.
* **해결:** Terraform 코드와 Docker 명령어의 아이디를 모두 소문자(`gwang-min1`)로 통일하여 해결.

#### ⏳ 이슈 2: 배포 직후 502/503 에러
* **문제:** 배포가 완료되었다고 떴는데 브라우저에서는 `503 Service Unavailable` 발생.
* **원인:** EC2가 켜지는 속도보다, 내부에서 `Docker`를 설치하고 컨테이너를 띄우는 속도가 더 느려서, 로드밸런서가 "아직 준비 안 됨(Initial)"으로 판단함.
* **해결:** `Health Check`가 통과될 때까지 약 3~5분의 대기 시간이 필요함을 확인. (운영 환경에서는 `Health Check Grace Period` 조정 필요성 학습)

#### ⚔️ 이슈 3: Git Push 충돌 (Non-fast-forward)
* **문제:** GitHub 웹에서 Secrets 설정을 하거나 파일을 건드린 후, 로컬에서 Push 하려니 충돌 발생.
* **해결:** 로컬 환경이 '진실(Source of Truth)'임을 확신하고 `git push -f origin main`으로 강제 동기화.

### 4. 최종 성과 (Results)
* **자동화 달성:** 코드 한 줄 수정 후 `git push`만 하면, 약 5분 뒤 전 세계에 배포된 모든 서버가 자동으로 최신화됨. ("Made by Auto CI/CD" 확인 완료)
* **안정성 확보:** 서버 한 대를 강제로 종료해도, 서비스 중단 없이 자동으로 복구되는 것을 확인함.

---

## 🛠️ Tech Stack Integration

| Component | Technology | Role |
| :--- | :--- | :--- |
| **Orchestration** | **GitHub Actions** | CI/CD 파이프라인 실행 (Build ➔ Push ➔ Deploy) |
| **Infrastructure** | **Terraform** | ALB, ASG, Launch Template 코드형 관리 |
| **Compute** | **AWS EC2 (Auto Scaling)** | 트래픽에 따라 늘어나고 줄어드는 서버 그룹 |
| **Traffic** | **AWS ALB** | 부하 분산 및 헬스 체크(Health Check) |
| **Container** | **Docker** | 애플리케이션 실행 환경 표준화 |
