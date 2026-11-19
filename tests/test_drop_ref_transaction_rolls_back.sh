#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=drop-patch
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"
git patch add cache

printf 'uncommitted work\n' >uncommitted.txt
before_head=$(git rev-parse HEAD)
before_list=$(git patch list)
before_log=$(git patch log)
before_status=$(git status --porcelain --untracked-files=all)
before_stashes=$(git stash list)
before_feature=$(git show HEAD:feature.txt)

stack_id=$(printf 'feature' | git hash-object --stdin)
head_ref="refs/git-patch/stacks/$stack_id/head"
head_ref_file=$(git rev-parse --git-path "$head_ref")
touch "$head_ref_file.lock"

if git patch drop cache >/dev/null 2>&1; then
  fail "drop should fail when its ref transaction is locked"
fi
rm -f "$head_ref_file.lock"

assert_equals "$before_head" "$(git rev-parse HEAD)" "HEAD changed after failed drop"
assert_equals "$before_list" "$(git patch list)" "active metadata changed after failed drop"
assert_equals "$before_log" "$(git patch log)" "operation log changed after failed drop"
assert_equals "$before_feature" "$(git show HEAD:feature.txt)" \
  "feature commit changed after failed drop"
assert_equals "$before_status" "$(git status --porcelain --untracked-files=all)" \
  "worktree changed after failed drop"
assert_equals "$before_stashes" "$(git stash list)" \
  "stash state changed after failed drop"
