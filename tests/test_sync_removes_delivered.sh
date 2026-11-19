#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=sync-delivered
init_repo "$fixture"
create_cache_branch "$fixture"
cache_commit=$(git rev-parse cache)
create_feature_branch "$fixture"
git patch add cache

git switch -q main
git cherry-pick -q "$cache_commit"
git push -q origin main
git switch -q feature
git patch sync

git patch list | grep -q cache && fail "delivered cache remained in stack"
git grep -q 'cache change' HEAD
git grep -q 'feature work' HEAD
assert_contains "$(git patch log)" "dropped cache because its change was found in main"
