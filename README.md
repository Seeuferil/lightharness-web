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

### 방법 A: bootstrap 스크립트 (권장)

```bash
# 어떤 프로젝트 repo 루트에서든 한 줄 실행
curl -sL https://raw.githubusercontent.com/Seeuferil/lightharness-web/main/bootstrap.sh | bash
```

자동으로 수행되는 작업:
1. `.claude/lhw` submodule 추가
2. 루트 `CLAUDE.md` 첫 줄에 `@.claude/lhw/CLAUDE.md` import 삽입
3. `.claude/settings.json`에 **SessionStart hook** 추가 (서브모듈 자동 초기화)
4. commit

> Mac Mini 환경(`~/.claude/CLAUDE.md` 존재)에서는 자동으로 스킵됩니다.

### 방법 B: 수동 설정

```bash
# 1. submodule 추가
git submodule add https://github.com/Seeuferil/lightharness-web .claude/lhw

# 2. 루트 CLAUDE.md 첫 줄에 import 추가
# 3. .claude/settings.json에 SessionStart hook 추가 (아래 참고)
```

---

## SessionStart hook — 자동 초기화 (핵심)

Web Claude Code는 매 세션마다 fresh clone합니다. 서브모듈은 clone 시 비어 있으므로, **SessionStart hook**이 자동으로 초기화해야 합니다.

bootstrap 스크립트가 아래 파일을 자동 생성합니다:

**.claude/settings.json**:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "command": "[ ! -f \"$HOME/.claude/CLAUDE.md\" ] && [ -f .gitmodules ] && git submodule update --init --recursive 2>/dev/null; true"
      }
    ]
  }
}
```

### Mac Mini 안전 가드

hook 커맨드에 `[ ! -f "$HOME/.claude/CLAUDE.md" ]` 가드가 포함되어 있습니다:

| 환경 | `~/.claude/CLAUDE.md` | hook 동작 |
|---|---|---|
| **Web Claude Code** | 없음 | 서브모듈 초기화 실행 |
| **Mac Mini CLI** | 있음 | 스킵 (아무것도 안 함) |

이 파일은 프로젝트 repo에 커밋되므로, **어떤 프로젝트든** 이 hook이 있으면 Web 세션 시작 시 자동으로 lightharness-web이 로드됩니다. Mac Mini에서는 완전히 무시됩니다.

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

## 실전 적용 예시

bootstrap 실행 후 프로젝트 구조:

```
any-project/
├── CLAUDE.md                 # 첫 줄: @.claude/lhw/CLAUDE.md
├── .gitmodules               # [submodule ".claude/lhw"]
├── .claude/
│   ├── settings.json         # SessionStart hook (서브모듈 자동 초기화)
│   ├── lhw/                  # ← lightharness-web submodule
│   └── blueprints/           # 프로젝트 전용 Blueprint
└── ...
```

**흐름 요약**:

```
Web 세션 시작
  → SessionStart hook 실행
  → Mac Mini 가드 체크 (Web이면 통과)
  → git submodule update --init
  → .claude/lhw/CLAUDE.md 로드
  → 스킬(/harness, /harness-run, /rsm) 등록
  → 준비 완료
```
