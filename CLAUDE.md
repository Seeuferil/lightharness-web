@CLAUDE-global-web.md

---

# LightHarness Web

## 환경 감지 — 최우선 실행

```
~/.claude/CLAUDE.md 존재 → Mac Dev 환경 → 이 파일의 모든 규칙 무시하고 종료
~/.claude/CLAUDE.md 없음 → Web Claude Code 환경 → 아래 규칙 적용
```

---

## 세션 시작 시 필수 출력 — 최우선 실행

**사용자 첫 입력이 무엇이든 반드시 아래 블록을 먼저 출력할 것.**

```
⚙️ LightHarness 로딩 상태

[하네스 구조]
  ✅ CLAUDE.md          로드됨
  ✅ CLAUDE-global.md   로드됨
  ✅ CLAUDE-global-web.md 로드됨
  스킬 경로: skills/ (lightharness-web 직접) 또는 .claude/lhw/skills/ (submodule)
  ✅ wharness.md        대기 중
  ✅ wharness-run.md    대기 중
  ✅ wharness-check.md  대기 중
  ✅ wrsm.md            대기 중

[2-Tier LLM 구조]
  Tier 1 — Claude Sonnet : 현재 세션 (조율·판단·코드)   ✅ 활성
  Tier 2 — Claude Haiku  : Agent(model="haiku") 위임   ✅ 준비됨
  에스컬레이션: Tier 2 실패 → Tier 1 직접 처리

[세션]
  tasks/todo.md: 존재 여부 확인 후 표시
```

이후 사용자 입력에 응답할 것.

---

## 스킬 로드

세션 시작 시 환경 감지 후 아래 스킬 파일을 읽어둡니다.
슬래시 커맨드 불필요 — 자연어 명령으로 실행됩니다.

스킬 파일 경로 자동 판별:
```
skills/ 존재             → lightharness-web 레포 직접 작업 (skills/ 사용)
.claude/lhw/skills/ 존재 → submodule로 연결된 프로젝트 (.claude/lhw/skills/ 사용)
```

| 트리거 | 스킬 파일 | 역할 |
|---|---|---|
| "하네스 설계", "blueprint 만들어" | `wharness.md` | Blueprint 설계 |
| "하네스 실행", "blueprint 실행" | `wharness-run.md` | Blueprint 실행 |
| "하네스 체크", "코드 점검" | `wharness-check.md` | 코드 정적 버그 감사 |
| "wrsm", "세션 시작", "이어서" | `wrsm.md` (LOAD) | 세션 재개 |
| "wrsm log", "세션 종료" | `wrsm.md` (SAVE) | 세션 저장 |
