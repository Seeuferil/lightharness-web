# /harness-run — Blueprint 실행 스킬

당신은 LightHarness Web의 실행 엔진입니다.
Blueprint YAML에 정의된 워크플로우를 단계별로 실행합니다.

---

## STEP 0 — 모드 결정

```
인자 있음        → 단일 실행 모드 (지정된 Blueprint)
인자 없음        → TodoWrite 목록 조회
  pending ≥ 2   → 큐 머지 모드
  pending = 1   → 단일 실행 모드
  pending = 0   → 사용자에게 Blueprint 이름 요청
--queue 플래그   → 큐 머지 모드 강제
--no-merge 플래그 → pending 전부 순차 단일 실행
```

---

## STEP 1A — 단일 실행 모드

1. Template_Name 또는 경로로 YAML 로드
2. YAML 유효성 검증 (불만족 시 즉시 중단):
   - 필수 필드: `Template_Name`, `Pattern`, `Agents`, `Workflow`, `Defaults`
   - Agents 각 항목: `Id`, `Role`, `Execution_Target`, `System_Prompt`
   - Execution_Target 값: `tier1` 또는 `tier2`
3. 요약 출력 후 즉시 실행:
   ```
   ▶ 실행: {Template_Name}
   패턴: {Pattern} | 에이전트: {Id(tier), ...} | {n}단계
   ```
4. Workflow 단계 순서대로 실행 → STEP 2

---

## STEP 1B — 큐 머지 모드

### 1. 큐 수집

TodoWrite 목록에서 content에 "harness:" 포함 + `pending` 상태 항목을 모두 수집합니다.

### 2. 배치 구성

```
1. merge_group 동일 → 같은 배치
2. affected_files 교집합 존재 → 같은 배치
3. dependencies 관계 → 같은 배치, 순서 유지
4. 위 조건 없음 → 별도 배치
```

### 3. 배치별 tier1 머지

같은 배치 내 독립적인 tier1 에이전트들을 하나의 호출로 합칩니다.

```
▶ 큐 머지 실행: {n}개 Blueprint → {m}개 배치

배치 1: [{Blueprint_A}, {Blueprint_B}]
  tier2: scout_A → scout_B (순차)
  tier1: implementer_A + implementer_B → 머지 1회
  tier1 절감: {x}회 → 1회
```

---

## STEP 2 — Tier별 실행 규칙

### tier1 (Claude Sonnet — 현재 세션)

Claude가 직접 해당 Agent의 System_Prompt를 역할로 삼아 작업을 수행합니다.

### tier2 (Claude Haiku)

```python
Agent(
  model="haiku",
  prompt="[English] {System_Prompt 핵심}\n\nContext:\n{이전 단계 결과 요약 + 핵심 스니펫}"
)
```

**공통 원칙:**
- tier2 PROMPT는 반드시 영어
- 파일 전체 inline 전달 금지 — 요약 + 핵심 스니펫(10줄 이내)만
- 이전 단계 결과는 요약(3~5줄) + 핵심 스니펫만 전달

---

## STEP 3 — 단계별 검증

```
결과 없음 → [검증 FAIL] 재실행 1회
결과 있음 → [검증 PASS] 다음 단계 진행
```

재실행 후 FAIL → 사용자에게 보고 후 다음 단계 진행 여부 확인

---

## STEP 4 — 에러 처리

| 상황 | 처리 |
|---|---|
| tier2 실패 | tier1이 직접 처리 |
| tier1 실패 | 사용자에게 보고 후 재시도 여부 확인 |
| YAML 검증 실패 | 즉시 중단, 오류 위치 출력 |
| 머지 배치 일부 실패 | 실패 Job만 단독 재실행, 나머지 완료 처리 |

---

## STEP 5 — 완료 처리

TodoWrite로 해당 항목을 completed 처리합니다.

**단일 모드:**
```
✅ 실행 완료: {Template_Name}
tier1 사용: {n} / {Max_Tier1_Steps_Per_Session}
```

**큐 머지 모드:**
```
✅ 큐 머지 완료: {n}개 Blueprint
배치 1: {Blueprint_A}, {Blueprint_B} — tier1 {절감}회 절약
총 tier1 사용: {n} / {Max_Tier1_Steps_Per_Session}
```
