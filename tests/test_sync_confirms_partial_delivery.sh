#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=sync-partial-delivery
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"
git patch add cache

git switch -q main
cp "$FIXTURES/$fixture/main-partial.txt" app.txt
git commit -qam 'part of cache landed differently'
git push -q origin main
git switch -q feature
before=$(git rev-parse HEAD)

output=$(printf 'n\n' | git patch sync 2>&1 || true)
assert_contains "$output" "bekref"
assert_equals "$before" "$(git rev-parse HEAD)"
