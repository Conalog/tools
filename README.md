# Conalog tools

Conalog 운영 도구의 공개 설치 진입점을 제공한다. 각 도구의 소스 저장소와 릴리스가 실제 바이너리, 버전과 체크섬을 소유한다.

## edge-access

Edge에 SSH로 접속하는 운영자 CLI다. macOS와 Linux에서 다음 한 줄로 최신 버전을 설치하거나 갱신한다.

```bash
curl -fsSL https://raw.githubusercontent.com/Conalog/tools/main/install-edge-access.sh | bash
```

비공개 `Conalog/edge-access` 릴리스를 읽을 수 있도록 [GitHub CLI](https://cli.github.com/)에 권한 있는 계정이 하나 이상 인증돼 있어야 한다. 여러 계정이 있으면 설치 프로그램이 저장소를 읽을 수 있는 계정을 자동으로 사용한다. 전역 계정은 바꾸지 않는다. `GH_TOKEN` 또는 `GITHUB_TOKEN`을 지정하면 해당 토큰만 사용한다.

설치 프로그램은 운영체제와 CPU에 맞는 최신 바이너리를 선택하고 체크섬을 검증한 뒤 `~/.local/bin/edge-access`에 설치한다.

```bash
edge-access login
edge-access ssh <edge_id>
```

## conalog-library

사내 라이브러리에서 Codex / Claude Code Skills, Agents를 관리하는 인증 CLI.
CLI는 인증(login/logout/whoami/docs)만 담당하고, 패키지 검색·설치·배포는 LLM이 REST API를 직접 호출하여 수행합니다.

## 설치

**macOS / Linux:**

```bash
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/Conalog/tools/main/install.ps1 | iex
```

또는 [GitHub Releases](https://github.com/Conalog/tools/releases)에서 바이너리를 직접 다운로드.

```bash
# 특정 버전 설치
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash -s -- --version v0.1.0

# 설치 경로 지정
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash -s -- --bin-dir ~/.local/bin
```

## 사용법

```bash
conalog-library login     # Google OAuth 로그인 (브라우저가 자동으로 열림)
conalog-library docs      # 인증된 API 문서를 브라우저에서 열기
conalog-library logout    # 저장된 인증 정보 삭제
conalog-library whoami    # 현재 로그인 상태 확인
conalog-library auth-info # 인증 파일 경로와 서버 정보 확인
```

로그인 후 LLM이 인증된 OpenAPI 문서(`/docs`, `/openapi.json`)를 읽고 패키지를 자동으로 검색·설치합니다.

## 설정

| 환경변수 | 설명 |
|----------|------|
| `CONALOG_SERVER` | 서버 주소 override (기본값 내장) |
| `CONALOG_TOKEN` | CI/CD용 인증 토큰 (`conalog-library login` 대체) |
