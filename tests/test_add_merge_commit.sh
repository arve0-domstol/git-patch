#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=add-merge-commit
init_repo "$fixture"

git switch -q -c cache main
cp "$FIXTURES/$fixture/cache.txt" cache.txt
git add cache.txt && git commit -qm 'cache one'
git switch -q -c cache-side main
cp "$FIXTURES/$fixture/cache-side.txt" side.txt
git add side.txt && git commit -qm 'cache side'
git switch -q cache
git merge -q --no-ff cache-side -m 'merge cache side'
git switch -q -C feature main

output=$(git patch add cache 2>&1 || true)
assert_contains "$output" "merge-commit"
