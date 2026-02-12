#!/usr/bin/env bats
# Tests for lib/helpers.sh

setup() {
  load test_helper/common
  setup_test_env
}

teardown() {
  teardown_test_env
}

@test "waki_sql_escape escapes single quotes" {
  result=$(waki_sql_escape "it's a test")
  assert_equal "$result" "it''s a test"
}

@test "waki_sql_escape handles multiple single quotes" {
  result=$(waki_sql_escape "it''s Bob's")
  assert_equal "$result" "it''''s Bob''s"
}

@test "waki_sql_escape passes through clean strings unchanged" {
  result=$(waki_sql_escape "hello world")
  assert_equal "$result" "hello world"
}

@test "waki_sql_escape handles empty string" {
  result=$(waki_sql_escape "")
  assert_equal "$result" ""
}

@test "waki_require_tool succeeds for bash" {
  run waki_require_tool bash
  assert_success
}

@test "waki_require_tool fails for nonexistent tool" {
  run waki_require_tool nonexistent_tool_xyz
  assert_failure
  assert_output --partial "nonexistent_tool_xyz"
}

@test "waki_green outputs the message" {
  run waki_green "success"
  assert_success
  assert_output --partial "success"
}

@test "waki_yellow outputs the message" {
  run waki_yellow "warning"
  assert_success
  assert_output --partial "warning"
}

@test "waki_red outputs the message" {
  run waki_red "error"
  assert_success
  assert_output --partial "error"
}
