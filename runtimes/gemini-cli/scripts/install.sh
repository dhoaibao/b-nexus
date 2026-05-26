# Sourced by install.sh - do not run directly.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "error: this script is sourced by install.sh" >&2
  exit 1
fi

readonly RUNTIME_UNINSTALL_LABEL="Gemini CLI personal config"
readonly RUNTIME_PRESERVE_LABEL="Gemini CLI"
readonly GEMINI_DIR="${B_AGENTIC_GEMINI_DIR:-$HOME/.gemini}"
readonly METADATA_DIR="$GEMINI_DIR/b-agentic"
readonly BACKUPS_DIR="$METADATA_DIR/backups"
readonly SKILLS_DST="${B_AGENTIC_SKILLS_DST:-$HOME/.gemini/skills}"
readonly COMMANDS_SRC="$SOURCE_DIR/runtimes/$RUNTIME/commands"
readonly COMMANDS_DST="${B_AGENTIC_GEMINI_COMMANDS_DIR:-$HOME/.gemini/commands}"
readonly COMMANDS_SNAPSHOT_DST="$METADATA_DIR/commands"
readonly KERNEL_DST="$GEMINI_DIR/GEMINI.md"
readonly KERNEL_SNAPSHOT_DST="$METADATA_DIR/GEMINI.md"
readonly REFERENCES_DST="$METADATA_DIR/references"
readonly TEMPLATES_DST="$METADATA_DIR/templates"
readonly MANIFEST_DST="$METADATA_DIR/install.json"
readonly GEMINI_SETTINGS_DST="${B_AGENTIC_GEMINI_SETTINGS:-$HOME/.gemini/settings.json}"
readonly MCP_CONFIG_DST="$GEMINI_SETTINGS_DST"
readonly MCP_TEMPLATE_SRC="$TEMPLATES_SRC/settings.template.json"
readonly MCP_ROOT_KEY="mcpServers"
readonly MCP_PLACEHOLDER_STYLE="gemini"
readonly MCP_CONTEXT7_SECTION="headers"
readonly MCP_BRAVE_SECTION="env"
readonly MCP_FIRECRAWL_SECTION="env"
readonly MCP_BACKUP_KEY="geminiSettings"

CONTEXT7_API_KEY_INPUT=""
BRAVE_API_KEY_INPUT=""
FIRECRAWL_API_KEY_INPUT=""

runtime_warn_missing_cli() {
  command -v gemini >/dev/null 2>&1 || warn "gemini CLI not found; files will still be installed for Gemini CLI to discover later."
}

runtime_install_config_stage_count() {
  printf '1'
}

command_names() {
  python3 - "$COMMANDS_SRC" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
for path in sorted(root.glob('*.toml')):
    print(path.stem)
PY
}

install_commands() {
  local -n installed_ref="$1"
  ensure_dir "$COMMANDS_DST"
  installed_ref=()

  local name src dst previous_snapshot next_snapshot
  next_snapshot="$(mktemp -d "${TMPDIR:-/tmp}/b-agentic-gemini-commands.XXXXXX")"
  while IFS= read -r name; do
    [ -n "$name" ] || continue

    src="$COMMANDS_SRC/$name.toml"
    dst="$COMMANDS_DST/$name.toml"
    previous_snapshot="$COMMANDS_SNAPSHOT_DST/$name.toml"

    if [ -f "$dst" ]; then
      if [ -f "$previous_snapshot" ] && cmp -s "$dst" "$previous_snapshot"; then
        copy_file "$src" "$dst"
        copy_file "$src" "$next_snapshot/$name.toml"
        installed_ref+=("$name")
        continue
      fi

      if cmp -s "$dst" "$src"; then
        if [ -f "$previous_snapshot" ]; then
          copy_file "$src" "$next_snapshot/$name.toml"
          installed_ref+=("$name")
        else
          warn "preserving existing Gemini command: $dst"
        fi
        continue
      fi

      warn "preserving modified Gemini command wrapper: $dst"
      continue
    fi

    copy_file "$src" "$dst"
    copy_file "$src" "$next_snapshot/$name.toml"
    installed_ref+=("$name")
  done < <(command_names)

  copy_dir_replace "$next_snapshot" "$COMMANDS_SNAPSHOT_DST"
  rm -rf "$next_snapshot"
}

runtime_install_extra_assets() {
  [ -d "$COMMANDS_SRC" ] || die "missing command source directory: $COMMANDS_SRC"
  install_commands INSTALL_COMMAND_NAMES
}

runtime_install_configs() {
  run_install_triplet_stage "Merging Gemini settings" install_mcp_config "skip" "none" "none" \
    INSTALL_MCP_ACTION INSTALL_MCP_STATE INSTALL_MCP_BACKUP
}

runtime_write_manifest() {
  local skills_string="${INSTALL_SKILL_NAMES[*]}"
  local commands_string="${INSTALL_COMMAND_NAMES[*]}"

  if dry_run_enabled; then
    printf '[dry-run] write manifest %s\n' "$MANIFEST_DST" >&2
    return 0
  fi

  ensure_dir "$METADATA_DIR"
  env \
    MANIFEST_DST="$MANIFEST_DST" \
    TIMESTAMP="$TIMESTAMP" \
    RUNTIME="$RUNTIME" \
    MEMORY_ACTION="$INSTALL_MEMORY_ACTION" \
    ACTIVATION_STATE="$INSTALL_ACTIVATION_STATE" \
    MEMORY_BACKUP="$INSTALL_MEMORY_BACKUP" \
    MCP_ACTION="$INSTALL_MCP_ACTION" \
    MCP_STATE="$INSTALL_MCP_STATE" \
    MCP_BACKUP="$INSTALL_MCP_BACKUP" \
    GEMINI_DIR="$GEMINI_DIR" \
    GEMINI_SETTINGS_DST="$GEMINI_SETTINGS_DST" \
    SKILLS_DST="$SKILLS_DST" \
    COMMANDS_DST="$COMMANDS_DST" \
    REFERENCES_DST="$REFERENCES_DST" \
    TEMPLATES_DST="$TEMPLATES_DST" \
    KERNEL_DST="$KERNEL_DST" \
    SKILLS="$skills_string" \
    COMMANDS="$commands_string" \
    python3 - <<'PY'
import json
import os
from pathlib import Path

skills = [name for name in os.environ['SKILLS'].split() if name]
commands = [name for name in os.environ['COMMANDS'].split() if name]
manifest = {
    'suite': 'b-agentic',
    'runtime': os.environ['RUNTIME'],
    'installedAt': os.environ['TIMESTAMP'],
    'activationState': os.environ['ACTIVATION_STATE'],
    'memoryAction': os.environ['MEMORY_ACTION'],
    'mcpAction': os.environ['MCP_ACTION'],
    'mcpState': os.environ['MCP_STATE'],
    'paths': {
        'geminiDir': os.environ['GEMINI_DIR'],
        'geminiSettings': os.environ['GEMINI_SETTINGS_DST'],
        'kernel': os.environ['KERNEL_DST'],
        'skills': os.environ['SKILLS_DST'],
        'commands': os.environ['COMMANDS_DST'],
        'references': os.environ['REFERENCES_DST'],
        'templates': os.environ['TEMPLATES_DST'],
    },
    'skills': skills,
    'commands': commands,
    'backups': {
        'geminiMd': os.environ['MEMORY_BACKUP'],
        'geminiSettings': os.environ['MCP_BACKUP'],
    },
}
Path(os.environ['MANIFEST_DST']).write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
PY
}

runtime_print_install_report() {
  print_install_report_header "Gemini CLI"
  report_section "Summary"
  report_item "activation" "$INSTALL_ACTIVATION_STATE"
  report_item "skills" "${#INSTALL_SKILL_NAMES[@]} synced -> $SKILLS_DST"
  report_item "commands" "${#INSTALL_COMMAND_NAMES[@]} synced -> $COMMANDS_DST"
  report_item "kernel" "$INSTALL_MEMORY_ACTION -> $KERNEL_DST"
  report_item "settings" "$INSTALL_MCP_ACTION -> $GEMINI_SETTINGS_DST"
  report_item "references" "sync -> $REFERENCES_DST"
  report_item "templates" "sync -> $TEMPLATES_DST"
  report_item "manifest" "write -> $MANIFEST_DST"
  report_section "Backups"
  report_item "kernel" "$INSTALL_MEMORY_BACKUP"
  report_item "settings" "$INSTALL_MCP_BACKUP"
  print_install_report_readiness
  print_shell_tool_recommendations
  print_install_report_next_steps "Gemini CLI"
}

manifest_command_names() {
  if manifest_array_values commands; then
    return 0
  fi
  command_names
}

runtime_uninstall_extra_assets() {
  local name commands_path command_snapshot
  commands_path="$(manifest_path_value commands "$COMMANDS_DST")"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    command_snapshot="$COMMANDS_SNAPSHOT_DST/$name.toml"
    if [ ! -f "$commands_path/$name.toml" ]; then
      continue
    fi
    if [ ! -f "$command_snapshot" ]; then
      warn "preserving Gemini command with no managed snapshot: $commands_path/$name.toml"
      continue
    fi
    if cmp -s "$commands_path/$name.toml" "$command_snapshot"; then
      run_cmd rm -f "$commands_path/$name.toml"
    else
      warn "preserving modified Gemini command wrapper: $commands_path/$name.toml"
    fi
  done < <(manifest_command_names)
}

runtime_uninstall_configs() {
  local settings_path
  settings_path="$(manifest_path_value geminiSettings "$GEMINI_SETTINGS_DST")"
  remove_merged_config "$settings_path" "$TEMPLATES_DST/settings.template.json" "gemini-settings.json" "geminiSettings" "mcpAction"
}

runtime_main() {
  runtime_install_common
}

runtime_uninstall() {
  runtime_uninstall_common
}
