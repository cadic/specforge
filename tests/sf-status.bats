#!/usr/bin/env bats

setup() {
  TESTDIR="$(mktemp -d)"
  cd "$TESTDIR"
  git init -q
  STATUS="$BATS_TEST_DIRNAME/../skills/specforge/scripts/sf-status.sh"
  DIR="docs/specforge/t"
  mkdir -p "$DIR"
}

teardown() {
  rm -rf "$TESTDIR"
}

@test "setup when no 01 exists" {
  run bash "$STATUS" t
  [ "$output" = "setup" ]
}

@test "explore when 01 present and no 03" {
  printf 'x\n' > "$DIR/01-problem-statement.md"
  run bash "$STATUS" t
  [ "$output" = "explore" ]
}

@test "spec when 03 present and no 04" {
  printf 'x\n' > "$DIR/01-problem-statement.md"
  printf 'x\n' > "$DIR/02-solution-options.md"
  printf 'x\n' > "$DIR/03-solution-hld.md"
  run bash "$STATUS" t
  [ "$output" = "spec" ]
}

@test "spec when 04 still holds template placeholders" {
  printf 'x\n' > "$DIR/01-problem-statement.md"
  printf 'x\n' > "$DIR/03-solution-hld.md"
  printf 'Project: <...>\n' > "$DIR/04-execution-spec.md"
  run bash "$STATUS" t
  [ "$output" = "spec" ]
}

@test "execute when 04 is filled and placeholder-free" {
  printf 'x\n' > "$DIR/01-problem-statement.md"
  printf 'x\n' > "$DIR/03-solution-hld.md"
  printf 'Project: Widget API\n' > "$DIR/04-execution-spec.md"
  run bash "$STATUS" t
  [ "$output" = "execute" ]
}

@test "errors without a slug" {
  run bash "$STATUS"
  [ "$status" -eq 2 ]
}
