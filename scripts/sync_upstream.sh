#!/bin/bash
# Daily sync: fast-forward main from upstream, push to origin, rebase the
# working branch on top, and push it too. Pure git — no LLM/agent involved.
set -uo pipefail

REPO="/Users/aryanagarwal/repos/TradingAgents"
BRANCH="claude/github-upload-check-e0fbcd"

cd "$REPO" || exit 1

echo "=== sync run: $(date) ==="

if [ -n "$(git status --porcelain)" ]; then
  echo "Uncommitted changes present in $REPO — aborting sync, not touching anything."
  exit 1
fi

git fetch upstream || { echo "fetch upstream failed"; exit 1; }
git fetch origin || { echo "fetch origin failed"; exit 1; }

git checkout main || exit 1
if ! git merge --ff-only upstream/main; then
  echo "main cannot fast-forward to upstream/main (local divergence) — aborting."
  exit 1
fi
git push origin main || { echo "push origin main failed"; exit 1; }

if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "branch $BRANCH not found locally — skipping rebase step."
  exit 0
fi

git checkout "$BRANCH" || exit 1
if ! git rebase main; then
  echo "rebase conflict on $BRANCH — aborting rebase, leaving branch untouched."
  git rebase --abort
  exit 1
fi
git push --force-with-lease origin "$BRANCH" || { echo "push $BRANCH failed"; exit 1; }

echo "sync complete."
