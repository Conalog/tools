# conalog

Conalog 사내 라이브러리에서 Codex Skills, Agents를 설치·관리하는 CLI 도구.

## 설치

### macOS / Linux

```bash
curl -sSL https://raw.githubusercontent.com/Conalog/tools/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/Conalog/tools/main/install.ps1 | iex
```

또는 [GitHub Releases](https://github.com/Conalog/tools/releases)에서 바이너리를 직접 다운로드.

## 사용법

### 인증

```bash
conalog login           # Google OAuth로 브라우저 인증
conalog whoami          # 현재 인증 상태 확인
conalog logout          # 저장된 인증 정보 삭제
```

### 라이브러리 (`conalog library`)

`library` (단축: `lib`) 서브커맨드로 패키지를 관리합니다.

```bash
conalog library search code-review                # 패키지/리소스 검색
conalog library list                               # 설치 가능한 패키지 목록
conalog library list --installed                   # 설치된 패키지 확인

conalog library install code-reviewer              # 최신 버전 설치
conalog library install code-reviewer planner      # 여러 패키지 동시 설치
conalog library install --all                      # 모든 패키지 설치

conalog library update                             # 전체 업데이트
conalog library update code-reviewer               # 특정 패키지만

conalog library info code-reviewer                 # 패키지 상세 정보
conalog library uninstall code-reviewer            # 패키지 삭제
```

### 패키지 배포 (`publish`)

```bash
# 디렉터리를 패키지로 배포 (자동으로 tar.gz 생성)
conalog library publish ./my-skill --slug my-skill --type skill --version 0.1.0

# tar.gz 아카이브 직접 배포
conalog library publish ./my-skill.tar.gz --slug my-skill --type skill --version 0.2.0

# 기존 패키지에 새 릴리즈 추가 (--type 생략 가능)
conalog library publish ./my-skill --slug my-skill --version 0.3.0
```

필수 플래그: `--slug`, `--version`
신규 패키지일 경우: `--type` (skill 또는 agent) 필수
선택 플래그: `--name`, `--description`, `--changelog`, `--tags`

설치 경로:
- skill → `$HOME/.agents/skills/<name>/`
- agent → `$HOME/.codex/agents/<name>.toml`

## 설정

| 환경변수 | 기본값 | 설명 |
|----------|--------|------|
| `CONALOG_SERVER` | `—` | API 서버 주소 |
| `CONALOG_TOKEN` | — | 인증 토큰 (CI/CD용, `conalog login` 대체) |

인증 우선순위:
1. `CONALOG_TOKEN` 환경변수 (설정된 경우)
2. OS별 사용자 설정 디렉터리의 `conalog/auth.json` (`os.UserConfigDir()` 기준, 기존 `~/.config/conalog`도 계속 읽음)
