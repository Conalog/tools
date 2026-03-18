# conalog

Conalog 사내 라이브러리에서 Codex Skills, Agents를 설치·관리하는 CLI 도구.

## 설치

### macOS / Linux

```bash
curl -sSL https://raw.githubusercontent.com/Conalog/cli/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/Conalog/cli/main/install.ps1 | iex
```

또는 [GitHub Releases](https://github.com/Conalog/cli/releases)에서 바이너리를 직접 다운로드.

## 사용법


```bash
conalog login
```

브라우저가 열리고 로그인 후 자동으로 인증이 완료됩니다.

현재 인증 상태 확인:

```bash
conalog whoami
```

### 패키지 검색

```bash
conalog search code-review
```

### 설치 가능한 패키지 목록

```bash
conalog list
```

### 패키지 설치

```bash
conalog install code-reviewer              # 최신 버전 설치
conalog install code-reviewer planner      # 여러 패키지 동시 설치
```

설치 경로:
- skill → `$HOME/.agents/skills/<name>/`
- agent → `$HOME/.codex/agents/<name>.toml`

### 설치된 패키지 확인

```bash
conalog list --installed
```

### 패키지 업데이트

```bash
conalog update              # 전체 업데이트
conalog update code-reviewer  # 특정 패키지만
```

### 패키지 상세 정보

```bash
conalog info code-reviewer
```

### 패키지 삭제

```bash
conalog uninstall code-reviewer
```

### 로그아웃

```bash
conalog logout
```

## 설정

| 환경변수 | 기본값 | 설명 |
|----------|--------|------|
| `CONALOG_SERVER` | `https://library.conalog.com` | API 서버 주소 |
| `CONALOG_TOKEN` | — | 인증 토큰 (CI/CD용, `conalog login` 대체) |

인증 우선순위:
1. `CONALOG_TOKEN` 환경변수 (설정된 경우)
2. OS별 사용자 설정 디렉터리의 `conalog/auth.json` (`os.UserConfigDir()` 기준, 기존 `~/.config/conalog`도 계속 읽음)
