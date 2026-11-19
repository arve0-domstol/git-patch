#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=sync-patch
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"
git patch add cache

git switch -q cache
cp "$FIXTURES/$fixture/cache-revised.txt" app.txt
git commit -qam 'revise cache'
git switch -q feature
git patch sync cache

assert_file_equals "$FIXTURES/$fixture/cache-revised.txt" app.txt
git grep -q 'feature work' HEAD
assert_contains "$(git patch log)" "synced cache"
