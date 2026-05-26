#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path
import json
import sys

root = Path('.')
errors = []


def command_exposed_skill_names():
    registry_path = root / 'skills' / 'registry.yaml'
    try:
        registry = json.loads(registry_path.read_text())
    except Exception as exc:
        errors.append(f'{registry_path}: invalid JSON-compatible YAML registry: {exc}')
        return set()

    names = set()
    for skill in registry.get('skills', []):
        if not isinstance(skill, dict):
            errors.append('skills/registry.yaml: skill entries must be objects')
            continue
        command = skill.get('command', {})
        if not isinstance(command, dict):
            errors.append(f"skills/registry.yaml: missing command object for {skill.get('name')!r}")
            continue
        if command.get('exposed') is True:
            alias = command.get('alias')
            if not isinstance(alias, str) or not alias:
                errors.append(f"skills/registry.yaml: invalid command alias for {skill.get('name')!r}")
                continue
            names.add(alias)
    return names


skill_names = command_exposed_skill_names()

kernel_path = root / 'runtimes' / 'gemini-cli' / 'kernel.md'
kernel = kernel_path.read_text() if kernel_path.exists() else ''
gemini_readme = (root / 'runtimes' / 'gemini-cli' / 'configs' / 'README.md').read_text() if (root / 'runtimes' / 'gemini-cli' / 'configs' / 'README.md').exists() else ''
contract_index = (root / 'references' / 'contract' / 'index.md').read_text() if (root / 'references' / 'contract' / 'index.md').exists() else ''
maintainer = (root / 'CLAUDE.md').read_text() if (root / 'CLAUDE.md').exists() else ''
gemini_install = (root / 'runtimes' / 'gemini-cli' / 'scripts' / 'install.sh').read_text() if (root / 'runtimes' / 'gemini-cli' / 'scripts' / 'install.sh').exists() else ''
commands_dir = root / 'runtimes' / 'gemini-cli' / 'commands'
runtime_registry_path = root / 'runtimes' / 'registry.yaml'
settings_template_path = root / 'runtimes' / 'gemini-cli' / 'configs' / 'settings.template.json'

try:
    runtime_registry = json.loads(runtime_registry_path.read_text())
except Exception as exc:
    runtime_registry = {}
    errors.append(f'{runtime_registry_path}: invalid JSON-compatible YAML registry: {exc}')

gemini_runtime = None
for runtime in runtime_registry.get('runtimes', []):
    if isinstance(runtime, dict) and runtime.get('name') == 'gemini-cli':
        gemini_runtime = runtime
        break

if not kernel_path.exists():
    errors.append('runtimes/gemini-cli/kernel.md: missing')
if '<!-- b-agentic-managed -->' not in kernel:
    errors.append('runtimes/gemini-cli/kernel.md: missing b-agentic managed marker')
for marker in ['Reference checklist:', 'Runtime gate checklist:', 'GEMINI.md', 'Gemini CLI', 'runtime contract §9']:
    if marker not in kernel:
        errors.append(f'runtimes/gemini-cli/kernel.md: missing kernel marker {marker!r}')

if 'Gemini CLI' not in maintainer:
    errors.append('CLAUDE.md: must mention Gemini CLI as a supported runtime')

if not isinstance(gemini_runtime, dict):
    errors.append('runtimes/registry.yaml: missing gemini-cli runtime entry')
else:
    if gemini_runtime.get('memory_install_path') != '~/.gemini/GEMINI.md':
        errors.append('runtimes/registry.yaml: gemini-cli memory_install_path must be ~/.gemini/GEMINI.md')
    if gemini_runtime.get('skills_install_root') != '~/.gemini/skills':
        errors.append('runtimes/registry.yaml: gemini-cli skills_install_root must be ~/.gemini/skills')
    command_wrappers = gemini_runtime.get('command_wrappers')
    if not isinstance(command_wrappers, dict) or command_wrappers.get('supported') is not True:
        errors.append('runtimes/registry.yaml: gemini-cli must declare supported command wrappers')
    elif command_wrappers.get('source_dir') != 'runtimes/gemini-cli/commands':
        errors.append('runtimes/registry.yaml: gemini-cli command wrapper source_dir must be runtimes/gemini-cli/commands')

for required in [
    '~/.gemini/b-agentic',
    '/tmp/gemini-cli/b-agentic',
]:
    if required not in contract_index:
        errors.append(f'references/contract/index.md: missing Gemini marker {required!r}')

for required in [
    'GEMINI_DIR',
    'GEMINI_SETTINGS_DST',
    'COMMANDS_DST',
    'install_mcp_config',
    'runtime_main',
    'report_item "commands"',
]:
    if required not in gemini_install:
        errors.append(f'runtimes/gemini-cli/scripts/install.sh: missing Gemini installer marker {required!r}')

if not commands_dir.exists():
    errors.append('runtimes/gemini-cli/commands: missing Gemini command wrapper source directory')
else:
    command_names = {path.stem for path in commands_dir.glob('*.toml')}
    missing_commands = sorted(skill_names - command_names)
    extra_commands = sorted(command_names - skill_names)
    if missing_commands or extra_commands:
        errors.append(
            'runtimes/gemini-cli/commands: command wrappers must match exposed skill aliases '
            f'(missing: {missing_commands}, extra: {extra_commands})'
        )
    for path in commands_dir.glob('*.toml'):
        text = path.read_text()
        if 'prompt =' not in text or '{{args}}' not in text:
            errors.append(f'{path}: Gemini command wrapper must define prompt with {{args}} forwarding')

if not settings_template_path.exists():
    errors.append('runtimes/gemini-cli/configs/settings.template.json: missing settings template')
else:
    try:
        template = json.loads(settings_template_path.read_text())
    except Exception as exc:
        errors.append(f'runtimes/gemini-cli/configs/settings.template.json: invalid JSON: {exc}')
        template = {}
    servers = template.get('mcpServers', {})
    expected = {'serena', 'context7', 'brave-search', 'firecrawl', 'playwright', 'gitnexus'}
    if set(servers) != expected:
        errors.append(f'runtimes/gemini-cli/configs/settings.template.json: expected default MCP servers {sorted(expected)}, found {sorted(servers)}')
    if servers.get('context7', {}).get('httpUrl') != 'https://mcp.context7.com/mcp':
        errors.append('runtimes/gemini-cli/configs/settings.template.json: context7 must use the official MCP endpoint')
    if servers.get('playwright', {}).get('args', [])[-1:] != ['--isolated']:
        errors.append('runtimes/gemini-cli/configs/settings.template.json: playwright must use --isolated by default')

if 'Gemini CLI Runtime Layout' not in gemini_readme:
    errors.append('runtimes/gemini-cli/configs/README.md: missing title')
for needle in ['~/.gemini/settings.json', '~/.gemini/commands/', '~/.gemini/skills/', 'settings.template.json', 'runtime-neutral', 'TOML']:
    if needle not in gemini_readme:
        errors.append(f'runtimes/gemini-cli/configs/README.md: missing Gemini documentation marker {needle!r}')

if errors:
    for error in errors:
        print(error, file=sys.stderr)
    sys.exit(1)

print('Gemini CLI runtime validation passed.')
PY
