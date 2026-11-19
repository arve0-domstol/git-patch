#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=list
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
