#!/usr/bin/env bash
# (Public) prerequisites bootstrap — runs the "One-time prerequisites"
# steps from the README (see README for details)

set -euo pipefail

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
info() { printf '    %s\n' "$1"; }
warn() { printf '    \033[33mwarning:\033[0m %s\n' "$1" >&2; }

# -----------------------------------------------------------------------
# [1/3] Homebrew
# -----------------------------------------------------------------------
step "[1/3] Homebrew"

if command -v brew >/dev/null 2>&1; then
  info "Already installed at: $(command -v brew)"
else
  info "Installing Homebrew (you may be prompted for your Mac password)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# -----------------------------------------------------------------------
# [2/3] PATH — Apple Silicon vs Intel
# -----------------------------------------------------------------------
step "[2/3] Add Homebrew to PATH"

if [ -x /opt/homebrew/bin/brew ]; then
  BREW=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
  BREW=/usr/local/bin/brew
else
  warn "Couldn't find brew at /opt/homebrew/bin/brew or /usr/local/bin/brew"
  warn "Homebrew install may have failed. Re-run this script after fixing."
  exit 1
fi
info "Detected brew at: $BREW"

# Make it available in the current session — without this, the next `brew` call below fails.
eval "$($BREW shellenv)"

# Persist to ~/.zshrc (idempotent — only append if not already there).
RC="$HOME/.zshrc"
touch "$RC"
SHELLENV_LINE="eval \"\$($BREW shellenv)\""
if grep -qF "$BREW shellenv" "$RC" 2>/dev/null; then
  info "$RC already has the brew shellenv line."
else
  printf '\n# Added by cureneo bootstrap-prereqs (Homebrew PATH)\n%s\n' "$SHELLENV_LINE" >> "$RC"
  info "Appended brew shellenv line to $RC"
fi

# -----------------------------------------------------------------------
# [3/3] GitHub CLI
# -----------------------------------------------------------------------
step "[3/3] GitHub CLI (gh)"

if command -v gh >/dev/null 2>&1; then
  info "Already installed at: $(command -v gh)"
else
  info "Installing gh..."
  brew install gh
fi

# -----------------------------------------------------------------------
# Done — print the manual next steps
# -----------------------------------------------------------------------
cat <<'EOF'

==> Prerequisites installed

EOF
