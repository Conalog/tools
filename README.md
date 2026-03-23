# conalog-library

사내 라이브러리에서 Codex Skills, Agents를 관리하는 인증 CLI + LLM 연동 도구.

CLI는 인증(login/logout/whoami)만 담당하고, 패키지 검색·설치·배포는 LLM이 REST API를 직접 호출하여 수행합니다.

---

## LLM 시작 가이드

**이 파일을 읽는 LLM은 아래 순서대로 진행하세요.**

### 1단계: 로그인 상태 확인

```bash
conalog-library whoami
```

- **로그인된 경우**: `Logged in as <email>` 출력 → 2단계로
- **로그인 안 된 경우**: 사용자에게 아래 명령 실행을 요청하세요.

```bash
conalog-library login   # 브라우저로 Google OAuth 인증
```

`conalog-library login`은 인증 완료 후 **API 가이드를 자동으로 출력**합니다. 출력된 가이드를 따라 패키지를 설치하세요.

### 2단계: API 가이드 가져오기

이미 로그인된 상태에서 가이드를 다시 보려면:

```bash
conalog-library login
```

> 가이드에는 패키지 검색·다운로드·설치·배포 방법이 모두 담겨 있습니다.

---

## 처음 설치하는 경우

`conalog-library` CLI가 없다면 먼저 설치합니다.

**macOS / Linux:**

```bash
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/Conalog/tools/main/install.ps1 | iex
```

설치 후 `conalog-library login`으로 인증합니다.

## CLI 명령어

```bash
conalog-library login     # Google OAuth 로그인 (완료 후 가이드 자동 출력)
conalog-library logout    # 저장된 인증 정보 삭제
conalog-library whoami    # 현재 로그인 상태 확인
```

CI/CD 환경에서는 `CONALOG_TOKEN` 환경변수로 토큰을 직접 지정할 수 있습니다.

## 설치 옵션

```bash
# 특정 버전 설치
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash -s -- --version v0.1.0

# 설치 경로 지정
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash -s -- --bin-dir ~/.local/bin
```

또는 [GitHub Releases](https://github.com/Conalog/tools/releases)에서 바이너리를 직접 다운로드.

## 설정

| 환경변수 | 설명 |
|----------|------|
| `CONALOG_SERVER` | 서버 주소 override (기본값 내장) |
| `CONALOG_TOKEN` | CI/CD용 인증 토큰 (`conalog-library login` 대체) |
