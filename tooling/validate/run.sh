#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

runtime_names() {
  python3 - <<'PY'
from pathlib import Path
import json

registry = json.loads(Path('runtimes/registry.yaml').read_text())
for runtime in registry.get('runtimes', []):
    name = runtime.get('name')
    if isinstance(name, str) and name:
        print(name)
PY
}

python3 "$ROOT_DIR/tooling/validate/shared.py"

exit_code=0
while IFS= read -r runtime_name; do
  [ -n "$runtime_name" ] || continue
  runtime_script="$ROOT_DIR/runtimes/$runtime_name/scripts/validate.sh"
  if [ ! -f "$runtime_script" ]; then
    printf 'runtimes/%s/scripts/validate.sh: missing registered runtime validator\n' "$runtime_name" >&2
    exit_code=1
    continue
  fi
  if ! bash "$runtime_script"; then
    exit_code=1
  fi
done < <(runtime_names)

exit "$exit_code"
