# conalog-library

사내 라이브러리에서 Codex Skills, Agents를 설치·관리하는 CLI 도구.

## 명령 결정표

| 명령 | 범위 | 효과 | 인증 |
|------|------|------|------|
| `login` | 로컬 | Google OAuth 인증 정보를 로컬에 저장 | - |
| `logout` | 로컬 | 저장된 인증 정보 삭제 | - |
| `whoami` | 서버 | 현재 인증 상태 확인 | O |
| `search <query>` | 서버 | 패키지/리소스 검색 | O |
| `list` | 서버 | 설치 가능한 패키지 목록 조회 | O |
| `list --installed` | 로컬 | 로컬에 설치된 패키지 목록 확인 | - |
| `info <slug>` | 서버 | 패키지 상세 정보 조회 | O |
| `install <slug>` | 서버 → 로컬 | 서버에서 다운로드하여 로컬에 설치 | O |
| `update [slug]` | 서버 → 로컬 | 설치된 패키지를 최신 버전으로 업데이트 | O |
| `uninstall <slug>` | **로컬만** | 로컬 파일 삭제 (서버에는 영향 없음) | - |
| `publish <path>` | 로컬 → 서버 → 로컬 | 서버에 배포 후 로컬에도 자동 설치 | O |
| `deprecate <slug>` | **서버만** | 패키지에 deprecation 표시 (설치는 가능) | O |
| `unpublish <slug>` | **서버만** | 서버에서 목록 숨김 (soft-delete, 관리자 복원 가능) | O |
| `doctor` | **로컬만** | 설치 인덱스 검사/복구 (파일 삭제 없음) | - |

> **uninstall vs unpublish**
> - `uninstall`: 내 컴퓨터에서 패키지 파일을 삭제합니다. 서버의 패키지는 그대로 남아 있습니다.
> - `unpublish`: 서버에서 패키지를 숨깁니다 (soft-delete). 내 컴퓨터의 파일은 그대로 남아 있습니다.

## Quick Setup

아래 명령어를 순서대로 실행하면 CLI 설치부터 스킬 설정까지 완료됩니다.

```bash
# 1. CLI 설치 (macOS/Linux)
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash

# 2. 로그인 (Google OAuth, 브라우저가 자동으로 열림)
conalog-library login

# 3. 모든 스킬/에이전트 설치
conalog-library install --all
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/Conalog/tools/main/install.ps1 | iex
conalog-library login
conalog-library install --all
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

### `conalog-library`

```bash
# 패키지 조회
conalog-library search <query>          # 패키지/리소스 검색
conalog-library list                    # 설치 가능한 패키지 목록 (서버)
conalog-library list --installed        # 로컬에 설치된 패키지 확인
conalog-library info <slug>             # 패키지 상세 정보

# 패키지 설치/관리
conalog-library install <slug>          # 최신 버전 설치
conalog-library install <a> <b>         # 여러 패키지 동시 설치
conalog-library install --all           # 모든 패키지 일괄 설치
conalog-library update                  # 설치된 모든 패키지 업데이트
conalog-library update <slug>           # 특정 패키지만 업데이트
conalog-library uninstall <slug>        # 로컬 파일만 삭제 (서버에는 영향 없음)

# 인증
conalog-library login                   # Google OAuth 로그인
conalog-library whoami                  # 현재 인증 상태 확인
conalog-library logout                  # 저장된 인증 정보 삭제

# 배포/관리자
conalog-library publish <path>          # 서버에 배포 + 로컬 자동 설치
conalog-library unpublish <slug>        # 서버에서 목록 숨김 (soft-delete)
conalog-library deprecate <slug> -m "대체: new-skill"  # deprecation 표시
conalog-library deprecate <slug> --undo                # deprecation 해제

# 유지보수
conalog-library doctor                  # 설치 인덱스 검사/복구 (파일 삭제 없음)
```

### 설치 경로

| 타입 | 경로 |
|------|------|
| Skill | `~/.agents/skills/<slug>/` (디렉토리) |
| Agent | `~/.codex/agents/<slug>.toml` (단일 파일) |

## 패키지 배포

```bash
# 디렉토리를 패키지로 배포 (자동으로 tar.gz 생성)
conalog-library publish ./my-skill \
  --slug conalog-my-skill --type skill --version 0.1.0

# 기존 패키지에 새 릴리즈 추가 (--type 생략 가능)
conalog-library publish ./my-skill \
  --slug conalog-my-skill --version 0.2.0 --changelog "버그 수정"
```

| 플래그 | 설명 |
|--------|------|
| `--slug` | 패키지 식별자 (필수, `conalog-` 접두어) |
| `--type` | `skill` 또는 `agent` (신규 패키지 시 필수) |
| `--version` | 버전 문자열 (필수) |
| `--name` | 표시 이름 |
| `--description` | 패키지 설명 |
| `--changelog` | 릴리즈 변경사항 |
| `--tags` | 쉼표 구분 태그 |

### 아카이브 요구사항

| 타입 | 필수 파일 | 검증 규칙 |
|------|-----------|-----------|
| Skill | `SKILL.md` | YAML frontmatter 필수 (`name`, `description`). name은 소문자+숫자+하이픈, 부모 디렉토리명과 일치 |
| Agent | `.toml` 파일 | 아카이브 내 `.toml` 파일 1개 이상 존재 |

## 설정

| 환경변수 | 설명 |
|----------|------|
| `CONALOG_SERVER` | 서버 주소 override (기본값 내장) |
| `CONALOG_TOKEN` | CI/CD용 인증 토큰 (`conalog-library login` 대체) |
