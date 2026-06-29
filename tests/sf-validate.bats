#!/usr/bin/env bats

setup() {
  TESTDIR="$(mktemp -d)"
  cd "$TESTDIR"
  VALIDATE="$BATS_TEST_DIRNAME/../skills/specforge/scripts/sf-validate.sh"
}

teardown() {
  rm -rf "$TESTDIR"
}

@test "passes a fully filled document" {
  printf '# Spec\n\nProject: Widget API\n\n- invariant one\n\n| Term | Definition |\n| ---- | ---------- |\n| node | a unit |\n' > clean.md
  run bash "$VALIDATE" clean.md
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK"* ]]
}

@test "flags angle placeholders" {
  printf 'Project: <...>\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"angle-placeholder"* ]]
}

@test "flags TBD" {
  printf 'Version: TBD\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"TBD"* ]]
}

@test "flags the forbidden glyph" {
  printf 'Status: ❌\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"forbidden-glyph"* ]]
}

@test "flags empty table cells" {
  printf '| a |  | c |\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"empty-table-cell"* ]]
}

@test "flags empty list items" {
  printf 'List:\n- \n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"empty-list-item"* ]]
}

@test "does not flag a filled checkbox list" {
  printf -- '- [ ] do a thing\n- [x] done thing\n' > f.md
  run bash "$VALIDATE" f.md
  [ "$status" -eq 0 ]
}

@test "errors on a missing file" {
  run bash "$VALIDATE" nope.md
  [ "$status" -eq 2 ]
}
