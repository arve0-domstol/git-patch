#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
fixture=list
init_repo "$fixture"

for patch in first second third; do
  git switch -q -c "$patch" main
  printf '%s\n' "$patch" >"$patch.txt"
  git add "$patch.txt"
  git commit -qm "$patch"
done

create_feature_branch "$fixture"
git patch add first
git patch add second
git patch add third

for patch in first second third; do
  git switch -q "$patch"
  git reset --hard -q main
  printf '%s updated\n' "$patch" >app.txt
  git commit -qam "$patch updated"
done
git switch -q feature

output=$(git patch list)
first_output=$(printf '%s\n' "$output" |
  sed -n '/^1\. first$/,/^2\./p')
second_output=$(printf '%s\n' "$output" |
  sed -n '/^2\. second$/,/^3\./p')
third_output=$(printf '%s\n' "$output" |
  sed -n '/^3\. third$/,/^   stack conflicts:/p')
third_conflicts=$(printf '%s\n' "$third_output" |
  sed -n 's/^   conflicts: //p')

assert_contains "$first_output" "conflicts: none"
assert_contains "$second_output" "conflicts: app.txt"
assert_equals "unknown" "$third_conflicts"
