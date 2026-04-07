#!/bin/bash
# LightHarness Web — Bootstrap Script
# Usage: curl -sL https://raw.githubusercontent.com/Seeuferil/lightharness-web/main/bootstrap.sh | bash
#
# 어떤 프로젝트 repo에서든 실행하면:
#   1. .claude/lhw submodule 추가
#   2. CLAUDE.md에 import 줄 삽입
#   3. .claude/settings.json에 SessionStart hook 추가
#   4. .claude/commands/ 에 슬래시 커맨드 심링크 생성
#   5. .mcp.json 템플릿 복사 (Gemini MCP)
#   6. commit

set -e

# ── 프로젝트 repo 루트 확인 ────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ git repo가 아닙니다. 프로젝트 repo 루트에서 실행하세요."
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

LHW_PATH=".claude/lhw"
CLAUDE_DIR=".claude"
COMMANDS_DIR=".claude/commands"
CLAUDE_MD="CLAUDE.md"
SETTINGS_JSON=".claude/settings.json"
MCP_JSON=".mcp.json"
LHW_REPO="https://github.com/Seeuferil/lightharness-web"

echo "🔧 LightHarness Web bootstrap 시작..."
echo "   대상: $REPO_ROOT"

# ── Step 1: submodule 추가 ─────────────────────────────────
if [ -d "$LHW_PATH/.git" ] || [ -f "$LHW_PATH/CLAUDE.md" ]; then
  echo "✅ submodule 이미 존재 — 건너뜁니다."
else
  echo "📦 submodule 추가 중..."
  git submodule add "$LHW_REPO" "$LHW_PATH"
  git submodule update --init --recursive
  echo "✅ submodule 추가 완료"
fi

# ── Step 2: 루트 CLAUDE.md에 import 줄 추가 ────────────────
if [ ! -f "$CLAUDE_MD" ]; then
  echo "📝 CLAUDE.md 생성 중..."
  cat > "$CLAUDE_MD" << 'EOF'
@.claude/lhw/CLAUDE.md

# Project Rules
<!-- 프로젝트 전용 규칙을 여기에 추가하세요 -->
EOF
  echo "✅ CLAUDE.md 생성 완료"
else
  if grep -q "@.claude/lhw/CLAUDE.md" "$CLAUDE_MD"; then
    echo "✅ CLAUDE.md 이미 import 줄 존재 — 건너뜁니다."
  else
    echo "📝 CLAUDE.md에 import 줄 추가 중..."
    EXISTING=$(cat "$CLAUDE_MD")
    printf '@.claude/lhw/CLAUDE.md\n\n%s\n' "$EXISTING" > "$CLAUDE_MD"
    echo "✅ import 줄 추가 완료"
  fi
fi

# ── Step 3: .claude/settings.json에 SessionStart hook 추가 ─
mkdir -p "$CLAUDE_DIR"

if [ ! -f "$SETTINGS_JSON" ]; then
  echo "📝 .claude/settings.json 생성 중..."
  cat > "$SETTINGS_JSON" << 'JSONEOF'
{
  "hooks": {
    "SessionStart": [
      {
        "command": "[ ! -f \"$HOME/.claude/CLAUDE.md\" ] && [ -f .gitmodules ] && git submodule update --init --recursive 2>/dev/null; true"
      }
    ]
  }
}
JSONEOF
  echo "✅ settings.json 생성 완료"
else
  if grep -q "submodule update" "$SETTINGS_JSON"; then
    echo "✅ settings.json 이미 SessionStart hook 존재 — 건너뜁니다."
  else
    echo "📝 settings.json에 SessionStart hook 추가 중..."
    HOOK_CMD='[ ! -f "$HOME/.claude/CLAUDE.md" ] && [ -f .gitmodules ] && git submodule update --init --recursive 2>/dev/null; true'
    if command -v jq > /dev/null 2>&1; then
      TMP=$(mktemp)
      jq --arg cmd "$HOOK_CMD" '
        .hooks.SessionStart = (.hooks.SessionStart // []) + [{"command": $cmd}]
      ' "$SETTINGS_JSON" > "$TMP" && mv "$TMP" "$SETTINGS_JSON"
      echo "✅ SessionStart hook 추가 완료 (jq merge)"
    else
      echo "⚠️  jq가 없어 자동 머지 불가 — .claude/settings.json에 수동 추가 필요"
    fi
  fi
fi

# ── Step 4: .claude/commands/ 심링크 생성 ──────────────────
mkdir -p "$COMMANDS_DIR"

for CMD in wharness wharness-run wrsm; do
  SRC="../lhw/commands/${CMD}.md"
  DST="${COMMANDS_DIR}/${CMD}.md"
  if [ -L "$DST" ] || [ -f "$DST" ]; then
    echo "✅ commands/${CMD}.md 이미 존재 — 건너뜁니다."
  else
    echo "🔗 commands/${CMD}.md 심링크 생성 중..."
    ln -s "$SRC" "$DST"
    echo "✅ /${CMD} 등록 완료"
  fi
done

# ── Step 5: .mcp.json 템플릿 복사 (Gemini MCP) ────────────
if [ ! -f "$MCP_JSON" ]; then
  if [ -f "$LHW_PATH/mcp.template.json" ]; then
    echo "📝 .mcp.json 템플릿 복사 중..."
    cp "$LHW_PATH/mcp.template.json" "$MCP_JSON"
    echo "✅ .mcp.json 생성 완료 (GEMINI_API_KEY 환경변수 설정 필요)"
  fi
else
  echo "✅ .mcp.json 이미 존재 — 건너뜁니다."
fi

# ── Step 6: commit ─────────────────────────────────────────
echo "💾 변경사항 commit 중..."
git add "$LHW_PATH" "$CLAUDE_MD" "$SETTINGS_JSON" "$COMMANDS_DIR" .gitmodules 2>/dev/null || true
git add "$MCP_JSON" 2>/dev/null || true
git commit -m "chore: add LightHarness Web with commands and Gemini MCP" 2>/dev/null || echo "   (커밋할 변경사항 없음)"

echo ""
echo "🎉 bootstrap 완료!"
echo "   Web/Mac 양쪽에서 이 repo를 열면 슬래시 커맨드가 자동 등록됩니다."
echo ""
echo "   사용 가능한 커맨드:"
echo "     /wharness [목표]   — Blueprint 설계"
echo "     /wharness-run      — Blueprint 실행"
echo "     /wrsm              — 세션 시작 (GitHub Issues 조회)"
echo "     /wrsm log          — 세션 종료 (GitHub Issues 저장)"
echo ""
echo "   Gemini Tier 2를 사용하려면 GEMINI_API_KEY 환경변수를 설정하세요."
