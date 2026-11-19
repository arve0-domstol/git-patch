#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FIXTURES="$ROOT/tests/fixtures"
TEST_TMP=${TEST_TMP:-$(mktemp -d)}
REPO="$TEST_TMP/repo"
REMOTE="$TEST_TMP/origin.git"

cleanup() {
  rm -rf "$TEST_TMP"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_equals() {
  local expected=$1 actual=$2 message=${3:-"values differ"}
  [[ "$actual" == "$expected" ]] || fail "$message (expected '$expected', got '$actual')"
}

assert_contains() {
  local haystack=$1 needle=$2 message=${3:-"missing expected text"}
  [[ "$haystack" == *"$needle"* ]] || fail "$message: '$needle'"
}

assert_not_contains() {
  local haystack=$1 needle=$2 message=${3:-"unexpected text"}
  [[ "$haystack" != *"$needle"* ]] || fail "$message: '$needle'"
}

assert_file_equals() {
  local expected=$1 actual=$2
  diff -u "$expected" "$actual" >/dev/null || fail "$actual did not match $expected"
}

assert_succeeds() {
  "$@" >/dev/null 2>&1 || fail "command should succeed: $*"
}

assert_fails() {
  "$@" >/dev/null 2>&1 && fail "command should fail: $*"
}

init_repo() {
  local fixture=$1
  git init --bare -q "$REMOTE"
  git init -q -b main "$REPO"
  cd "$REPO"
  git config user.name "Test User"
  git config user.email test@example.invalid
  cp "$FIXTURES/$fixture/base.txt" app.txt
  git add app.txt
  git commit -qm 'initial'
  git remote add origin "$REMOTE"
  git push -q -u origin main
  git fetch -q origin
  git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
}

create_branch_commit() {
  local branch=$1 fixture_file=$2 message=$3
  git switch -q -C "$branch" main
  cp "$FIXTURES/$(basename "$fixture_file")" "$fixture_file"
  git add -A
  git commit -qm "$message"
}

create_cache_branch() {
  local fixture=$1
  git switch -q -c cache main
  cp "$FIXTURES/$fixture/cache.txt" app.txt
  git add app.txt
  git commit -qm 'cache'
  git switch -q main
}
create_feature_branch() {
  local fixture=$1
  git switch -q -c feature main
  cp "$FIXTURES/$fixture/feature.txt" feature.txt
  git add feature.txt
  git commit -qm 'feature'
}

tip_before() {
  git rev-parse "$1"
}
