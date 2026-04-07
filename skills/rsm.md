# /rsm — 세션 핸드오프 스킬

TaskList를 유일한 상태 저장소로 사용합니다.
파일 저장 없음. repo commit 없음.

---

## 모드 판별

| 호출 | 모드 |
|---|---|
| `/rsm` (인자 없음) | LOAD 모드 — 세션 시작 |
| `/rsm log` | SAVE 모드 — 세션 종료 |

---

## LOAD 모드 (`/rsm`)

### 1. TaskList 조회

```
TaskList() 호출 → 전체 Task 목록 조회
```

### 2. 분류 및 출력

```
pending 항목   → "이어서 할 일"로 출력
in_progress 항목 → "진행 중" 으로 출력 (이전 세션에서 미완료된 항목)
```

출력 형식:
```
📋 {프로젝트명} — 세션 재개

진행 중:
  - [{id}] {subject}

이어서 할 일:
  - [{id}] {subject}
      {description 첫 줄}
```

### 3. 완료 메시지

```
✅ 로드 완료 — pending {n}개 / in_progress {m}개
세션 종료 시 /rsm log 로 저장하세요.
```

TaskList가 비어있으면:
```
📋 등록된 Task 없음.
새 작업을 시작하거나 /harness 로 Blueprint를 설계하세요.
```

---

## SAVE 모드 (`/rsm log`)

### 1. 현재 세션 정리

완료된 작업을 TaskUpdate로 처리합니다.

```
이번 세션에서 완료한 항목 → TaskUpdate(id=..., status="completed")
아직 미완료 항목 → status 변경 없음 (pending 유지)
```

### 2. 다음 할 일 등록

이번 세션에서 새로 파악된 다음 액션을 TaskCreate로 저장합니다.

```
TaskCreate(
  subject: "{프로젝트명}: {다음 액션 한 줄 요약}",
  description: "{상세 내용 — 무엇을, 왜, 어디서부터}"
)
```

### 3. 완료 메시지

```
✅ 세션 저장 완료
  완료 처리: {n}개
  다음 할 일 등록: {m}개
  남은 pending: {k}개
```

---

## 주의사항

- Task는 세션 간 유지됩니다.
- 오래된 Task는 주기적으로 정리하세요 (`TaskUpdate(status="completed")` 또는 불필요하면 삭제).
- harness Blueprint Task는 subject를 `harness: {Template_Name}` 형식으로 유지해야 `/harness-run`이 자동 감지합니다.
