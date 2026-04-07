@CLAUDE-global-web.md

---

# LightHarness Web

## 환경 감지 — 최우선 실행

```
~/.claude/CLAUDE.md 존재 → Mac Dev 환경 → 이 파일의 모든 규칙 무시하고 종료
~/.claude/CLAUDE.md 없음 → Web Claude Code 환경 → 아래 규칙 적용
```

---

## 스킬 로드

세션 시작 시 환경 감지 후 스킬을 자동으로 읽어 슬래시 커맨드로 등록합니다.

스킬 파일 경로 자동 판별:
```
skills/ 존재             → lightharness-web 레포 직접 작업 (skills/ 사용)
.claude/lhw/skills/ 존재 → submodule로 연결된 프로젝트 (.claude/lhw/skills/ 사용)
```

| 커맨드 | submodule 경로 | 직접 작업 경로 | 역할 |
|---|---|---|---|
| `/wharness` | `.claude/lhw/skills/wharness.md` | `skills/wharness.md` | Blueprint 설계 |
| `/wharness-run` | `.claude/lhw/skills/wharness-run.md` | `skills/wharness-run.md` | Blueprint 실행 |
| `/wharness-check` | `.claude/lhw/skills/wharness-check.md` | `skills/wharness-check.md` | 코드 정적 버그 감사 |
| `/wrsm` | `.claude/lhw/skills/wrsm.md` | `skills/wrsm.md` | 세션 핸드오프 |
