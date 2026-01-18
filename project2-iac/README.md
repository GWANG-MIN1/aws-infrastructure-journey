# 🚀 Project 2. "자동화의 시작" (IaC & Container)

> 마우스 클릭(Console)에서 벗어나, **코드(Code)**로 인프라를 제어하고 **컨테이너(Docker)**로 배포 환경을 표준화하는 과정을 기록합니다.

---

## 📅 2026.01.18 (일) - Terraform 인프라 구축 & Docker 배포

### 1. 주요 작업 (Work Done)
* **Terraform을 이용한 인프라 코드화 (IaC)**
    * 기존에 수동으로 만들었던 VPC, Subnet, IGW, Route Table을 `main.tf` 코드 하나로 정의.
    * `terraform apply` 명령어 한 번으로 전체 네트워크 및 서버 환경 자동 생성 구현.
* **Docker 컨테이너화**
    * `Dockerfile` 작성: PHP 8.1 + Apache 환경을 이미지로 빌드.
    * **Docker Hub 활용:** 로컬에서 빌드한 이미지를 레지스트리에 푸시(Push)하고, 서버에서 풀(Pull) 받아 실행함으로써 "환경 불일치" 문제 해결.
* **CI/CD 기초 체험**
    * 코드를 수정한 뒤(v2), 이미지를 새로 굽고 서버에서 컨테이너만 교체하여 배포하는 롤링 업데이트 방식 실습.
* **Git 보안 설정**
    * `.gitignore`를 통해 민감한 파일(`*.pem`, `*.tfstate`) 업로드 차단.

### 2. 트러블 슈팅 (Troubleshooting)

#### 🔥 이슈 1: GitHub Push Protection (AWS 키 노출 사고)
* **문제:** `git push` 시도 시 *"Push cannot contain secrets"* 에러 발생하며 거부됨.
* **원인:** `main.tf` 파일 내에 AWS Access Key를 하드코딩한 채로 커밋(Commit)하여, 이후에 코드를 지웠음에도 **과거의 커밋 기록(History)**에 키가 남아있어 보안 필터에 걸림.
* **해결:**
    1. `git reset`으로 되돌리려 했으나 꼬인 히스토리가 해결되지 않음.
    2. `rm -rf .git` 명령어로 로컬 Git 기록을 초기화(Hard Reset) 후 재설정.
    3. `main.tf`에서 키를 완전히 삭제하고 환경 변수(`export`) 방식으로 변경 후 재업로드 성공.

#### 🔒 이슈 2: Terraform 인증 오류
* **문제:** 보안을 위해 코드에서 키를 지우자 `terraform apply`가 실행되지 않음.
* **해결:** 터미널 세션에 환경 변수(`AWS_ACCESS_KEY_ID` 등)를 임시로 등록하여, 코드는 안전하게 유지하면서 테라폼이 권한을 갖도록 조치함.

### 3. 배운 점 (Key Takeaways)
* **IaC의 강력함:** 콘솔에서 30분 걸리던 작업이 `terraform apply` 엔터 한 번에 1분 만에 끝나는 것을 보고 자동화의 필요성을 체감함.
* **컨테이너의 일관성:** "내 컴퓨터에선 되는데 서버에선 안 돼요"라는 말이 Docker를 쓰면 사라진다는 것을 직접 확인함.
* **보안의 중요성:** 깃허브의 보안 정책(Push Protection)을 직접 뚫어보며, 클라우드 엔지니어에게 보안 의식이 얼마나 중요한지 깨달음.