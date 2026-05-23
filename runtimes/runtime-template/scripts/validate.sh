#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

printf 'replace runtimes/runtime-template/scripts/validate.sh with adapter-specific checks before registering a new runtime\n' >&2
exit 1
