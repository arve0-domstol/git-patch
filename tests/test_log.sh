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
assert_not_contains "$output" "rolled back sync after conflicts"
synced_tip=$(git rev-parse cache)

cat >app.txt <<'EOF'
base
feature changed cache
EOF
git commit -qam 'feature changes cache'

git switch -q cache
cat >app.txt <<'EOF'
base
cache changed again
EOF
git commit -qam 'conflicting cache update'
git switch -q feature

printf 'pending work\n' >pending.txt
before_head=$(git rev-parse HEAD)
before_list=$(git patch list)
before_status=$(git status --porcelain --untracked-files=all)
before_stashes=$(git stash list)

output=$(git patch sync cache 2>&1 || true)
assert_contains "$output" "conflict"
assert_equals "$before_head" "$(git rev-parse HEAD)" \
  "HEAD changed after failed sync"
assert_equals "$before_list" "$(git patch list)" \
  "stack metadata changed after failed sync"
assert_equals "$before_status" "$(git status --porcelain --untracked-files=all)" \
  "worktree changed after failed sync"
assert_equals "$before_stashes" "$(git stash list)" \
  "stash state changed after failed sync"

output=$(git patch log)
assert_equals \
  "added cache from $synced_tip
synced cache from $synced_tip
rolled back sync after conflicts" \
  "$output" \
  "operations should be shown in recorded order"
