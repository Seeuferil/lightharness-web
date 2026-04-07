# /wrsm — 세션 핸드오프 스킬

`tasks/todo.md`를 상태 저장소로 사용합니다. git commit으로 세션 간 유지됩니다.

---

## 모드 판별

| 호출 | 모드 |
|---|---|
| `wrsm` / 세션 시작 / 이어서 | LOAD 모드 |
| `wrsm log` / 세션 종료 | SAVE 모드 |

---

## LOAD 모드

### 1. 스킬 로드

스킬 파일 경로 판별:
```
skills/ 존재             → skills/ 사용
.claude/lhw/skills/ 존재 → .claude/lhw/skills/ 사용
```

아래 파일을 순서대로 Read:
1. `wharness.md`
2. `wharness-run.md`
3. `wharness-check.md`

### 2. tasks/todo.md 읽기

```
tasks/todo.md 존재 → Read 후 미완료 항목 출력
tasks/todo.md 없음 → "등록된 Task 없음" 출력
```

### 3. 출력 형식

```
📋 {프로젝트명} — 세션 재개

스킬 로드: wharness ✅ / wharness-run ✅ / wharness-check ✅

진행 중:
  - [ ] {항목}

이어서 할 일:
  - [ ] {항목}
      {설명 첫 줄}
```

### 4. 완료 메시지

```
✅ 로드 완료
세션 종료 시 "wrsm log" 로 저장하세요.
```

tasks/todo.md가 없거나 비어있으면:
```
📋 등록된 Task 없음.
새 작업을 시작하거나 "하네스 설계" 로 Blueprint를 만드세요.
```

---

## SAVE 모드

### 1. tasks/todo.md 업데이트

이번 세션에서 완료한 항목은 `[x]`로 체크.
새로 파악된 다음 액션은 `[ ]`로 추가.

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

tasks/lessons.md도 변경된 경우 함께 커밋:
```bash
git add tasks/todo.md tasks/lessons.md
git commit -m "chore: update session handoff and lessons"
```

### 3. 완료 메시지

```
✅ 세션 저장 완료
  완료 처리: {n}개
  다음 할 일: {m}개
  커밋: chore: update session handoff
```

---

## 주의사항

- `tasks/todo.md`가 없으면 SAVE 시 자동 생성합니다.
- wharness Blueprint는 subject를 `wharness: {Template_Name}` 형식으로 기록합니다.
