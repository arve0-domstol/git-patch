#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=list
empty_repo="$TEST_TMP/empty"
git init -q -b main "$empty_repo"
cd "$empty_repo"
assert_equals "0 active patches" "$(git patch list)"

init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"
git patch add cache

git switch -q cache
cp "$FIXTURES/$fixture/cache-newer.txt" app.txt
git commit -qam 'review update'
git switch -q feature
output=$(git patch list)

assert_contains "$output" "1"
assert_contains "$output" "cache"
assert_contains "$output" "cache"
assert_contains "$output" "outdated"
assert_contains "$output" "conflicts: none"

git switch -q -c logging main
printf 'logging\n' >logging.txt
git add logging.txt
git commit -qm 'logging'
git switch -q feature
git patch add logging

git switch -q cache
git reset --hard -q main
printf 'cache current\n' >app.txt
git commit -qam 'current cache'
git switch -q logging
git reset --hard -q main
printf 'logging current\n' >app.txt
git commit -qam 'current logging'
git switch -q feature

objects_before=$(git count-objects -v)
head_before=$(git rev-parse HEAD)
status_before=$(git status --porcelain --untracked-files=all)
refs_before=$(git show-ref)
output=$(git patch list)

assert_contains "$output" "cache"
assert_contains "$output" "logging"
assert_contains "$output" "source: cache (outdated)"
assert_contains "$output" "source: logging (outdated)"
assert_contains "$output" "conflicts: app.txt"
assert_equals "$objects_before" "$(git count-objects -v)"
assert_equals "$head_before" "$(git rev-parse HEAD)"
assert_equals "$status_before" "$(git status --porcelain --untracked-files=all)"
assert_equals "$refs_before" "$(git show-ref)"
