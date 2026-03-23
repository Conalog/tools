# conalog

사내 라이브러리에서 Codex Skills, Agents를 설치·관리하는 CLI 도구.

## Quick Setup

아래 명령어를 순서대로 실행하면 CLI 설치부터 스킬 설정까지 완료됩니다.

```bash
# 1. CLI 설치 (macOS/Linux)
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash

# 2. 로그인 (Google OAuth, 브라우저가 자동으로 열림)
conalog login

# 3. 모든 스킬/에이전트 설치
conalog library install --all
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/Conalog/tools/main/install.ps1 | iex
conalog login
conalog library install --all
```

설치된 스킬과 에이전트는 즉시 사용할 수 있습니다.

## 설치 옵션

특정 버전을 설치하거나 바이너리를 직접 다운로드할 수 있습니다.

```bash
# 특정 버전 설치
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash -s -- --version v0.1.0

# 설치 경로 지정
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash -s -- --bin-dir ~/.local/bin
```

또는 [GitHub Releases](https://github.com/Conalog/tools/releases)에서 바이너리를 직접 다운로드.

## 사용법

### 인증

```bash
conalog login          # Google OAuth 로그인
conalog whoami         # 현재 인증 상태 확인
conalog logout         # 저장된 인증 정보 삭제
```

### 라이브러리 (`conalog library` / `conalog lib`)

```bash
conalog library search <query>          # 패키지/리소스 검색
conalog library list                    # 설치 가능한 패키지 목록
conalog library list --installed        # 로컬에 설치된 패키지 확인

conalog library install <slug>          # 최신 버전 설치
conalog library install <a> <b>         # 여러 패키지 동시 설치
conalog library install --all           # 모든 패키지 일괄 설치

conalog library update                  # 설치된 모든 패키지 업데이트
conalog library update <slug>           # 특정 패키지만 업데이트

conalog library info <slug>             # 패키지 상세 정보
conalog library uninstall <slug>        # 패키지 제거
```

### 설치 경로

| 타입 | 경로 |
|------|------|
| Skill | `~/.agents/skills/<slug>/` (디렉토리) |
| Agent | `~/.codex/agents/<slug>.toml` (단일 파일) |

## 패키지 배포

```bash
# 디렉토리를 패키지로 배포 (자동으로 tar.gz 생성)
conalog library publish ./my-skill \
  --slug my-skill --type skill --version 0.1.0

# 기존 패키지에 새 릴리즈 추가 (--type 생략 가능)
conalog library publish ./my-skill \
  --slug my-skill --version 0.2.0 --changelog "버그 수정"
```

| 플래그 | 설명 |
|--------|------|
| `--slug` | 패키지 식별자 (필수) |
| `--type` | `skill` 또는 `agent` (신규 패키지 시 필수) |
| `--version` | 버전 문자열 (필수) |
| `--name` | 표시 이름 |
| `--description` | 패키지 설명 |
| `--changelog` | 릴리즈 변경사항 |
| `--tags` | 쉼표 구분 태그 |

## 설정

| 환경변수 | 설명 |
|----------|------|
| `CONALOG_SERVER` | 서버 주소 override (기본값 내장) |
| `CONALOG_TOKEN` | CI/CD용 인증 토큰 (`conalog login` 대체) |
