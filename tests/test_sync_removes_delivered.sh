#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=sync-delivered
init_repo "$fixture"
create_cache_branch "$fixture"
cache_commit=$(git rev-parse cache)
create_feature_branch "$fixture"
git patch add cache

git switch -q cache
cp "$FIXTURES/$fixture/cache-followup.txt" app.txt
git commit -qam 'follow-up cache change'
followup_commit=$(git rev-parse cache)
git switch -q main
git cherry-pick "$cache_commit" >/dev/null
git push -q origin main
git switch -q feature
git patch sync

stack_id=$(printf '%s' feature | git hash-object --stdin)
patch_id=$(printf '%s' cache | git hash-object --stdin)
patch_prefix="git-patch.$stack_id.patch.$patch_id"
assert_equals "$patch_id" \
  "$(git config --local --get "git-patch.$stack_id.patches.value")"
assert_equals "$followup_commit" \
  "$(git config --local --get "$patch_prefix.source-tip")"
assert_file_equals "$FIXTURES/$fixture/cache-followup.txt" app.txt
git grep -q 'feature work' HEAD

git switch -q main
git cherry-pick "$followup_commit" >/dev/null
git push -q origin main
git switch -q feature
git patch sync

if git config --local --get \
  "git-patch.$stack_id.patches.value" >/dev/null 2>&1; then
  fail "delivered cache remained in stack metadata"
fi
if git show-ref --verify --quiet \
  "refs/git-patch/stacks/$stack_id/patch/$patch_id/source"; then
  fail "delivered cache source ref remained"
fi
git grep -q 'cache change' HEAD
git grep -q 'follow-up cache change' HEAD
git grep -q 'feature work' HEAD
assert_contains "$(git patch log)" "dropped cache because its change was found in main"
