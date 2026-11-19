#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=drop-patch
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"
git patch add cache
git patch drop cache

git patch list | grep -q cache && fail "cache remained in the stack"
assert_file_equals "$FIXTURES/$fixture/expected.txt" app.txt
git grep -q 'feature work' HEAD
