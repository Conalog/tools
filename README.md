# conalog-library

사내 라이브러리에서 Codex / Claude Code Skills, Agents를 관리하는 인증 CLI + LLM 연동 도구.
CLI는 인증(login/logout/whoami/guide)만 담당하고, 패키지 검색·설치·배포는 LLM이 REST API를 직접 호출하여 수행합니다.

**이 문서는 LLM(Claude Code, Codex 등)이 읽고 실행하는 운영 가이드입니다.**

---

## LLM 실행 가이드

이 파일을 읽는 LLM은 아래 순서대로 진행하세요.

### 0단계: CLI 설치 및 버전 확인

```bash
command -v conalog-library && conalog-library --version
```

- 명령이 존재하면 → 출력된 버전을 사용자에게 보여주고 최신 버전인지 확인을 요청하세요
  - 최신 버전이면 → 1단계로
  - 오래된 버전이거나 불확실하면 → 아래 설치 명령을 다시 실행하면 최신 버전으로 업데이트됩니다
- 명령이 없으면 → 아래 설치 명령을 사용자에게 안내하고 설치 완료 후 1단계로

**macOS / Linux:**

```bash
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/Conalog/tools/main/install.ps1 | iex
```

### 1단계: 로그인 상태 확인

```bash
conalog-library whoami
```

- `Logged in as <email>` 출력 → 2단계(b)로
- 그 외(`Not logged in` / `Token status: invalid or expired`) → 사용자에게 아래 명령 실행을 요청하세요

```bash
conalog-library login   # 브라우저로 Google OAuth 인증
```

로그인 완료 → 2단계(a)로

### 2단계: API 가이드 획득

**(a) 방금 `conalog-library login`을 실행한 경우:**

`login` 명령의 stdout 출력이 API 가이드(Markdown)입니다. 그 출력 내용을 가이드로 사용하세요.

**(b) 이미 로그인된 경우:**

```bash
conalog-library guide
```

> **중요: 위에서 획득한 가이드(Markdown)가 이후 모든 작업의 API 레퍼런스입니다.**
> 가이드에 패키지 검색, 다운로드, 설치, 로컬 관리, 배포 방법이 모두 포함되어 있습니다.
> 가이드 내용을 기반으로 아래 3단계를 진행하세요.

### 3단계: 사용자에게 작업 선택지 제시

가이드를 획득한 후, 사용자에게 원하는 작업을 물어보세요:

1. **패키지 검색** — 키워드로 Skills / Agents 검색
2. **설치된 패키지 확인** — 로컬에 설치된 패키지 목록 조회
3. **패키지 설치** — 특정 Skill 또는 Agent 다운로드 및 설치
4. **패키지 배포** — 새 패키지를 라이브러리에 업로드

사용자 선택에 따라 가이드의 해당 섹션(Search, Local Package Management, Download+Installation, Publish)을 참조하여 실행하세요.

---

## CLI 명령어

```bash
conalog-library login     # Google OAuth 로그인 (완료 후 가이드 자동 출력)
conalog-library guide     # API 가이드 출력 (이미 로그인된 상태에서 재획득)
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
