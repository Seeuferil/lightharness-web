#!/bin/bash
# LightHarness Web — Bootstrap Script
# Usage: curl -sL https://raw.githubusercontent.com/Seeuferil/lightharness-web/main/bootstrap.sh | bash

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
LHW_PATH=".claude/lhw"
CLAUDE_DIR=".claude"
CLAUDE_MD=".claude/CLAUDE.md"
LHW_REPO="https://github.com/Seeuferil/lightharness-web"

echo "🔧 LightHarness Web bootstrap 시작..."
echo "   대상: $REPO_ROOT"

# ── Step 1: submodule 추가 ─────────────────────────────────
if [ -d "$REPO_ROOT/$LHW_PATH/.git" ] || [ -f "$REPO_ROOT/$LHW_PATH/CLAUDE.md" ]; then
  echo "✅ submodule 이미 존재 — 건너뜁니다."
else
  echo "📦 submodule 추가 중..."
  git submodule add "$LHW_REPO" "$LHW_PATH"
  git submodule update --init --recursive
  echo "✅ submodule 추가 완료"
fi

# ── Step 2: .claude/CLAUDE.md 생성 또는 import 줄 추가 ─────
mkdir -p "$REPO_ROOT/$CLAUDE_DIR"

if [ ! -f "$REPO_ROOT/$CLAUDE_MD" ]; then
  echo "📝 .claude/CLAUDE.md 생성 중..."
  cat > "$REPO_ROOT/$CLAUDE_MD" << 'EOF'
@.claude/lhw/CLAUDE.md

## Project Rules
<!-- 프로젝트 전용 규칙을 여기에 추가하세요 -->
EOF
  echo "✅ .claude/CLAUDE.md 생성 완료"
else
  # 이미 존재하면 import 줄이 없을 때만 추가
  if grep -q "@.claude/lhw/CLAUDE.md" "$REPO_ROOT/$CLAUDE_MD"; then
    echo "✅ .claude/CLAUDE.md 이미 import 줄 존재 — 건너뜁니다."
  else
    echo "📝 .claude/CLAUDE.md에 import 줄 추가 중..."
    # 파일 맨 위에 import 줄 삽입
    EXISTING=$(cat "$REPO_ROOT/$CLAUDE_MD")
    echo "@.claude/lhw/CLAUDE.md" > "$REPO_ROOT/$CLAUDE_MD"
    echo "" >> "$REPO_ROOT/$CLAUDE_MD"
    echo "$EXISTING" >> "$REPO_ROOT/$CLAUDE_MD"
    echo "✅ import 줄 추가 완료"
  fi
fi

# ── Step 3: commit ─────────────────────────────────────────
echo "💾 변경사항 commit 중..."
git add "$LHW_PATH" "$CLAUDE_MD" .gitmodules 2>/dev/null || true
git commit -m "chore: add LightHarness Web submodule" 2>/dev/null || echo "   (커밋할 변경사항 없음)"

echo ""
echo "🎉 bootstrap 완료!"
echo "   Web Claude Code에서 이 repo를 열면 LightHarness Web이 자동으로 로드됩니다."
echo ""
echo "   사용 가능한 커맨드:"
echo "     /wharness [목표]   — Blueprint 설계"
echo "     /wharness-run      — Blueprint 실행"
echo "     /wharness-check    — 코드 정적 버그 감사"
echo "     /wrsm              — 세션 시작"
echo "     /wrsm log          — 세션 종료"
