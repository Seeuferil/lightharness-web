# LightHarness Web

경량 에이전트 오케스트레이터 — Web Claude Code & Mac Mini CLI 양쪽 지원.

---

## 3-Tier 구조

| Tier | 모델 | 역할 | 호출 방식 |
|---|---|---|---|
| 1 | Claude (현재 세션) | 조율·판단·코드 작성 | 직접 처리 |
| 2 | Gemini Flash | 대형 파일 분석·Lint | Gemini MCP (`.mcp.json`) |
| 3 | Claude Haiku | 반복·요약·검색·커밋 메시지 | `Agent(model="haiku")` |

Gemini MCP 미연결 시 Tier 2 → Haiku 또는 Tier 1로 자동 폴백.

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
3. `.claude/settings.json`에 **SessionStart hook** 추가 (Web에서 서브모듈 자동 초기화)
4. `.claude/commands/` 에 슬래시 커맨드 심링크 (`/wharness`, `/wharness-run`, `/wrsm`)
5. `.mcp.json` 템플릿 복사 (Gemini MCP)
6. commit

### 방법 B: 수동 설정

```bash
# 1. submodule 추가
git submodule add https://github.com/Seeuferil/lightharness-web .claude/lhw

# 2. 루트 CLAUDE.md 첫 줄에 import 추가
# 3. 심링크 생성
mkdir -p .claude/commands
ln -s ../lhw/commands/wharness.md .claude/commands/wharness.md
ln -s ../lhw/commands/wharness-run.md .claude/commands/wharness-run.md
ln -s ../lhw/commands/wrsm.md .claude/commands/wrsm.md

# 4. (선택) Gemini MCP 설정
cp .claude/lhw/mcp.template.json .mcp.json
```

---

## 슬래시 커맨드

`.claude/commands/`에 하드 등록. Mac Mini의 `/harness`와 충돌하지 않도록 `w` 접두어 사용.

| 커맨드 | 설명 |
|---|---|
| `/wharness [목표]` | Blueprint 설계 |
| `/wharness-run` | Blueprint 실행 |
| `/wrsm` | 세션 시작 — GitHub Issues에서 할 일 조회 |
| `/wrsm log` | 세션 종료 — 완료 처리 + 다음 할 일 Issue 생성 |

---

## 세션 핸드오프 — GitHub Issues

`/wrsm`은 GitHub Issues를 영구 상태 저장소로 사용합니다.

| 라벨 | 용도 |
|---|---|
| `harness:pending` | 대기 중 태스크 |
| `harness:active` | 현재 진행 중 |
| `harness:completed` | 완료 |
| `blueprint` | Blueprint 설계 태스크 |
| `session-handoff` | 세션 핸드오프 메모 |

Web Claude Code와 Mac Mini CLI 양쪽에서 동일하게 작동합니다.

---

## SessionStart hook

Web Claude Code는 매 세션마다 fresh clone하므로 서브모듈이 비어 있습니다.
`.claude/settings.json`의 SessionStart hook이 자동 초기화합니다.

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

| 환경 | hook 동작 |
|---|---|
| **Web Claude Code** | 서브모듈 초기화 실행 |
| **Mac Mini CLI** | 스킵 (Mac Mini 가드) |

---

## Gemini MCP (Tier 2)

`.mcp.json`을 프로젝트 루트에 배치하면 양쪽 환경에서 로드됩니다.

```json
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/gemini-mcp"],
      "env": {
        "GEMINI_API_KEY": "${GEMINI_API_KEY}"
      }
    }
  }
}
```

`GEMINI_API_KEY` 환경변수 설정 필요. 미설정 시 Tier 2 자동 폴백.

---

## submodule 업데이트

```bash
git submodule update --remote .claude/lhw
git add .claude/lhw
git commit -m "chore: update lightharness-web submodule"
```

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
├── mcp.template.json         # Gemini MCP 설정 템플릿
├── blueprints/
│   └── _example.yaml         # Blueprint 템플릿 예시
├── commands/                 # 슬래시 커맨드 (심링크 원본)
│   ├── wharness.md           # /wharness
│   ├── wharness-run.md       # /wharness-run
│   └── wrsm.md               # /wrsm
└── skills/                   # 레거시 (소프트 참조용, 호환 유지)
    ├── harness.md
    ├── harness-run.md
    └── rsm.md
```

## 실전 적용 예시

bootstrap 실행 후 프로젝트 구조:

```
any-project/
├── CLAUDE.md                 # 첫 줄: @.claude/lhw/CLAUDE.md
├── .gitmodules               # [submodule ".claude/lhw"]
├── .mcp.json                 # Gemini MCP 설정
├── .claude/
│   ├── settings.json         # SessionStart hook
│   ├── commands/
│   │   ├── wharness.md → ../lhw/commands/wharness.md
│   │   ├── wharness-run.md → ../lhw/commands/wharness-run.md
│   │   └── wrsm.md → ../lhw/commands/wrsm.md
│   ├── lhw/                  # ← lightharness-web submodule
│   └── blueprints/           # 프로젝트 전용 Blueprint
└── ...
```

**흐름 요약**:

```
세션 시작
  → SessionStart hook (Web에서만 서브모듈 초기화)
  → .claude/lhw/CLAUDE.md 로드
  → .claude/commands/ 슬래시 커맨드 등록
  → /wrsm → GitHub Issues에서 할 일 로드
  → 준비 완료
```
