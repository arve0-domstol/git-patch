#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=check-conflicts-after-add
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"
git patch add cache
cp "$FIXTURES/$fixture/feature-conflict.txt" app.txt
git commit -qam 'feature reworks cached line'

git switch -q cache
cp "$FIXTURES/$fixture/cache-conflicting.txt" app.txt
git commit -qam 'conflicting cache update'
git switch -q feature
before=$(git rev-parse HEAD)

output=$(git patch check-conflicts cache 2>&1 || true)
assert_contains "$output" "app.txt"
assert_equals "$before" "$(git rev-parse HEAD)"
