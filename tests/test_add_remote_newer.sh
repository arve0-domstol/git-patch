#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=add-remote-newer
init_repo "$fixture"
create_cache_branch "$fixture"

git switch -q cache
old_cache=$(git rev-parse HEAD)
cp "$FIXTURES/$fixture/cache-remote.txt" app.txt
git commit -qam 'new remote cache'
git push -q origin cache
git switch -q main
git branch -f cache "$old_cache"
git switch -q -c feature main

output=$(git patch add cache 2>&1)
assert_contains "$output" "origin/cache er nyere enn lokal cache"
assert_contains "$output" "Lokal cache ble lagt til"
git grep -q 'local cache' HEAD
git grep -q 'remote cache' HEAD && fail "remote cache was applied"
