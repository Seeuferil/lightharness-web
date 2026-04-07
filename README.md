# LightHarness Web

Web Claude Code (claude.ai/code) 전용 경량 에이전트 오케스트레이터.

Mac Mini CLI 버전과 완전히 독립된 구조입니다.

---

## 3-Tier 구조

| Tier | 모델 | 역할 |
|---|---|---|
| 1 | Claude Sonnet | 조율·판단·코드 작성 |
| 2 | Gemini Flash | 대형 파일 분석·Lint |
| 3 | Claude Haiku | 반복·요약·검색·커밋 메시지 |

---

## 프로젝트에 추가하는 방법

```bash
# 프로젝트 repo 루트에서
git submodule add https://github.com/Seeuferil/lightharness-web .claude/lhw

# 프로젝트 CLAUDE.md 생성
mkdir -p .claude
cat > .claude/CLAUDE.md << 'EOF'
# Project Rules
@.claude/lhw/CLAUDE.md

## 프로젝트 전용 규칙
(여기에 프로젝트 규칙 추가)
EOF
```

## submodule 업데이트

```bash
git submodule update --remote .claude/lhw
```

---

## 슬래시 커맨드

| 커맨드 | 설명 |
|---|---|
| `/wharness [목표]` | Blueprint 설계 |
| `/wharness-run` | Blueprint 실행 |
| `/wharness-check` | 코드 정적 버그 감사 |
| `/wrsm` | 세션 시작 — 이어서 할 일 출력 |
| `/wrsm log` | 세션 종료 — 다음 할 일 TaskCreate 저장 |

---

## Blueprint 저장 위치

- **프로젝트 전용** → `.claude/blueprints/{name}.yaml`
- **재사용 템플릿** → `.claude/lhw/blueprints/{name}.yaml`
