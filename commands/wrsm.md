# /wrsm — 세션 핸드오프 스킬

GitHub Issues를 영구 상태 저장소로 사용합니다.
세션 간 태스크 핸드오프를 지원합니다.

---

## 모드 판별

| 호출 | 모드 |
|---|---|
| `/wrsm` (인자 없음) | LOAD 모드 — 세션 시작 |
| `/wrsm log` | SAVE 모드 — 세션 종료 |

---

## LOAD 모드 (`/wrsm`)

### 1. GitHub Issues 조회

현재 프로젝트 repo에서 아래 라벨의 Issue를 조회합니다:

```
mcp__github__list_issues:
  labels: ["harness:pending"] → 이어서 할 일
  labels: ["harness:active"]  → 진행 중
```

### 2. 분류 및 출력

```
harness:active 항목  → "진행 중" 으로 출력
harness:pending 항목 → "이어서 할 일"로 출력
blueprint 라벨 포함  → Blueprint 태스크로 표시
```

출력 형식:
```
📋 {프로젝트명} — 세션 재개

진행 중:
  - [#{issue_number}] {title}

이어서 할 일:
  - [#{issue_number}] {title}
      {body 첫 줄}

Blueprint 대기:
  - [#{issue_number}] {title} → /wharness-run 으로 실행
```

### 3. 완료 메시지

```
✅ 로드 완료 — pending {n}개 / active {m}개
세션 종료 시 /wrsm log 로 저장하세요.
```

Issue가 없으면:
```
📋 등록된 Task 없음.
새 작업을 시작하거나 /wharness 로 Blueprint를 설계하세요.
```

---

## SAVE 모드 (`/wrsm log`)

### 1. 현재 세션 정리

이번 세션에서 완료한 작업의 Issue를 업데이트합니다.

```
완료 항목:
  → Issue label: harness:pending → harness:completed
  → Issue에 완료 코멘트 추가: "Completed in session {date}"
  → Issue close

미완료 항목:
  → label 변경 없음 (pending 유지)
```

### 2. 다음 할 일 등록

이번 세션에서 새로 파악된 다음 액션을 GitHub Issue로 생성합니다.

```
mcp__github__issue_write:
  title: "{프로젝트명}: {다음 액션 한 줄 요약}"
  body: "{상세 내용 — 무엇을, 왜, 어디서부터}"
  labels: ["harness:pending", "session-handoff"]
```

### 3. 완료 메시지

```
✅ 세션 저장 완료
  완료 처리: {n}개 Issue
  다음 할 일 등록: {m}개 Issue
  남은 pending: {k}개
```

---

## 라벨 체계

| 라벨 | 용도 |
|---|---|
| `harness:pending` | 대기 중 태스크 |
| `harness:active` | 현재 진행 중 |
| `harness:completed` | 완료 |
| `blueprint` | Blueprint 설계 태스크 (/wharness로 생성) |
| `session-handoff` | 세션 핸드오프 메모 (/wrsm log로 생성) |

---

## 주의사항

- Issue는 GitHub에 영구 저장되므로 세션 간 유지됩니다.
- 오래된 Issue는 주기적으로 close하세요.
- Blueprint 태스크는 title을 `wharness: {Template_Name}` 형식으로 유지해야 `/wharness-run`이 자동 감지합니다.
- Web Claude Code와 Mac Mini CLI 양쪽에서 동일하게 작동합니다.
