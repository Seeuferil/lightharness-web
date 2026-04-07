@CLAUDE-global.md

---

# Web Claude Code 오버라이드

> CLAUDE-global.md 기준에서 Web Claude Code 환경에 맞게 아래 항목을 오버라이드합니다.
> Mac Dev 전용 섹션(Obsidian 볼트, Tool 자동승인, LM Studio, LiveStatus)은 Web에서 적용 안 함.

## 2-Tier LLM 라우팅

`/wharness`, `/wharness-run`, `/wharness-check` 실행 시에만 적용.
일반 대화·코딩은 Tier 1(Sonnet)이 직접 처리.

| Tier | 모델 | 역할 | 호출 방식 |
|------|------|------|----------|
| 1 | Claude Sonnet | 조율·판단·코드 작성 | 현재 세션 (직접) |
| 2 | Claude Haiku | 반복·요약·검색·커밋 메시지 | `Agent(model="haiku")` |

### 에스컬레이션

```
Tier 2 실패 → Tier 1이 직접 처리
```

### Tier 2 적합 작업 (Haiku)

- 코드 검색·요약
- 단순 리팩터링
- 커밋 메시지 생성
- Blueprint Lint
- 반복 템플릿 생성
- 정적 분석 (scout, auditor, verifier)

### Tier 2 prompt 원칙

- 반드시 영어
- 파일 전체 inline 전달 금지 — 요약(3~5줄) + 핵심 스니펫(10줄 이내)만

## 커밋 메시지 (오버라이드)

Tier 2 (Haiku)로 생성 요청:

```python
Agent(
  model="haiku",
  prompt="Generate a git commit message. Format: `type: short summary` (max 72 chars, English). "
         "Types: feat/fix/chore/refactor/docs. "
         "Last line: Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>\n\n"
         "Changes:\n{변경 내용 요약}"
)
```

## 세션 이어가기 (오버라이드)

Web Claude Code에서는 `/wrsm` 사용. (`/rsm` 대신)

| 시점 | 명령 | 동작 |
|------|------|------|
| 세션 시작 | `/wrsm` | Task 목록 로드 + 이어서 할 일 출력 |
| 세션 종료 | `/wrsm log` | 완료 처리 + 다음 할 일 TaskCreate 저장 |

## 실행 결과 저장 (Web 전용)

파일시스템 직접 저장 불가 → TaskOutput 사용:

```
각 단계 완료 → TaskUpdate(status="completed", output="결과 요약")
전체 완료   → TaskCreate로 다음 할 일 등록
```

## Blueprint 저장 위치

```
.claude/lhw/blueprints/  ← 재사용 템플릿
.claude/blueprints/      ← 프로젝트 전용
```

## 토큰 절약 (추가)

1. 반복 작업 → Tier 2 (Haiku) 위임
2. 이전 단계 결과 전달: 요약(3~5줄) + 핵심 스니펫(10줄 이내)만
3. 대용량 분석 결과 → TaskOutput에 저장 후 경로만 참조
