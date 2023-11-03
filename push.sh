#!/usr/bin/env bash
set -euo pipefail

cd "$1"

git add --all

# Exit if no changes.
git diff-index --quiet HEAD && exit

# https://github.com/orgs/community/discussions/26560
git config --local user.name  "github-actions[bot]"
git config --local user.email "41898282+github-actions[bot]@users.noreply.github.com"

# Amend the wiki, fails-safe with concurrent modifications.
if [[ "${INPUT_AMEND-true}" == "true" ]]; then
  git commit --amend --no-edit
  git push --force-with-lease
  exit
fi

git commit -m "Update coverage"

# Push to wiki, retrying up to 10 times.
for _ in {1..10}; do
  git pull --rebase
  git push --force-with-lease && exit || c=$?
done
exit "$c"