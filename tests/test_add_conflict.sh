#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=add-conflict
init_repo "$fixture"
create_cache_branch "$fixture"
git switch -q -C feature main
cp "$FIXTURES/$fixture/feature.txt" app.txt
git add app.txt && git commit -qm 'feature conflict'
before=$(git rev-parse HEAD)

output=$(git patch add cache 2>&1 || true)
assert_contains "$output" "app.txt"
assert_contains "$output" "Ingen endringer ble gjort"
assert_equals "$before" "$(git rev-parse HEAD)"
