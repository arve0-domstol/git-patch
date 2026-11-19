#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=log
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"
git patch add cache

output=$(git patch log)
assert_contains "$output" "added cache from "
git patch sync cache
output=$(git patch log)
assert_contains "$output" "synced cache from "
