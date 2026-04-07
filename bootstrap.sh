#!/bin/bash
# LightHarness Web — Bootstrap Script
# Usage: curl -sL https://raw.githubusercontent.com/Seeuferil/lightharness-web/main/bootstrap.sh | bash
#
# 어떤 프로젝트 repo에서든 실행하면:
#   1. .claude/lhw submodule 추가
#   2. CLAUDE.md에 import 줄 삽입
#   3. .claude/settings.json에 SessionStart hook 추가 (서브모듈 자동 초기화)
#   4. commit
#
# Mac Mini 환경(~/.claude/CLAUDE.md 존재)에서는 실행하지 않습니다.

set -e

# ── 환경 감지 ──────────────────────────────────────────────
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  echo "⚠️  Mac Mini 환경 감지 — bootstrap을 실행하지 않습니다."
  echo "   Mac 환경에서는 기존 구조를 사용하세요."
  exit 0
fi

# ── 프로젝트 repo 루트 확인 ────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ git repo가 아닙니다. 프로젝트 repo 루트에서 실행하세요."
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

LHW_PATH=".claude/lhw"
CLAUDE_DIR=".claude"
CLAUDE_MD="CLAUDE.md"
SETTINGS_JSON=".claude/settings.json"
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

# SessionStart hook: Web 환경에서만 서브모듈 자동 초기화
# Mac Mini 가드: ~/.claude/CLAUDE.md 존재 시 스킵
HOOK_CMD='[ ! -f "$HOME/.claude/CLAUDE.md" ] && [ -f .gitmodules ] && git submodule update --init --recursive 2>/dev/null; true'

if [ ! -f "$SETTINGS_JSON" ]; then
  echo "📝 .claude/settings.json 생성 중..."
  cat > "$SETTINGS_JSON" << JSONEOF
{
  "hooks": {
    "SessionStart": [
      {
        "command": "$HOOK_CMD"
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
    # jq가 있으면 안전하게 머지, 없으면 경고
    if command -v jq > /dev/null 2>&1; then
      TMP=$(mktemp)
      jq --arg cmd "$HOOK_CMD" '
        .hooks.SessionStart = (.hooks.SessionStart // []) + [{"command": $cmd}]
      ' "$SETTINGS_JSON" > "$TMP" && mv "$TMP" "$SETTINGS_JSON"
      echo "✅ SessionStart hook 추가 완료 (jq merge)"
    else
      echo "⚠️  jq가 없어 자동 머지 불가 — 아래 내용을 .claude/settings.json에 수동 추가하세요:"
      echo ""
      echo "  \"hooks\": {"
      echo "    \"SessionStart\": [{\"command\": \"$HOOK_CMD\"}]"
      echo "  }"
    fi
  fi
fi

# ── Step 4: commit ─────────────────────────────────────────
echo "💾 변경사항 commit 중..."
git add "$LHW_PATH" "$CLAUDE_MD" "$SETTINGS_JSON" .gitmodules 2>/dev/null || true
git commit -m "chore: add LightHarness Web submodule with auto-init hook" 2>/dev/null || echo "   (커밋할 변경사항 없음)"

echo ""
echo "🎉 bootstrap 완료!"
echo "   Web Claude Code에서 이 repo를 열면 LightHarness Web이 자동으로 로드됩니다."
echo "   Mac Mini CLI에서는 hook이 자동 스킵됩니다."
echo ""
echo "   사용 가능한 커맨드:"
echo "     /harness [목표]   — Blueprint 설계"
echo "     /harness-run      — Blueprint 실행"
echo "     /rsm              — 세션 시작"
echo "     /rsm log          — 세션 종료"
