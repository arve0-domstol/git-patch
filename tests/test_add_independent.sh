#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=add-independent
init_repo "$fixture"

git switch -q -c cache main
cp "$FIXTURES/$fixture/cache.txt" cache.txt
git add cache.txt && git commit -qm 'cache'
git switch -q -c dependent cache
cp "$FIXTURES/$fixture/dependent.txt" dependent.txt
git add dependent.txt && git commit -qm 'dependent'
git switch -q -C feature main
git patch add cache
before=$(git rev-parse HEAD)

output=$(git patch add dependent 2>&1 || true)
assert_contains "$output" "avhenger"
assert_equals "$before" "$(git rev-parse HEAD)"
