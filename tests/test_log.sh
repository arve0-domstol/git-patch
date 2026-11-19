#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=log
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"

assert_equals "Ingen stack-historikk ennå." "$(git patch log)" \
  "empty stack should have no history"

git patch add cache

output=$(git patch log)
assert_contains "$output" "added cache from "
git patch sync cache
output=$(git patch log)
assert_contains "$output" "synced cache from "

stack_id=$(printf 'feature' | git hash-object --stdin)
git config --local --add "git-patch.$stack_id.operations.value" \
  "rolled back sync after conflicts"
git config --local --add "git-patch.$stack_id.operations.value" \
  "dropped cache"

output=$(git patch log)
assert_contains "$output" "rolled back sync after conflicts"
assert_contains "$output" "dropped cache"
assert_equals \
  "added cache from $(git rev-parse cache)
synced cache from $(git rev-parse cache)
rolled back sync after conflicts
dropped cache" \
  "$output" \
  "operations should be shown in recorded order"
