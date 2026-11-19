#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=sync-all-main
init_repo "$fixture"
create_cache_branch "$fixture"
create_feature_branch "$fixture"
git patch add cache

git switch -q main
cp "$FIXTURES/$fixture/main-new.txt" main.txt
git add main.txt && git commit -qm 'new main'
git push -q origin main
git switch -q feature
git patch sync

git merge-base --is-ancestor origin/main HEAD
git grep -q 'main update' HEAD
git grep -q 'cache change' HEAD
git grep -q 'feature work' HEAD
