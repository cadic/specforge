#!/usr/bin/env bats

setup() {
  TESTDIR="$(mktemp -d)"
  cd "$TESTDIR"
  git init -q
  LIB="$BATS_TEST_DIRNAME/../skills/specforge/scripts/_lib.sh"
}

teardown() {
  rm -rf "$TESTDIR"
}

@test "sf_repo_root returns git toplevel" {
  run bash -c "source '$LIB'; sf_repo_root"
  [ "$status" -eq 0 ]
  [ "$output" = "$(cd "$TESTDIR" && pwd -P)" ]
}

@test "sf_task_root defaults to docs/specforge" {
  run bash -c "source '$LIB'; sf_task_root"
  [ "$status" -eq 0 ]
  [ "$output" = "docs/specforge" ]
}

@test "sf_task_root honors .specforge.json override" {
  printf '{ "task_root": "coding-assistant/tasks" }\n' > .specforge.json
  run bash -c "source '$LIB'; sf_task_root"
  [ "$status" -eq 0 ]
  [ "$output" = "coding-assistant/tasks" ]
}

@test "sf_resolve_task_dir joins root, task-root, slug" {
  run bash -c "source '$LIB'; sf_resolve_task_dir my-task"
  [ "$status" -eq 0 ]
  [ "$output" = "$(cd "$TESTDIR" && pwd -P)/docs/specforge/my-task" ]
}

@test "sf_has_placeholders detects angle placeholders" {
  printf 'name: <...>\n' > f.md
  run bash -c "source '$LIB'; sf_has_placeholders f.md"
  [ "$status" -eq 0 ]
}

@test "sf_has_placeholders passes a clean file" {
  printf 'name: real value\n' > f.md
  run bash -c "source '$LIB'; sf_has_placeholders f.md"
  [ "$status" -ne 0 ]
}
