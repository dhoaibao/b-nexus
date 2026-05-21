#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d /tmp/b-agentic-smoke.XXXXXX)"

cleanup() {
  rm -rf "$WORK_DIR"
}

trap cleanup EXIT

fail() {
  printf 'smoke-install.sh: %s\n' "$*" >&2
  exit 1
}

require_bin() {
  command -v "$1" >/dev/null 2>&1 || fail "required binary not found: $1"
}

assert_file() {
  local path="$1"
  [ -f "$path" ] || fail "expected file: $path"
}

assert_no_path() {
  local path="$1"
  [ ! -e "$path" ] || fail "unexpected path: $path"
}

assert_glob() {
  local pattern="$1"
  compgen -G "$pattern" >/dev/null || fail "expected match: $pattern"
}

assert_contains() {
  local path="$1" needle="$2"
  grep -Fq "$needle" "$path" || fail "expected '$needle' in $path"
}

assert_not_contains() {
  local path="$1" needle="$2"
  ! grep -Fq "$needle" "$path" || fail "did not expect '$needle' in $path"
}

assert_equal_files() {
  local left="$1" right="$2"
  cmp -s "$left" "$right" || fail "expected files to match: $left vs $right"
}

make_repo_snapshot() {
  local snapshot_dir="$1"
  mkdir -p "$snapshot_dir"
  cp -R "$ROOT_DIR"/. "$snapshot_dir"/
  rm -rf "$snapshot_dir/.git" "$snapshot_dir/.b-agentic" "$snapshot_dir/.serena"
  git -C "$snapshot_dir" init -q
  git -C "$snapshot_dir" add .
  git -C "$snapshot_dir" -c user.name='b-agentic smoke' -c user.email='smoke@example.com' commit -qm 'snapshot'
}

run_install_status() {
  local sandbox="$1" repo_snapshot="$2"
  shift 2

  local rc=0
  set +e
  HOME="$sandbox/home" \
  B_AGENTIC_REPO="$repo_snapshot" \
  B_AGENTIC_DIR="$sandbox/source" \
  B_AGENTIC_PROJECT_DIR="$sandbox/project" \
  bash "$ROOT_DIR/install.sh" "$@" >/dev/null 2>&1
  rc=$?
  set -e

  printf '%s' "$rc"
}

expect_install_status() {
  local expected="$1" sandbox="$2" repo_snapshot="$3"
  shift 3

  local rc
  rc="$(run_install_status "$sandbox" "$repo_snapshot" "$@")"
  [ "$rc" -eq "$expected" ] || fail "expected install exit $expected, got $rc"
}

main() {
  local snapshot_repo="$WORK_DIR/repo-snapshot"
  local sandbox_fresh="$WORK_DIR/fresh"
  local sandbox_preserve="$WORK_DIR/preserve"
  local sandbox_replace="$WORK_DIR/replace"
  local sandbox_dry_run="$WORK_DIR/dry-run"
  local sandbox_config="$WORK_DIR/config"
  local sandbox_uninstall="$WORK_DIR/uninstall"

  require_bin git
  require_bin python3

  make_repo_snapshot "$snapshot_repo"

  mkdir -p "$sandbox_fresh/home"
  expect_install_status 0 "$sandbox_fresh" "$snapshot_repo"
  assert_file "$sandbox_fresh/home/.claude/skills/b-plan/SKILL.md"
  assert_file "$sandbox_fresh/home/.claude/skills/b-browser/SKILL.md"
  assert_file "$sandbox_fresh/home/.claude/skills/b-review/reference.md"
  assert_file "$sandbox_fresh/home/.claude/skills/b-plan/references/b-agentic/runtime-contract.md"
  assert_file "$sandbox_fresh/home/.claude/skills/b-plan/references/b-agentic/performance-checklist.md"
  assert_file "$sandbox_fresh/home/.claude/CLAUDE.md"
  assert_file "$sandbox_fresh/home/.claude/b-agentic/CLAUDE.md"
  assert_file "$sandbox_fresh/home/.claude/b-agentic/references/runtime-contract.md"
  assert_file "$sandbox_fresh/home/.claude/b-agentic/templates/settings.recommended.json"
  assert_file "$sandbox_fresh/home/.claude/b-agentic/templates/mcp.project.template.json"
  assert_file "$sandbox_fresh/home/.claude/b-agentic/templates/mcp.safe.template.json"
  assert_file "$sandbox_fresh/home/.claude/b-agentic/templates/mcp.research.template.json"
  assert_file "$sandbox_fresh/home/.claude/b-agentic/templates/mcp.browser.template.json"
  assert_file "$sandbox_fresh/home/.claude/b-agentic/templates/mcp.architecture.template.json"
  assert_file "$sandbox_fresh/home/.claude/b-agentic/install.json"
  assert_no_path "$sandbox_fresh/home/.claude/commands"
  assert_no_path "$sandbox_fresh/home/.config/opencode"
  assert_equal_files "$sandbox_fresh/home/.claude/CLAUDE.md" "$sandbox_fresh/home/.claude/b-agentic/CLAUDE.md"
  assert_contains "$sandbox_fresh/home/.claude/b-agentic/install.json" '"runtime": "claude-code"'
  assert_contains "$sandbox_fresh/home/.claude/b-agentic/install.json" '"activationState": "active"'
  assert_contains "$sandbox_fresh/home/.claude/skills/b-implement/SKILL.md" 'disable-model-invocation: true'

  expect_install_status 0 "$sandbox_fresh" "$snapshot_repo"

  mkdir -p "$sandbox_preserve/home/.claude"
  printf '# User Claude Memory\n' > "$sandbox_preserve/home/.claude/CLAUDE.md"
  expect_install_status 2 "$sandbox_preserve" "$snapshot_repo"
  assert_contains "$sandbox_preserve/home/.claude/CLAUDE.md" '# User Claude Memory'
  assert_file "$sandbox_preserve/home/.claude/b-agentic/CLAUDE.md"
  assert_contains "$sandbox_preserve/home/.claude/b-agentic/install.json" '"activationState": "pending"'

  mkdir -p "$sandbox_replace/home/.claude"
  printf '# User Claude Memory\n' > "$sandbox_replace/home/.claude/CLAUDE.md"
  expect_install_status 0 "$sandbox_replace" "$snapshot_repo" --replace-memory
  assert_contains "$sandbox_replace/home/.claude/CLAUDE.md" '<!-- b-agentic-managed -->'
  assert_contains "$sandbox_replace/home/.claude/b-agentic/install.json" '"memoryAction": "replace"'
  assert_glob "$sandbox_replace/home/.claude/b-agentic/backups/CLAUDE.md.bak-*"

  mkdir -p "$sandbox_dry_run/home"
  expect_install_status 0 "$sandbox_dry_run" "$snapshot_repo" --dry-run
  assert_no_path "$sandbox_dry_run/home/.claude"
  assert_no_path "$sandbox_dry_run/source"

  mkdir -p "$sandbox_config/home"
  expect_install_status 0 "$sandbox_config" "$snapshot_repo" --install-settings --install-project-mcp
  assert_file "$sandbox_config/home/.claude/settings.json"
  assert_file "$sandbox_config/project/.mcp.json"
  assert_contains "$sandbox_config/project/.mcp.json" '"playwright"'
  assert_not_contains "$sandbox_config/project/.mcp.json" '"gitnexus"'
  assert_contains "$sandbox_config/home/.claude/b-agentic/install.json" '"settingsAction": "install"'
  assert_contains "$sandbox_config/home/.claude/b-agentic/install.json" '"mcpAction": "install"'
  assert_contains "$sandbox_config/home/.claude/b-agentic/install.json" '"mcpProfile": "project"'
  expect_install_status 0 "$sandbox_config" "$snapshot_repo" --uninstall
  assert_no_path "$sandbox_config/home/.claude/settings.json"
  assert_no_path "$sandbox_config/project/.mcp.json"

  local sandbox_profile="$WORK_DIR/profile"
  mkdir -p "$sandbox_profile/home"
  expect_install_status 0 "$sandbox_profile" "$snapshot_repo" --install-project-mcp --mcp-profile safe
  assert_file "$sandbox_profile/project/.mcp.json"
  assert_contains "$sandbox_profile/project/.mcp.json" '"serena"'
  assert_not_contains "$sandbox_profile/project/.mcp.json" '"brave-search"'
  assert_contains "$sandbox_profile/home/.claude/b-agentic/install.json" '"mcpProfile": "safe"'
  expect_install_status 0 "$sandbox_profile" "$snapshot_repo" --uninstall
  assert_no_path "$sandbox_profile/project/.mcp.json"

  local sandbox_bad_profile="$WORK_DIR/bad-profile"
  mkdir -p "$sandbox_bad_profile/home"
  expect_install_status 1 "$sandbox_bad_profile" "$snapshot_repo" --install-project-mcp --mcp-profile unknown

  local sandbox_profile_dry_run="$WORK_DIR/profile-dry-run"
  mkdir -p "$sandbox_profile_dry_run/home"
  expect_install_status 0 "$sandbox_profile_dry_run" "$snapshot_repo" --dry-run --install-project-mcp --mcp-profile research
  assert_no_path "$sandbox_profile_dry_run/home/.claude"
  assert_no_path "$sandbox_profile_dry_run/project/.mcp.json"
  assert_no_path "$sandbox_profile_dry_run/source"

  mkdir -p "$sandbox_uninstall/home"
  expect_install_status 0 "$sandbox_uninstall" "$snapshot_repo"
  expect_install_status 0 "$sandbox_uninstall" "$snapshot_repo" --uninstall
  assert_no_path "$sandbox_uninstall/home/.claude/skills/b-plan"
  assert_no_path "$sandbox_uninstall/home/.claude/CLAUDE.md"
  assert_no_path "$sandbox_uninstall/home/.claude/b-agentic"

  printf 'smoke-install.sh passed\n'
}

main "$@"
