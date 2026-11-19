#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=drop-conflict
init_repo "$fixture"
create_cache_branch "$fixture"
git switch -q -C feature main
cp "$FIXTURES/$fixture/feature.txt" feature.txt
git add feature.txt && git commit -qm 'feature work'
git patch add cache
cp "$FIXTURES/$fixture/cache-without-dependency.txt" app.txt
git commit -qam 'feature reworks cache content'
before=$(git rev-parse HEAD)

output=$(git patch drop cache 2>&1 || true)
assert_contains "$output" "conflict"
assert_equals "$before" "$(git rev-parse HEAD)"
