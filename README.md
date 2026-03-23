# conalog-library

사내 라이브러리에서 Codex Skills, Agents를 관리하는 인증 CLI + LLM 연동 도구.

CLI는 인증(login/logout/whoami)만 담당하고, 패키지 검색·설치·배포는 LLM이 REST API를 직접 호출하여 수행합니다.

## Quick Setup

```bash
# 1. CLI 설치 (macOS/Linux)
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash

# 2. 로그인 (Google OAuth, 브라우저가 자동으로 열림)
conalog-library login
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/Conalog/tools/main/install.ps1 | iex
conalog-library login
```

로그인 후 LLM이 API 가이드를 읽고 패키지를 자동으로 검색·설치합니다.

## 설치 옵션

특정 버전을 설치하거나 바이너리를 직접 다운로드할 수 있습니다.

```bash
# 특정 버전 설치
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash -s -- --version v0.1.0

# 설치 경로 지정
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash -s -- --bin-dir ~/.local/bin
```

또는 [GitHub Releases](https://github.com/Conalog/tools/releases)에서 바이너리를 직접 다운로드.

## CLI 명령어

```bash
conalog-library login     # Google OAuth 로그인
conalog-library logout    # 저장된 인증 정보 삭제
conalog-library whoami    # 현재 인증 상태 확인
```

CI/CD 환경에서는 `CONALOG_TOKEN` 환경변수로 토큰을 직접 지정할 수 있습니다.

## LLM 연동

LLM(Claude Code, Codex 등)은 아래 엔드포인트를 통해 패키지를 관리합니다.

- **API 가이드**: `GET /api/library/guide` — 인증, 검색, 다운로드, 설치, 배포 방법을 구조화된 JSON으로 제공 (인증 불필요)
- **API 문서**: `/docs` (Swagger UI)

### 설치 경로

| 타입 | 경로 |
|------|------|
| Skill | `~/.agents/skills/<slug>/` (디렉토리) |
| Agent | `~/.codex/agents/<slug>.toml` (단일 파일) |

### 패키지 배포

LLM이 API 가이드의 publish 섹션을 참조하여 multipart POST로 배포합니다.

| 아카이브 요구사항 | |
|------|-----------|
| Skill | `SKILL.md` 필수 (YAML frontmatter: `name`, `description`) |
| Agent | `.toml` 파일 1개 이상 |

## 설정

| 환경변수 | 설명 |
|----------|------|
| `CONALOG_SERVER` | 서버 주소 override (기본값 내장) |
| `CONALOG_TOKEN` | CI/CD용 인증 토큰 (`conalog-library login` 대체) |
