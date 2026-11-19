#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=check-conflicts
init_repo "$fixture"
create_cache_branch "$fixture"
git switch -q -C feature main
cp "$FIXTURES/$fixture/feature.txt" app.txt
git add app.txt && git commit -qm 'conflicting feature'
before=$(git rev-parse HEAD)

output=$(git patch check-conflicts cache 2>&1 || true)
assert_contains "$output" "app.txt"
assert_contains "$output" "conflict"
assert_equals "$before" "$(git rev-parse HEAD)"
if git status --porcelain | grep -q .; then
  fail "check-conflicts changed the worktree"
fi
