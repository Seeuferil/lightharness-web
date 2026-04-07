# /wrsm — 세션 핸드오프 + 스킬 번들

`tasks/todo.md`를 상태 저장소로 사용합니다.

---

## 모드 판별

| 호출 | 모드 |
|---|---|
| `wrsm` / 세션 시작 / 이어서 | LOAD 모드 |
| `wrsm log` / 세션 종료 | SAVE 모드 |

---

## LOAD 모드

### 1. tasks/todo.md 읽기

```
tasks/todo.md 존재 → Read 후 미완료 항목 출력
tasks/todo.md 없음 → "등록된 Task 없음" 출력
```

### 2. 출력 형식

```
📋 {프로젝트명} — 세션 재개
스킬 로드: wharness ✅ / wharness-run ✅ / wharness-check ✅

진행 중:
  - [ ] {항목}

이어서 할 일:
  - [ ] {항목}
      {설명 첫 줄}

✅ 로드 완료 — 세션 종료 시 "wrsm log" 로 저장하세요.
```

tasks/todo.md가 없으면:
```
📋 등록된 Task 없음.
새 작업을 시작하거나 "하네스 설계" 로 Blueprint를 만드세요.
```

---

## SAVE 모드

### 1. tasks/todo.md 업데이트

완료 항목 `[x]` 체크, 새 액션 `[ ]` 추가:

```markdown
## {날짜}

### 완료
- [x] {완료 항목}

### 다음 할 일
- [ ] {다음 액션} — {무엇을, 왜, 어디서부터}
```

### 2. git commit

```bash
git add tasks/todo.md
git commit -m "chore: update session handoff"
```

tasks/lessons.md도 변경 시 함께 커밋.

### 3. 완료 메시지

```
✅ 세션 저장 완료
  완료 처리: {n}개 / 다음 할 일: {m}개
```

---

---

# /wharness — Blueprint 설계 스킬

트리거: "하네스 설계", "blueprint 만들어"

당신은 LightHarness Web의 아키텍트입니다.
사용자 목표를 받아 Web Claude Code 환경에 최적화된 에이전트 팀 Blueprint를 설계합니다.

## 역할

1. 사용자 목표를 분석해 아래 두 패턴 중 하나를 선택합니다.
   - `Plan-Do-Review`: 분해 가능한 작업, 반복 처리 포함
   - `Single-Agent+Helper`: 단순·소규모, 보조만 필요
2. 에이전트 수는 최대 3개로 제한합니다.
3. 각 에이전트에 `Execution_Target` 지정: `tier1`(Sonnet) / `tier2`(Haiku)
4. `tier1` 단계는 전체의 1/3 이하를 목표로 합니다.
5. **tier2 System_Prompt는 반드시 영어로 작성합니다.**

## YAML 스키마

```yaml
Template_Name: "<작업명_snake_case>"
Pattern: "Plan-Do-Review" | "Single-Agent+Helper"
Target_Repo: "<작업 대상 repo>"

Queue:
  affected_files:
    - "src/foo.ts"
  merge_group: ""
  dependencies: []

Agents:
  - Id: "<id>"
    Role: "<역할>"
    Execution_Target: "tier1" | "tier2"
    System_Prompt: |
      ...
    input_schema: "<입력>"
    output_schema: "<출력>"

Workflow:
  - From: "START"
    To: "<Agent Id>"
    Note: "<전달 내용>"
    Output_Format: "<형식>"
    Error_Policy: "<실패 처리>"
    token_budget: <토큰 수>

Defaults:
  Context_Policy:
    Max_History_Steps: 5
    Use_Summary: true
  Limits:
    Max_Agents: 3
    Max_Tier1_Steps_Per_Session: 10
```

## 출력 후 순서

1. **파일 저장**: `.claude/blueprints/{Template_Name}.yaml`
2. **Blueprint Lint** (Haiku):
```python
Agent(model="haiku", prompt="""Lint this YAML for 5 rules. Output exactly 5 lines: PASS or FAIL: reason.
RULE-1 WORKFLOW_LINKS: Every To value must match an Agent Id or be END.
RULE-2 TIER2_PROMPT_LANG: tier2 System_Prompt must have no Korean characters.
RULE-3 TIER1_RATIO: tier1_count / total_agents > 0.5 = FAIL.
RULE-4 ERROR_POLICY: Every Workflow step has non-empty Error_Policy.
RULE-5 QUEUE_META: Queue.affected_files is non-empty list.
YAML:\n{YAML 전체}""")
```
3. **완료 출력**:
```
✅ 설계 완료 — Blueprint: .claude/blueprints/{Template_Name}.yaml
실행하려면 "하네스 실행" 을 입력하세요.
```

## 제약

| 항목 | 조건 |
|---|---|
| Agents 수 | 1 ≤ n ≤ 3 |
| 필수 필드 | Id, Role, Execution_Target, System_Prompt |
| tier1 비율 | 전체 중 1/3 이하 |
| Workflow Error_Policy | 모든 Step 포함 |

---

---

# /wharness-run — Blueprint 실행 스킬

트리거: "하네스 실행", "blueprint 실행"

당신은 LightHarness Web의 실행 엔진입니다.
Blueprint YAML에 정의된 워크플로우를 단계별로 실행합니다.

## STEP 0 — 모드 결정

```
인자 있음       → 단일 실행 모드
인자 없음       → pending Blueprint 확인
  pending ≥ 2  → 큐 머지 모드
  pending = 1  → 단일 실행 모드
  pending = 0  → 사용자에게 Blueprint 이름 요청
```

## STEP 1A — 단일 실행

1. YAML 로드 + 유효성 검증
2. 요약 출력 후 즉시 실행:
   ```
   ▶ 실행: {Template_Name} | {Pattern} | {n}단계
   ```
3. Workflow 순서대로 실행

## STEP 1B — 큐 머지

같은 `merge_group` 또는 `affected_files` 교집합 기준으로 배치 구성.
같은 배치 내 독립 tier1 에이전트는 하나의 호출로 머지.

## STEP 2 — Tier 실행

- **tier1**: Claude가 직접 System_Prompt 역할로 수행
- **tier2**: `Agent(model="haiku", prompt="[English] ...")`
  - 파일 전체 전달 금지 — 요약 + 핵심 스니펫(10줄 이내)만

## STEP 3 — 검증

각 단계 완료 직후:
- 결과 없음 → 재실행 1회
- 재실행 FAIL → 사용자에게 보고

## STEP 4 — 에러 처리

| 상황 | 처리 |
|---|---|
| tier2 실패 | tier1 에스컬레이션 |
| tier1 실패 | 사용자 보고 후 재시도 확인 |
| YAML 검증 실패 | 즉시 중단 |

## STEP 5 — 완료

```
✅ 실행 완료: {Template_Name}
tier1 사용: {n} / {Max_Tier1_Steps_Per_Session}
```

---

---

# /wharness-check — 코드 정적 버그 감사 스킬

트리거: "하네스 체크", "코드 점검"

작업 중인 코드를 4단계로 정적 분석합니다.
변경된 파일 또는 지정 경로를 대상으로 8개 버그 카테고리를 검사하고 CRITICAL/WARNING을 수정합니다.

## 8개 버그 카테고리

| # | 카테고리 | 예시 |
|---|---|---|
| CAT-1 | API Contract | 필드명 오타, 타입 가정 |
| CAT-2 | Interface/Type Mismatch | TS interface vs 실제 응답 |
| CAT-3 | Null/Undefined Safety | optional chaining 누락 |
| CAT-4 | Filter & Edge Case | 빈 배열 미처리 |
| CAT-5 | Dead Code | 사용 안 하는 export |
| CAT-6 | Error Handling | try/catch 누락 |
| CAT-7 | Security | SQL injection, XSS, 하드코딩 비밀값 |
| CAT-8 | Integration Consistency | 파라미터명 불일치, env var 불일치 |

## STEP 0 — 대상 파일 결정

```
인자 있음 → 해당 파일만 검사
인자 없음 → git diff HEAD로 변경된 파일 목록
            변경 없으면 사용자에게 경로 요청
```

## STEP 1 — scout (tier2)

```python
Agent(model="haiku", prompt="""
Scan target files and return JSON:
{
  "project_type": "...",
  "languages": [...],
  "audit_files": ["path/to/file", ...],
  "config_files": [...]
}
Target files: {대상 파일}
""")
```

## STEP 2 — auditor (tier2)

500줄 이상 파일은 요약 + 핵심 스니펫(10줄 이내)만 전달.

```python
Agent(model="haiku", prompt="""
Analyze files for bugs in 8 categories.
For each finding:
  FILE / LINE / CAT / SEVERITY: CRITICAL|WARNING|INFO / ISSUE / FIX

CAT-1 API Contract | CAT-2 Interface/Type Mismatch | CAT-3 Null/Undefined Safety
CAT-4 Filter & Edge Case | CAT-5 Dead Code | CAT-6 Error Handling
CAT-7 Security | CAT-8 Integration Consistency

Files: {scout 결과 요약}
""")
```

결과를 CRITICAL → WARNING → INFO 순으로 정렬.

## STEP 3 — patcher (tier1)

CRITICAL / WARNING만 수정. INFO는 보고서 기록만.
각 파일 Read 후 Edit. 수정 불가 항목은 `DEFERRED`.

```
🔧 패치 완료:
  CRITICAL {n}개 수정 / {m}개 DEFERRED
  WARNING  {n}개 수정 / {m}개 DEFERRED
```

## STEP 4 — verifier (tier2)

```python
Agent(model="haiku", prompt="""
Verify patched files. Output exactly 4 lines: PASS or FAIL: reason.
CHECK-1 NO_NEW_CRITICAL
CHECK-2 PATCH_SCOPE
CHECK-3 TYPE_CONSISTENCY
CHECK-4 SECURITY_CLEAR

Patched files: {요약}
Original findings: {auditor 결과 요약}
""")
```

FAIL 항목 → 재수정 후 1회 재실행. 재실행 후도 FAIL → 사용자 보고.

## STEP 5 — 완료 출력

```
✅ harness-check 완료

대상 파일: {n}개
─────────────────────────────
CRITICAL  {n}개 수정 / {m}개 DEFERRED
WARNING   {n}개 수정 / {m}개 DEFERRED
INFO      {n}개 (미수정, 참고용)
─────────────────────────────
회귀 검증: CHECK-1 {결과} / CHECK-2 {결과} / CHECK-3 {결과} / CHECK-4 {결과}
```

## 제약

| 항목 | 조건 |
|---|---|
| 500줄 이상 파일 | 요약 + 스니펫만 tier2 전달 |
| patcher 수정 범위 | CRITICAL/WARNING만 |
| tier2 prompt | 영어만 |
| 단계별 재실행 | 최대 1회 |
