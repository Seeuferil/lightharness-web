# LightHarness Web

## 환경 감지 — 최우선 실행

세션 시작 시 가장 먼저 확인합니다.

```
~/.claude/CLAUDE.md 존재 → Mac Mini 환경 → 이 파일의 모든 규칙 무시하고 종료
~/.claude/CLAUDE.md 없음 → Web Claude Code 환경 → 아래 규칙 적용
```

Mac Mini 환경에서는 이 파일을 완전히 무시합니다. Mac 전용 규칙은 `~/.claude/CLAUDE.md`에서 관리됩니다.

---

## 세션 시작 배너

**Web Claude Code 환경으로 확인되면 첫 응답 시 반드시 아래 배너를 즉시 출력하세요.**

```
LightHarness Web 로드됨
─────────────────────────────
사용 가능한 커맨드 (타이핑으로 실행):
  /harness [목표]   — 에이전트 팀 Blueprint 설계
  /harness-run      — Blueprint 실행 (큐 자동 감지)
  /rsm              — 세션 재개 (이전 Task 불러오기)
  /rsm log          — 세션 종료 (다음 할 일 저장)

2-Tier: Sonnet(조율) / Haiku(분석·반복)
─────────────────────────────
```

## 스킬 목록

| 커맨드 | 파일 | 역할 |
|---|---|---|
| `/harness` | `.claude/lhw/skills/harness.md` | Blueprint 설계 |
| `/harness-run` | `.claude/lhw/skills/harness-run.md` | Blueprint 실행 |
| `/rsm` | `.claude/lhw/skills/rsm.md` | 세션 핸드오프 |

커맨드는 `/` 자동완성 메뉴 대신 직접 타이핑하거나 자연어로 요청합니다.

---

## 2-Tier 라우팅

`/harness`, `/harness-run` 실행 시에만 적용합니다.
일반 대화·코딩은 Tier 1(Sonnet)이 직접 처리합니다.

| Tier | 모델 | 역할 | 호출 방식 |
|---|---|---|---|
| 1 | Claude Sonnet | 조율·판단·코드 작성 | 현재 세션 (직접) |
| 2 | Claude Haiku | 분석·반복·요약·Lint·커밋 메시지 | `Agent(model="haiku")` |

> `Max_Tier1_Steps_Per_Session: 10`은 참고용 가이드라인입니다. 자동 강제되지 않으며 완료 출력 시 사용량 표시 용도로만 사용합니다.

### 에스컬레이션

```
Tier 2 실패 → Tier 1이 직접 처리
```

### Tier 2 적합 작업 (Haiku)

- 코드 검색·요약
- 파일 분석·Lint
- 단순 리팩터링
- 커밋 메시지 생성
- 반복 템플릿 생성

---

## Blueprint 저장 위치

```
.claude/lhw/blueprints/     ← lightharness-web submodule 내 (재사용 템플릿)
.claude/blueprints/         ← 프로젝트 전용 Blueprint
```

---

## 커밋 메시지 규칙

- Tier 2 (Haiku)로 생성 요청
- 형식: `type: short summary` (최대 72자, 영어)
- type: `feat` / `fix` / `chore` / `refactor` / `docs`
- 마지막 줄: `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`

---

## 토큰 절약

1. 반복·분석 작업 → Tier 2 (Haiku) 위임
2. 이전 단계 결과 전달 시 요약(3~5줄) + 핵심 스니펫(10줄 이내)만 사용
