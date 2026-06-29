#!/usr/bin/env bats

setup() {
  TESTDIR="$(mktemp -d)"
  cd "$TESTDIR"
  git init -q
  INIT="$BATS_TEST_DIRNAME/../skills/specforge/scripts/sf-init.sh"
}

teardown() {
  rm -rf "$TESTDIR"
}

@test "sf-init scaffolds task dir and 01 template" {
  run bash "$INIT" my-task
  [ "$status" -eq 0 ]
  [ -f "docs/specforge/my-task/01-problem-statement.md" ]
  grep -q "Problem Statement" "docs/specforge/my-task/01-problem-statement.md"
}

@test "sf-init prints the task dir" {
  run bash "$INIT" my-task
  [ "$output" = "$(cd "$TESTDIR" && pwd -P)/docs/specforge/my-task" ]
}

@test "sf-init refuses to overwrite an existing 01" {
  bash "$INIT" my-task
  run bash "$INIT" my-task
  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing to overwrite"* ]]
}

@test "sf-init honors .specforge.json task root" {
  printf '{ "task_root": "tasks" }\n' > .specforge.json
  run bash "$INIT" my-task
  [ "$status" -eq 0 ]
  [ -f "tasks/my-task/01-problem-statement.md" ]
}

@test "sf-init errors without a slug" {
  run bash "$INIT"
  [ "$status" -ne 0 ]
}
