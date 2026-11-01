#!/usr/bin/env bash
# Deploys the Lumi Vance site to GitHub Pages under whichever account `gh` is
# logged into. Safe to re-run: if the repo already exists it just pushes updates.
#
#   bash website/deploy.sh
#
# Prereqs: `gh` CLI installed (brew install gh) and logged in:
#   gh auth login --hostname github.com --git-protocol https --web

set -euo pipefail
REPO="lumivance-site"
cd "$(dirname "$0")"

command -v gh >/dev/null || { echo "gh not installed. Run: brew install gh"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Not logged in. Run: gh auth login --hostname github.com --git-protocol https --web"; exit 1; }

USER=$(gh api user --jq '.login')
echo "Deploying as: $USER"

if [ ! -d .git ]; then
  git init -b main -q
  git config user.name "$USER"
  git config user.email "${USER}@users.noreply.github.com"
fi

git add -A
git commit -q -m "Deploy Lumi Vance marketing site" || echo "(nothing new to commit)"

if gh repo view "$USER/$REPO" >/dev/null 2>&1; then
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USER/$REPO.git"
  git push -u origin main
else
  gh repo create "$REPO" --public --source=. --push \
    --description "Lumi Vance — marketing site (disclosed AI-generated character brand)"
fi

# Enable Pages (ignore error if already enabled)
gh api "repos/$USER/$REPO/pages" -X POST -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || echo "(Pages already enabled)"

URL="https://$USER.github.io/$REPO/"
echo
echo "Deployed. Live in a minute or two at:"
echo "  $URL"
echo
echo "NOTE: 404.html uses root-absolute paths prefixed with /$REPO/."
echo "If you rename the repo, update those links in 404.html."
