#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=drop-all
init_repo "$fixture"
create_cache_branch "$fixture"
git switch -q -c logging main
cp "$FIXTURES/$fixture/logging.txt" logging.txt
git add logging.txt && git commit -qm 'logging'
create_feature_branch "$fixture"
git patch add cache
git patch add logging
git patch drop

list=$(git patch list)
assert_equals "0 active patches" "$list"
git grep -q 'cache change' HEAD && fail "cache remained"
git grep -q 'logging change' HEAD && fail "logging remained"
git grep -q 'feature work' HEAD
