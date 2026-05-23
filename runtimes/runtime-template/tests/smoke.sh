# Copy to runtimes/<name>/tests/smoke.sh and replace placeholders.
# Sourced by tests/smoke/install.sh — do not run directly.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "error: this script is sourced by tests/smoke/install.sh" >&2
  exit 1
fi

run_runtime_smoke_cases() {
  fail "replace runtimes/runtime-template/tests/smoke.sh with adapter-specific smoke coverage before registering a new runtime"
}
