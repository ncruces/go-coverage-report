#!/usr/bin/env bash
set -euo pipefail

cd "$1"

git add --all

# Exit if no changes.
git diff-index --quiet HEAD && exit

git config --local user.name  "GitHub Action"
git config --local user.email "action@github.com"

if [[ "${INPUT_AMEND-true}" == "true" ]]; then
  git commit --amend --no-edit
else
  git commit -m"Update coverage"
fi

# Push to wiki, retrying up to 10 times.
for _ in {1..10}; do
  git pull --rebase
  git push --force-with-lease && exit || c=$?
done
exit "$c"