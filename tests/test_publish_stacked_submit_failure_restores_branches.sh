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

cache_before=$(git rev-parse cache)
logging_before=$(git rev-parse logging)
feature_before=$(git rev-parse feature)
git config --local --list >"$TEST_TMP/config.before"
tree_before=$(git rev-parse "HEAD^{tree}")

mkdir "$TEST_TMP/bin"
cp "$FIXTURES/$fixture/gh" "$TEST_TMP/bin/gh"
chmod +x "$TEST_TMP/bin/gh"
export PATH="$TEST_TMP/bin:$PATH"
export GH_LOG="$TEST_TMP/gh.log"
export GH_FAIL_SUBMIT=1

assert_fails git patch publish-stacked
assert_equals "$cache_before" "$(git rev-parse cache)"
assert_equals "$logging_before" "$(git rev-parse logging)"
assert_equals "$feature_before" "$(git rev-parse feature)"
assert_equals "$tree_before" "$(git rev-parse "HEAD^{tree}")"
assert_equals "feature" "$(git symbolic-ref --short HEAD)"
git config --local --list >"$TEST_TMP/config.after"
assert_file_equals "$TEST_TMP/config.before" "$TEST_TMP/config.after"
[ ! -e "$(git rev-parse --git-dir)/gh-stack" ] ||
  fail "lokal gh-stack-sporing ble ikke fjernet ved rollback"
[ ! -e "$(git rev-parse --git-dir)/gh-stack.lock" ] ||
  fail "lokal gh-stack-lås ble ikke fjernet ved rollback"
[ ! -e "$(git rev-parse --git-dir)/gh-stack-operation.lock" ] ||
  fail "lokal gh-stack-operasjonslås ble ikke fjernet ved rollback"
