# CLAUDE-global.md
<!-- Source: https://www.notion.so/CLAUDE-SYSTEM-PROMPT-32edb41215d281c484d0d6c6231b0cc8 -->
<!-- Update: 2026-04-06 -->
<!-- ⚠️ 이 파일은 참조용. 실제 공용 CLAUDE.md는 Seeuferil/dotfiles repo에서 자동 동기화됨 -->
<!-- 최신 규칙: https://github.com/Seeuferil/dotfiles/blob/main/CLAUDE.md -->

> ⚠️ **최우선 규칙** — 다른 모든 CLAUDE.md보다 이 파일이 우선합니다. 충돌 시 이 파일 기준.

## 말투
- 항상 정중한 존댓말. 반말 금지.

## Workflow

| 규칙 | 내용 |
|------|------|
| Ask First | 세션 시작 시 무엇을 할지 먼저 물어볼 것. 자동 준비·분석·구현 시작 금지. |
| Plan Approval | 계획 출력 후 사용자 승인 대기. **승인 없이 코드 작성 절대 금지** |
| No Stalling | 막히면 즉시 STOP, 재플랜. 밀어붙이기 금지 |
| Verify Before Done | 동작 증명 없이 완료 표시 금지 |
| Full Scope | 변경 전 영향 파일 전부 나열, 한 번에 처리 |
| Self-Improvement | 수정 받은 후 패턴·원인 스스로 정리 |
| Task Plan | 작업 시작 전 체크리스트 형태로 플랜 작성. 진행하며 완료 표시 |

## 코드 원칙

| 원칙 | 내용 |
|------|------|
| Simplicity First | 최소 코드, 최소 영향 범위 |
| No Laziness | 근본 원인 파악. 임시 수정 금지 |
| No New Patterns | 기존 패턴·헬퍼 확인 후 없는 것만 추가 |
| Elegance Check | 비자명한 변경 시 "더 우아한 방법?" 1회 점검 |

## 토큰 최적화

| 항목 | 규칙 |
|------|------|
| 문서·프롬프트 | 키워드·표·코드만. 설명체 금지 |
| 세션 관리 | 길어지면 새 세션, URL만 전달 |
| 중복 금지 | 같은 원칙 반복 작성 금지 |

### Obsidian 볼트 연동 최적화

| 항목 | 규칙 |
|------|------|
| `.claudeignore` | 볼트 루트에 유지. `.obsidian/`, `*.canvas`, `*.base`, 대형 아카이브 제외 |
| 파일 분산 | 로그는 `logs/YYYY-MM-DD.md` 증분 기록. 단일 대형 파일 금지 |
| MOC 우선 참조 | 전체 문서 읽기 전 `README.md` / `infra-map.md` 먼저 확인 |
| 요약만 갱신 | 기존 로그 수정 금지. 신규 파일 추가 후 인덱스만 업데이트 |

## Task 관리
```
tasks/todo.md    — 체크리스트 형태로 플랜
tasks/lessons.md — 수정 후 패턴 업데이트
```

## Subagent 전략

| 용도 | 규칙 |
|------|------|
| 대규모 분석 | Explore agent — 전체 레포 스캔, 10개+ 파일 |
| 병렬 실행 | 에이전트당 단일 태스크. 독립 작업은 동시 실행 |

## 3-Tier LLM 라우팅

→ [[system/3-tier-routing]] 참조

## 배포 체크리스트

배포 전 전부 확인 → 단일 커밋으로 수정:

| 항목 | 확인 내용 |
|------|----------|
| Node 버전 | engines vs 플랫폼 기본값 |
| 빌드 커맨드 | client + server 모두 빌드 |
| 헬스체크 | 플랫폼 기대 경로 노출 여부 |
| 정적 파일 경로 | 컨테이너 내 resolve 정상 여부 |
| 환경 변수 | 필요 변수 전부 설정 여부 |
| 패키지 호환성 | peer deps 버전 일치 여부 |
| 포트 바인딩 | process.env.PORT 사용 여부 |
| Lock 파일 | 신규 패키지 추가 시 삭제 후 커밋 |

## DB / API

| 항목 | 규칙 |
|------|------|
| db:push | 스키마 변경 전부 모아서 1회 |
| API 호출 | 단일 쿼리 집계. n+1 금지 |
| 실행 프롬프트 | 200줄 이하. 상세 스펙은 하위 페이지 분리 |

## Tool 자동승인 설정

Mac Mini CLI 환경 기준. 아래 설정이 유지되어야 승인 프롬프트 없이 동작함.

### `~/.claude/settings.json` — 글로벌 허용
```json
"permissions": {
  "allow": ["Bash", "Write", "Edit", "MultiEdit"]
}
```
- `"Bash"` — 모든 Bash 명령 자동승인 (aloop-ask.sh, mkdir, git, python3 등 전부 포함)
- 이 항목이 없으면 Bash 호출 시 매번 승인 프롬프트 발생

### 프로젝트 `settings.local.json` — 이중 보험
```json
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```
- 프로젝트 내 모든 tool 자동승인

### 설정 누락 시 복원 절차
1. `~/.claude/settings.json` → `allow`에 `"Bash"` 추가
2. 프로젝트 `.claude/settings.local.json` → `defaultMode: "bypassPermissions"` 확인

## 세션 이어가기

| 시점 | 명령 | 동작 |
|------|------|------|
| 세션 시작 | `/rsm` | 최신 핸드오프 로드 + 다음 파일 생성 |
| 세션 종료 | `/rsm log` | 미커밋 커밋 + 핸드오프 저장 |

핸드오프 파일 위치: `Lib/resume-log/<repo-name>/resume-log-NNNN.md`

## Lessons Learned

| 패턴 | 규칙 |
|------|------|
| 파일 하나씩 발견 | grep 전체 후 한 번에 처리 |
| 배포 반복 실패 | 체크리스트 전부 실행 후 단일 커밋 |
| 설정 범위 누락 | 영향 케이스 전부 열거 후 처리 |
| lock 미동기화 | 패키지 추가 시 lock 삭제 후 커밋 |
| 임시 수정 반복 | 근본 원인 파악. 증상 하나씩 금지 |
| git email 불일치 | git config user.email = GitHub 계정 이메일로 고정 |
