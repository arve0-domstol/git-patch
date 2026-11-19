#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=add-snapshot
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"

git patch add cache

git grep -q 'cache change' HEAD
git grep -q 'feature work' HEAD
git merge-base --is-ancestor main HEAD
