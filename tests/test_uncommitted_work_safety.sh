#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=uncommitted-safety
init_repo "$fixture"
create_cache_branch "$fixture"
git switch -q -C feature main
cp "$FIXTURES/$fixture/feature-committed.txt" app.txt
git add app.txt && git commit -qm 'feature commit'
cp "$FIXTURES/$fixture/uncommitted.txt" notes.txt
before=$(git rev-parse HEAD)

output=$(git patch add cache 2>&1 || true)
assert_contains "$output" "stash@{0}"
assert_contains "$output" "Ingen endringer ble gjort"
assert_equals "$before" "$(git rev-parse HEAD)"
assert_file_equals "$FIXTURES/$fixture/uncommitted.txt" notes.txt
git stash list | grep -q 'git-patch'
