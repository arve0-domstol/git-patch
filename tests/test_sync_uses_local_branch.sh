#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=sync-local
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"
git patch add cache

git switch -q cache
cp "$FIXTURES/$fixture/cache-local.txt" app.txt
git commit -qam 'local cache'
local_cache=$(git rev-parse HEAD)
cp "$FIXTURES/$fixture/cache-remote.txt" app.txt
git commit -qam 'remote cache'
git push -q origin cache
git switch -q main
git branch -f cache "$local_cache"
git switch -q feature

output=$(git patch sync cache 2>&1)
assert_contains "$output" "origin/cache er nyere enn lokal cache"
assert_file_equals "$FIXTURES/$fixture/cache-local.txt" app.txt
