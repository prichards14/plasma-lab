#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="prichards14/plasma-lab"
gh api user --jq .login
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
 git init -b main
fi
if [[ "$(git branch --show-current)" != "main" ]]; then
 echo "Run this script on the main branch; leaving the current branch unchanged." >&2
 exit 1
fi
git add .gitignore .github README.md index.html macos docs downloads scripts
if ! git diff --cached --quiet; then
 git commit -m "Add Plasma Lab web demo, macOS screen saver, and GitHub Pages deployment"
fi
if ! gh repo view "$REPO" --json name >/dev/null 2>&1; then
 gh repo create "$REPO" --public --description "Amiga-inspired plasma playground and native macOS screen saver"
else
 VISIBILITY="$(gh repo view "$REPO" --json visibility --jq .visibility)"
 if [[ "$VISIBILITY" != "PUBLIC" ]]; then
  gh repo edit "$REPO" --visibility public --accept-visibility-change-consequences
 fi
fi
REMOTE="https://github.com/$REPO.git"
if git remote get-url origin >/dev/null 2>&1; then
 EXISTING="$(git remote get-url origin)"
 if [[ "$EXISTING" != "$REMOTE" && "$EXISTING" != "git@github.com:$REPO.git" ]]; then
  echo "Origin points to another repository; leaving it unchanged." >&2
  exit 1
 fi
else
 git remote add origin "$REMOTE"
fi
git push -u origin main
if gh api "repos/$REPO/pages" >/dev/null 2>&1; then
 gh api --method PUT "repos/$REPO/pages" -f build_type=workflow >/dev/null
else
 gh api --method POST "repos/$REPO/pages" -f build_type=workflow >/dev/null
fi
gh workflow run pages.yml --repo "$REPO" --ref main
printf 'Repository: https://github.com/%s\nExpected Pages URL after successful deployment: https://prichards14.github.io/plasma-lab/\n' "$REPO"
echo "Confirm the deployment in the repository's Actions tab."
