# LightHarness Web

## 환경 감지 — 최우선 실행

세션 시작 시 가장 먼저 확인합니다.

```
~/.claude/CLAUDE.md 존재 → Mac Mini 환경 → 이 파일의 모든 규칙 무시하고 종료
~/.claude/CLAUDE.md 없음 → Web Claude Code 환경 → 아래 규칙 적용
```

Mac Mini 환경에서는 이 파일을 완전히 무시합니다. Mac 전용 규칙은 `~/.claude/CLAUDE.md`에서 관리됩니다.

---

## 슬래시 커맨드

`.claude/commands/`에 하드 등록되어 자동으로 사용 가능합니다.
Mac Mini의 `/harness`와 충돌하지 않도록 `w` 접두어를 사용합니다.

| 커맨드 | 파일 | 역할 |
|---|---|---|
| `/wharness` | `.claude/commands/wharness.md` | Blueprint 설계 |
| `/wharness-run` | `.claude/commands/wharness-run.md` | Blueprint 실행 |
| `/wrsm` | `.claude/commands/wrsm.md` | 세션 핸드오프 (GitHub Issues 기반) |

---

## 3-Tier 라우팅

`/wharness`, `/wharness-run` 실행 시에만 적용합니다.
일반 대화·코딩은 Tier 1이 직접 처리합니다.

| Tier | 모델 | 역할 | 호출 방식 |
|---|---|---|---|
| 1 | Claude (현재 세션) | 조율·판단·코드 작성 | 직접 처리 |
| 2 | Gemini Flash | 500줄+ 파일 분석·Lint | Gemini MCP 도구 (`.mcp.json` 필요) |
| 3 | Claude Haiku | 반복·요약·검색·커밋 메시지 | `Agent(model="haiku")` |

### Tier 2 Fallback

Gemini MCP 서버가 연결되어 있지 않으면:
- Lint → Tier 3 (Haiku) 대체
- 대형 파일 분석 → Tier 1 직접 처리

### 에스컬레이션 순서

```
Tier 3 → Tier 2 → Tier 1
```

Tier 3 실패 시 Tier 2로, Tier 2 실패 시 Tier 1이 직접 처리합니다.
Tier 3 실패 시 Tier 1 직접 이동은 금지합니다.

### Tier 3 적합 작업 (Haiku)

- 코드 검색·요약
- 단순 리팩터링
- 커밋 메시지 생성
- Blueprint Lint 전처리
- 반복 템플릿 생성

### Tier 2 적합 작업 (Gemini)

- 500줄 이상 파일 전체 분석
- 대형 코드베이스 의존성 파악
- Blueprint YAML Lint (5개 규칙 검사)

---

## Blueprint 저장 위치

```
.claude/lhw/blueprints/     ← lightharness-web submodule 내 (재사용 템플릿)
.claude/blueprints/         ← 프로젝트 전용 Blueprint (프로젝트 repo에 저장)
```

`/wharness`로 설계한 Blueprint는 프로젝트 전용이면 `.claude/blueprints/`에,
여러 프로젝트에서 재사용할 템플릿이면 `.claude/lhw/blueprints/`에 저장합니다.

---

## 세션 핸드오프 — GitHub Issues

TaskList/TaskCreate 대신 **GitHub Issues**를 영구 상태 저장소로 사용합니다.

```
/wrsm         → GitHub Issues 조회 (harness:pending, harness:active)
/wrsm log     → 완료 Issue close + 다음 할 일 Issue 생성
```

### 라벨 체계

| 라벨 | 용도 |
|---|---|
| `harness:pending` | 대기 중 태스크 |
| `harness:active` | 현재 진행 중 |
| `harness:completed` | 완료 |
| `blueprint` | Blueprint 설계 태스크 |
| `session-handoff` | 세션 핸드오프 메모 |

---

## 커밋 메시지 규칙

- Tier 3 (Haiku)로 생성 요청
- 형식: `type: short summary` (최대 72자, 영어)
- type: `feat` / `fix` / `chore` / `refactor` / `docs`
- 마지막 줄: `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`

---

## 토큰 절약

1. 500줄 이상 파일 → Tier 2 (Gemini) 오프로드
2. 반복 작업 → Tier 3 (Haiku) 위임
3. 이전 단계 결과 전달 시 요약(3~5줄) + 핵심 스니펫(10줄 이내)만 사용
4. 대용량 분석 결과 요약 후 경로만 참조
