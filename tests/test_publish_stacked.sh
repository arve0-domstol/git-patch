#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=publish-stacked
init_repo "$fixture"
create_cache_branch "$fixture"
git switch -q -c logging main
cp "$FIXTURES/$fixture/logging.txt" logging.txt
git add logging.txt && git commit -qm 'logging'
create_feature_branch "$fixture"
git patch add cache
git patch add logging

mkdir "$TEST_TMP/bin"
cp "$FIXTURES/$fixture/gh" "$TEST_TMP/bin/gh"
chmod +x "$TEST_TMP/bin/gh"
export PATH="$TEST_TMP/bin:$PATH"
export GH_LOG="$TEST_TMP/gh.log"
git patch publish-stacked

log=$(cat "$GH_LOG")
assert_contains "$log" "stack"
assert_contains "$log" "cache"
assert_contains "$log" "logging"
assert_contains "$log" "feature"
