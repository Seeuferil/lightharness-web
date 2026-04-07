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

## 도입 방법

### 방법 A: bootstrap 스크립트 (터미널 환경)

```bash
# 프로젝트 repo 루트에서 한 줄 실행
curl -sL https://raw.githubusercontent.com/Seeuferil/lightharness-web/main/bootstrap.sh | bash
```

submodule 추가 → CLAUDE.md import 줄 삽입 → commit까지 자동 처리됩니다.

### 방법 B: 수동 설정

```bash
# 1. submodule 추가
git submodule add https://github.com/Seeuferil/lightharness-web .claude/lhw

# 2. 루트 CLAUDE.md 첫 줄에 import 추가
#    (기존 CLAUDE.md가 있으면 맨 위에 한 줄만 추가)
```

**CLAUDE.md 예시** (루트 위치):

```markdown
@.claude/lhw/CLAUDE.md

# Bootstrap Rule
...프로젝트 전용 규칙...

@CLAUDE-global.md
@CLAUDE-sub.md
```

> **핵심**: `@.claude/lhw/CLAUDE.md`를 **루트 CLAUDE.md 첫 줄**에 놓으면 Web Claude Code 세션 시작 시 자동으로 LightHarness 규칙이 로드됩니다.

### 방법 C: Web Claude Code에서 직접 도입 (권장)

Web Claude Code 세션에서 터미널 접근 없이 도입할 때:

```
"이 프로젝트에 lightharness-web을 도입해줘"
```

Claude가 아래를 순서대로 수행합니다:
1. `git submodule add` 실행
2. 루트 CLAUDE.md에 `@.claude/lhw/CLAUDE.md` import 줄 추가
3. commit & push

---

## clone 후 서브모듈 초기화 (중요)

이미 lightharness-web이 도입된 프로젝트를 **새로 clone**하면 `.claude/lhw/` 디렉토리가 **비어 있습니다**. 반드시 초기화가 필요합니다:

```bash
git submodule update --init .claude/lhw
```

### Web Claude Code에서 자동 초기화

Web Claude Code는 repo를 새 세션마다 fresh clone합니다. 서브모듈이 자동 초기화되지 않으므로, 프로젝트 루트에 **SessionStart hook**을 설정하면 매 세션 자동 초기화됩니다:

**.claude/settings.json**:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "command": "git submodule update --init --recursive 2>/dev/null || true"
      }
    ]
  }
}
```

또는 CLAUDE.md에 초기화 지시를 포함할 수 있습니다:

```markdown
@.claude/lhw/CLAUDE.md

# Init
IF .claude/lhw/CLAUDE.md NOT EXISTS:
  RUN: git submodule update --init .claude/lhw
```

---

## submodule 업데이트

```bash
# 최신 버전으로 업데이트
git submodule update --remote .claude/lhw
git add .claude/lhw
git commit -m "chore: update lightharness-web submodule"
```

---

## 슬래시 커맨드

| 커맨드 | 설명 |
|---|---|
| `/harness [목표]` | Blueprint 설계 |
| `/harness-run` | Blueprint 실행 |
| `/rsm` | 세션 시작 — 이어서 할 일 출력 |
| `/rsm log` | 세션 종료 — 다음 할 일 TaskCreate 저장 |

---

## Blueprint 저장 위치

- **프로젝트 전용** → `.claude/blueprints/{name}.yaml`
- **재사용 템플릿** → `.claude/lhw/blueprints/{name}.yaml`

---

## 디렉토리 구조

```
.claude/lhw/                  ← 이 repo (submodule)
├── CLAUDE.md                 # 프레임워크 규칙 (자동 로드)
├── README.md                 # 이 파일
├── bootstrap.sh              # 자동 설정 스크립트
├── blueprints/
│   └── _example.yaml         # Blueprint 템플릿 예시
└── skills/
    ├── harness.md            # /harness 스킬
    ├── harness-run.md        # /harness-run 스킬
    └── rsm.md                # /rsm 스킬
```

## 실전 적용 예시: subway-tracker

```
subway-tracker/
├── CLAUDE.md                 # 첫 줄: @.claude/lhw/CLAUDE.md
├── .gitmodules               # [submodule ".claude/lhw"]
├── .claude/
│   ├── lhw/                  # ← lightharness-web submodule
│   └── blueprints/           # 프로젝트 전용 Blueprint
└── ...
```
