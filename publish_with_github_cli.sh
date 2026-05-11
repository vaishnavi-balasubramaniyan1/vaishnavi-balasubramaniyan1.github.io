#!/usr/bin/env bash
set -euo pipefail

OWNER="${GITHUB_OWNER:-pravinkumarvr}"
REPO_NAME="${GITHUB_REPO_NAME:-pravinkumarvr.github.io}"
SITE_URL="https://${OWNER}.github.io/"
RESUME_FILE="Vaishnavi_Balasubramaniyan_Resume.pdf"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required. Install it from https://cli.github.com/ and run: gh auth login"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
fi

if [ ! -f "index.html" ] || [ ! -f "$RESUME_FILE" ]; then
  echo "Run this script from the folder containing index.html and $RESUME_FILE."
  exit 1
fi

# Prepare local git repository.
git init >/dev/null
if git rev-parse --verify main >/dev/null 2>&1; then
  git checkout main >/dev/null
else
  git checkout -B main >/dev/null
fi

git add index.html "$RESUME_FILE" README.md .nojekyll publish_with_github_cli.sh
if ! git diff --cached --quiet; then
  git commit -m "Publish portfolio website" >/dev/null
fi

# Create the GitHub repository if it does not exist; otherwise push to the existing one.
if gh repo view "${OWNER}/${REPO_NAME}" >/dev/null 2>&1; then
  git remote remove origin >/dev/null 2>&1 || true
  git remote add origin "https://github.com/${OWNER}/${REPO_NAME}.git"
  git push -u origin main
else
  gh repo create "${OWNER}/${REPO_NAME}" --public --source=. --remote=origin --push
fi

# Enable GitHub Pages from the main branch root.
PAGES_PAYLOAD="$(mktemp)"
printf '{"source":{"branch":"main","path":"/"}}' > "$PAGES_PAYLOAD"
if gh api "/repos/${OWNER}/${REPO_NAME}/pages" >/dev/null 2>&1; then
  gh api --method PUT "/repos/${OWNER}/${REPO_NAME}/pages" --input "$PAGES_PAYLOAD" >/dev/null
else
  gh api --method POST "/repos/${OWNER}/${REPO_NAME}/pages" --input "$PAGES_PAYLOAD" >/dev/null
fi
rm -f "$PAGES_PAYLOAD"

echo "Portfolio repository: https://github.com/${OWNER}/${REPO_NAME}"
echo "Portfolio URL: ${SITE_URL}"
