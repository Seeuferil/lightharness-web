# /wharness-check — 코드 정적 버그 감사 스킬

작업 중인 코드를 4단계로 정적 분석합니다.
변경된 파일 또는 지정 경로를 대상으로 8개 버그 카테고리를 검사하고 CRITICAL/WARNING을 수정합니다.

---

## 단계 구성

| 단계 | Tier | 역할 |
|---|---|---|
| scout | tier3 (Haiku) | 프로젝트 타입 + 핵심 파일 목록 수집 |
| auditor | tier3 (Haiku) | 8개 카테고리 버그 분석 |
| patcher | tier1 (Sonnet) | CRITICAL/WARNING 수정 |
| verifier | tier3 (Haiku) | 4가지 회귀 검증 |

---

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

---

## STEP 0 — 대상 파일 결정

```
인자 있음 (경로/파일명) → 해당 파일만 검사
인자 없음               → git diff HEAD로 변경된 파일 목록 사용
                          변경 없으면 사용자에게 경로 요청
```

---

## STEP 1 — scout (tier3)

```python
Agent(
  model="haiku",
  prompt="""
Scan the target files and return:
1. Project type (e.g. Next.js, Express, React, plain Node)
2. Language(s) in use (TypeScript / JavaScript / mixed)
3. List of files to audit (max 20, prioritize by change recency and dependency centrality)
4. Any env var files or config files relevant to CAT-8

Output as JSON:
{
  "project_type": "...",
  "languages": [...],
  "audit_files": ["path/to/file", ...],
  "config_files": ["path/to/.env.example", ...]
}

Target files: {변경된 파일 또는 지정 경로}
"""
)
```

scout 결과를 STEP 2로 전달합니다.

---

## STEP 2 — auditor (tier3)

scout 결과의 `audit_files`를 대상으로 8개 카테고리 순서대로 검사합니다.

500줄 이상 파일은 tier2 (gemini-analyzer)로 오프로드합니다.

```python
Agent(
  model="haiku",
  prompt="""
Analyze the following files for bugs in 8 categories.
For each finding output:
  FILE: <path>
  LINE: <line number or range>
  CAT: <CAT-1 through CAT-8>
  SEVERITY: CRITICAL | WARNING | INFO
  ISSUE: <one-line description>
  FIX: <one-line suggested fix>

Categories:
  CAT-1 API Contract         — field name typos, wrong type assumptions
  CAT-2 Interface/Type Mismatch — TS interface vs actual API/DB response shape
  CAT-3 Null/Undefined Safety   — missing optional chaining, unchecked null
  CAT-4 Filter & Edge Case      — empty array, zero, negative number unhandled
  CAT-5 Dead Code               — unused exports, unreachable branches
  CAT-6 Error Handling          — missing try/catch, swallowed errors
  CAT-7 Security                — SQL injection, XSS, hardcoded secrets/tokens
  CAT-8 Integration Consistency — param name mismatch between caller/callee, env var mismatch

Files to audit (summary + key snippets only):
{scout 결과 audit_files 요약}
"""
)
```

auditor 결과를 severity별로 정렬합니다: CRITICAL → WARNING → INFO

---

## STEP 3 — patcher (tier1)

auditor 결과에서 **CRITICAL** 과 **WARNING** 항목만 수정합니다.
INFO 항목은 보고서에 기록하되 수정하지 않습니다.

- 각 파일을 Read 후 Edit으로 수정합니다.
- 수정 시 해당 항목의 `FIX` 내용을 기반으로 최소 변경 원칙을 지킵니다.
- 수정 불가(설계 결정 필요) 항목은 `DEFERRED`로 표시합니다.

수정 후 중간 출력:
```
🔧 패치 완료:
  CRITICAL {n}개 수정 / {m}개 DEFERRED
  WARNING  {n}개 수정 / {m}개 DEFERRED
```

---

## STEP 4 — verifier (tier3)

patcher가 수정한 파일을 대상으로 4가지 회귀 검증합니다.

```python
Agent(
  model="haiku",
  prompt="""
Verify the patched files for 4 regression checks.
Output exactly 4 lines: PASS or FAIL: reason.

CHECK-1 NO_NEW_CRITICAL: No new CRITICAL issues introduced by the patch.
CHECK-2 PATCH_SCOPE: Patch only modified lines related to reported issues (no unrelated changes).
CHECK-3 TYPE_CONSISTENCY: All modified TypeScript types remain consistent with their usage sites.
CHECK-4 SECURITY_CLEAR: No CAT-7 (Security) issues remain in patched files.

Patched files (summary + key snippets):
{patcher 수정 파일 요약}

Original audit findings:
{auditor 결과 요약}
"""
)
```

- 4개 모두 PASS → 완료 출력
- FAIL 항목 → 해당 항목 재수정 후 verifier 1회 재실행
- 재실행 후도 FAIL → 사용자에게 보고

---

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

DEFERRED 항목이 있으면 /wharness 로 Blueprint를 설계하세요.
```

---

## 제약

| 항목 | 조건 |
|---|---|
| 파일당 라인 수 | 500줄 이상 → tier2 오프로드 |
| patcher 수정 범위 | CRITICAL/WARNING만, INFO 수정 금지 |
| 컨텍스트 전달 | 이전 단계 요약(3~5줄) + 핵심 스니펫(10줄 이내)만 |
| tier2/tier3 prompt | 영어만 |
| 재실행 | 단계별 최대 1회 |
