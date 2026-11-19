#!/usr/bin/env bash

set -euo pipefail

output=$(git-patch --help)
[[ "$output" == *"git patch <command>"* ]]
[[ "$output" == *"add <patch>"* ]]
[[ "$output" == *"publish-stacked"* ]]
