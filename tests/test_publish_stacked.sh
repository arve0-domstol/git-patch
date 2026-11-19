#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=publish-stacked
init_repo "$fixture"
create_cache_branch "$fixture"
git switch -q -c logging main
cp "$FIXTURES/$fixture/logging.txt" logging.txt
git add logging.txt && git commit -qm 'logging'
create_feature_branch "$fixture"
git patch add cache
git patch add logging

mkdir "$TEST_TMP/bin"
cp "$FIXTURES/$fixture/gh" "$TEST_TMP/bin/gh"
chmod +x "$TEST_TMP/bin/gh"
export PATH="$TEST_TMP/bin:$PATH"
export GH_LOG="$TEST_TMP/gh.log"
git patch publish-stacked

log=$(cat "$GH_LOG")
assert_contains "$log" "stack"
assert_contains "$log" "cache"
assert_contains "$log" "logging"
assert_contains "$log" "feature"

assert_equals "$(git rev-parse main)" "$(git rev-parse cache^)"
assert_equals "$(git rev-parse cache)" "$(git rev-parse logging^)"
assert_equals "$(git rev-parse logging)" "$(git rev-parse feature^)"

assert_equals "app.txt" "$(git diff --name-only main...cache)"
assert_equals "logging.txt" "$(git diff --name-only cache...logging)"
assert_equals "feature.txt" "$(git diff --name-only logging...feature)"
assert_file_equals "$FIXTURES/$fixture/cache.txt" \
  <(git show cache:app.txt)
assert_file_equals "$FIXTURES/$fixture/feature.txt" \
  <(git show feature:feature.txt)
assert_equals "   source: cache (current)" \
  "$(git patch list | sed -n '/1\. cache/{n;p;}')"
assert_equals "   source: logging (current)" \
  "$(git patch list | sed -n '/2\. logging/{n;p;}')"

git switch -q logging
printf 'logging follow-up\n' >>logging.txt
git add logging.txt && git commit -qm 'logging follow-up'
git switch -q feature
git patch sync logging
assert_equals "logging.txt" "$(git diff --name-only cache...logging)"
assert_not_contains "$(git diff --name-only cache...logging)" "app.txt"
assert_equals "feature.txt" "$(git diff --name-only logging...feature)"
