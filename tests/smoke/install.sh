#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="$(mktemp -d /tmp/b-agentic-smoke.XXXXXX)"

cleanup() {
  rm -rf "$WORK_DIR"
}

trap cleanup EXIT

source "$ROOT_DIR/tests/smoke/lib.sh"

main() {
  local snapshot_repo="$WORK_DIR/repo-snapshot"
  local runtime_name runtime_script

  require_bin git
  require_bin python3
  make_repo_snapshot "$snapshot_repo"

  while IFS= read -r runtime_name; do
    [ -n "$runtime_name" ] || continue
    runtime_script="$ROOT_DIR/runtimes/$runtime_name/tests/smoke.sh"
    [ -f "$runtime_script" ] || fail "missing smoke suite: $runtime_script"

    unset -f run_runtime_smoke_cases runtime_smoke_name 2>/dev/null || true
    # shellcheck disable=SC1090
    source "$runtime_script"
    declare -F run_runtime_smoke_cases >/dev/null || fail "runtime smoke suite did not define run_runtime_smoke_cases: $runtime_script"
    run_runtime_smoke_cases "$snapshot_repo"
  done < <(registered_runtime_names)

  printf 'smoke-install.sh passed\n'
}

main "$@"
