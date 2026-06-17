#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  Velaris Marketplace — push the official/ folder only
#
#  Stages ONLY official/, verifies nothing outside official/ is staged,
#  commits with the message you provide, and pushes to origin/main.
#
#  Usage:
#    ./push-official.sh "your commit message"
#
#  Scope guard: community/ (and anything else) is never committed by this
#  script — it aborts if the staged set contains a path outside official/.
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

red()   { echo -e "\033[0;31m$*\033[0m"; }
green() { echo -e "\033[0;32m$*\033[0m"; }
bold()  { echo -e "\033[1m$*\033[0m"; }

MSG="${1:-}"
if [ -z "$MSG" ]; then
  red "✗ No commit message. Usage: ./push-official.sh \"your commit message\""
  exit 1
fi

# Must be inside the marketplace git repo.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  red "✗ Not a git repository: $REPO_DIR"
  exit 1
fi

REMOTE_URL="$(git remote get-url origin 2>/dev/null || echo '<none>')"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
bold "Repo:   $REPO_DIR"
bold "Remote: $REMOTE_URL"
bold "Branch: $BRANCH"
echo

# Stage ONLY official/ (tracked changes, new files, and deletions).
git add -A -- official/

# Hard guard: abort if the staged set contains anything outside official/.
OUTSIDE="$(git diff --cached --name-only | grep -v '^official/' || true)"
if [ -n "$OUTSIDE" ]; then
  red "✗ Refusing to commit — these staged paths are outside official/:"
  echo "$OUTSIDE"
  red "  Unstage them (git restore --staged <path>) and re-run."
  exit 1
fi

STAGED="$(git diff --cached --name-only -- official/ || true)"
if [ -z "$STAGED" ]; then
  green "Nothing to commit under official/ — working tree clean."
  exit 0
fi

bold "Staged (official/ only):"
echo "$STAGED" | sed 's/^/  /'
echo
git --no-pager diff --cached --stat -- official/
echo

read -r -p "Commit the above and push to $BRANCH? [y/N] " ANS
if [ "$ANS" != "y" ] && [ "$ANS" != "Y" ]; then
  red "Aborted — changes left staged."
  exit 1
fi

git commit -m "$MSG"
git push origin "$BRANCH"
green "✓ Pushed official/ to origin/$BRANCH"
