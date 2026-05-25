#!/usr/bin/env bash
#
# Cureneo prerequisites bootstrap — runs the §B "One-time prerequisites"
# steps from the README so non-technical team members only need to paste
# one curl-piped command into Terminal:
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cureneo/CureneoSetup/main/bin/bootstrap-prereqs.sh)"
#
# What it does:
#   [1/3] Install Homebrew (if missing).
#   [2/3] Add Homebrew to PATH for the current session AND persist to
#         ~/.zshrc — the step Homebrew's own installer only prints to
#         stdout, which non-technical users routinely miss. Apple Silicon
#         (/opt/homebrew) and Intel (/usr/local) both handled.
#   [3/3] Install the GitHub CLI (gh).
#
# What it deliberately does NOT do:
#   - `gh auth login` — needs the user's attention for the browser flow,
#     and a script can't shepherd that. Printed as a clear next-step.
#   - 1Password vault enrolment — needs an admin to add the user to the
#     shared vault, then the user to enable CLI integration in the
#     desktop app. Printed as a next-step.
#   - Anything from README §C (gh repo clone, install.sh, op signin) —
#     same reason: each needs the user's attention for prompts.
#
# Idempotent: safe to re-run after partial failures.

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

==> Prerequisites installed. Two manual steps remain (browser + admin involvement):

  1. Authenticate the GitHub CLI:

        gh auth login -h github.com

     Choose HTTPS + browser login. Your account must be in the `cureneo` org.

  2. 1Password vault access: confirm an admin has added you to the shared
     `Cureneo` vault, then enable CLI integration in the desktop app
     (1Password → Settings → Developer → Integrate with 1Password CLI).

Then follow README §C (Installation) to clone the setup repo and run install.sh.

EOF
