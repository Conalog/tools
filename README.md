# conalog-library

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
