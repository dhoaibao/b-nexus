#!/usr/bin/env bash
# install.sh - Bootstrap or update b-agentic for Claude Code
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash -s -- --dry-run
#   curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash -s -- --replace-memory
#   curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash -s -- --install-settings
#   curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash -s -- --install-project-mcp
#   curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash -s -- --install-project-mcp --mcp-profile safe
#   curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash -s -- --uninstall

set -euo pipefail

readonly REPO_URL="${B_AGENTIC_REPO:-https://github.com/dhoaibao/b-agentic.git}"
readonly LOCAL_REPO="${B_AGENTIC_DIR:-$HOME/.b-agentic}"
readonly REF="${B_AGENTIC_REF:-}"
readonly CLAUDE_DIR="${B_AGENTIC_CLAUDE_DIR:-$HOME/.claude}"
readonly METADATA_DIR="$CLAUDE_DIR/b-agentic"
readonly BACKUPS_DIR="$METADATA_DIR/backups"
readonly SKILLS_DST="$CLAUDE_DIR/skills"
readonly KERNEL_DST="$CLAUDE_DIR/CLAUDE.md"
readonly KERNEL_SNAPSHOT_DST="$METADATA_DIR/CLAUDE.md"
readonly REFERENCES_DST="$METADATA_DIR/references"
readonly TEMPLATES_DST="$METADATA_DIR/templates"
readonly MANIFEST_DST="$METADATA_DIR/install.json"
readonly PROJECT_DIR="${B_AGENTIC_PROJECT_DIR:-$PWD}"
readonly SETTINGS_DST="$CLAUDE_DIR/settings.json"
readonly PROJECT_MCP_DST="$PROJECT_DIR/.mcp.json"
readonly TIMESTAMP="$(date +%Y%m%d%H%M%S)"

DRY_RUN_VALUE="${B_AGENTIC_DRY_RUN:-N}"
REPLACE_MEMORY_VALUE="${B_AGENTIC_REPLACE_MEMORY:-}"
UNINSTALL_VALUE="${B_AGENTIC_UNINSTALL:-N}"
INSTALL_SETTINGS_VALUE="${B_AGENTIC_INSTALL_SETTINGS:-N}"
REPLACE_SETTINGS_VALUE="${B_AGENTIC_REPLACE_SETTINGS:-N}"
INSTALL_PROJECT_MCP_VALUE="${B_AGENTIC_INSTALL_PROJECT_MCP:-N}"
REPLACE_PROJECT_MCP_VALUE="${B_AGENTIC_REPLACE_PROJECT_MCP:-N}"
MCP_PROFILE_VALUE="${B_AGENTIC_MCP_PROFILE:-project}"

SOURCE_DIR="$LOCAL_REPO"
SKILLS_SRC="$SOURCE_DIR/skills"
REFERENCES_SRC="$SOURCE_DIR/references"
TEMPLATES_SRC="$SOURCE_DIR/claude"
KERNEL_SRC="$SOURCE_DIR/global/CLAUDE.md"
DRY_RUN_SOURCE_DIR=""

log() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [ -n "$DRY_RUN_SOURCE_DIR" ]; then
    rm -rf "$DRY_RUN_SOURCE_DIR"
  fi
}

trap cleanup EXIT

yes_value() {
  case "${1:-}" in
    y|Y|yes|YES|Yes|true|TRUE|1) return 0 ;;
    *) return 1 ;;
  esac
}

dry_run_enabled() {
  yes_value "$DRY_RUN_VALUE"
}

replace_memory_enabled() {
  yes_value "$REPLACE_MEMORY_VALUE"
}

uninstall_enabled() {
  yes_value "$UNINSTALL_VALUE"
}

run_cmd() {
  if dry_run_enabled; then
    printf '[dry-run] %s\n' "$*" >&2
    return 0
  fi
  "$@"
}

ensure_dir() {
  local dir_path="$1"
  run_cmd mkdir -p "$dir_path"
}

copy_file() {
  local src="$1" dst="$2"
  ensure_dir "$(dirname "$dst")"
  run_cmd cp "$src" "$dst"
}

copy_dir_replace() {
  local src="$1" dst="$2"
  ensure_dir "$(dirname "$dst")"
  if dry_run_enabled; then
    printf '[dry-run] rm -rf %s\n' "$dst" >&2
    printf '[dry-run] cp -R %s %s\n' "$src" "$dst" >&2
    return 0
  fi
  rm -rf "$dst"
  cp -R "$src" "$dst"
}

backup_file() {
  local path="$1"
  [ -f "$path" ] || return 0
  ensure_dir "$BACKUPS_DIR"
  local backup="$BACKUPS_DIR/$(basename "$path").bak-$TIMESTAMP"
  copy_file "$path" "$backup"
  printf '%s' "$backup"
}

require_bin() {
  command -v "$1" >/dev/null 2>&1 || die "required binary not found: $1"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN_VALUE=Y
        ;;
      --replace-memory)
        REPLACE_MEMORY_VALUE=Y
        ;;
      --preserve-memory)
        REPLACE_MEMORY_VALUE=N
        ;;
      --uninstall)
        UNINSTALL_VALUE=Y
        ;;
      --install-settings)
        INSTALL_SETTINGS_VALUE=Y
        ;;
      --replace-settings)
        INSTALL_SETTINGS_VALUE=Y
        REPLACE_SETTINGS_VALUE=Y
        ;;
      --install-project-mcp)
        INSTALL_PROJECT_MCP_VALUE=Y
        ;;
      --replace-project-mcp)
        INSTALL_PROJECT_MCP_VALUE=Y
        REPLACE_PROJECT_MCP_VALUE=Y
        ;;
      --mcp-profile)
        shift
        [ "$#" -gt 0 ] || die "--mcp-profile requires one of: safe, research, browser, architecture, project"
        MCP_PROFILE_VALUE="$1"
        ;;
      --mcp-profile=*)
        MCP_PROFILE_VALUE="${1#--mcp-profile=}"
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
    shift
  done
}

set_source_dir() {
  SOURCE_DIR="$1"
  SKILLS_SRC="$SOURCE_DIR/skills"
  REFERENCES_SRC="$SOURCE_DIR/references"
  TEMPLATES_SRC="$SOURCE_DIR/claude"
  KERNEL_SRC="$SOURCE_DIR/global/CLAUDE.md"
}

sync_source() {
  require_bin git
  require_bin python3

  if dry_run_enabled; then
    if [ -d "$LOCAL_REPO/.git" ] || [ -d "$LOCAL_REPO/skills" ]; then
      log "Dry-run source: $LOCAL_REPO (no fetch/pull)"
      set_source_dir "$LOCAL_REPO"
    else
      DRY_RUN_SOURCE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/b-agentic-dry-run.XXXXXX")"
      log "Dry-run source clone: $REPO_URL -> $DRY_RUN_SOURCE_DIR"
      git clone "$REPO_URL" "$DRY_RUN_SOURCE_DIR"
      if [ -n "$REF" ]; then
        git -C "$DRY_RUN_SOURCE_DIR" checkout "$REF"
      fi
      set_source_dir "$DRY_RUN_SOURCE_DIR"
    fi
  elif [ -d "$LOCAL_REPO/.git" ]; then
    log "Updating source: $LOCAL_REPO"
    git -C "$LOCAL_REPO" fetch --all --tags --prune
    if [ -n "$REF" ]; then
      git -C "$LOCAL_REPO" checkout "$REF"
    else
      git -C "$LOCAL_REPO" pull --ff-only
    fi
    set_source_dir "$LOCAL_REPO"
  else
    log "Cloning source: $REPO_URL -> $LOCAL_REPO"
    mkdir -p "$(dirname "$LOCAL_REPO")"
    git clone "$REPO_URL" "$LOCAL_REPO"
    if [ -n "$REF" ]; then
      git -C "$LOCAL_REPO" checkout "$REF"
    fi
    set_source_dir "$LOCAL_REPO"
  fi

  [ -d "$SKILLS_SRC" ] || die "missing source directory: $SKILLS_SRC"
  [ -d "$REFERENCES_SRC" ] || die "missing source directory: $REFERENCES_SRC"
  [ -d "$TEMPLATES_SRC" ] || die "missing source directory: $TEMPLATES_SRC"
  [ -f "$KERNEL_SRC" ] || die "missing kernel source: $KERNEL_SRC"
}

skill_names() {
  python3 - "$SKILLS_SRC" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
for path in sorted(root.glob('*/SKILL.md')):
    print(path.parent.name)
PY
}

sync_references_into_skill() {
  local skill_dir="$1"
  local support_dir="$skill_dir/references/b-agentic"
  ensure_dir "$support_dir"
  if dry_run_enabled; then
    printf '[dry-run] cp %s/*.md %s/\n' "$REFERENCES_SRC" "$support_dir" >&2
    return 0
  fi
  cp "$REFERENCES_SRC"/*.md "$support_dir"/
}

install_skills() {
  ensure_dir "$SKILLS_DST"
  local name
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    copy_dir_replace "$SKILLS_SRC/$name" "$SKILLS_DST/$name"
    sync_references_into_skill "$SKILLS_DST/$name"
  done < <(skill_names)
}

install_references_and_templates() {
  copy_dir_replace "$REFERENCES_SRC" "$REFERENCES_DST"
  copy_dir_replace "$TEMPLATES_SRC" "$TEMPLATES_DST"
}

install_kernel() {
  ensure_dir "$METADATA_DIR"
  copy_file "$KERNEL_SRC" "$KERNEL_SNAPSHOT_DST"

  if [ ! -e "$KERNEL_DST" ]; then
    copy_file "$KERNEL_SRC" "$KERNEL_DST"
    printf 'replace\nactive\nnone'
    return 0
  fi

  if grep -Fq '<!-- b-agentic-managed -->' "$KERNEL_DST"; then
    local backup
    backup="$(backup_file "$KERNEL_DST")"
    copy_file "$KERNEL_SRC" "$KERNEL_DST"
    printf 'replace\nactive\n%s' "${backup:-none}"
    return 0
  fi

  if replace_memory_enabled; then
    local backup
    backup="$(backup_file "$KERNEL_DST")"
    copy_file "$KERNEL_SRC" "$KERNEL_DST"
    printf 'replace\nactive\n%s' "${backup:-none}"
    return 0
  fi

  printf 'preserve\npending\nnone'
}

install_optional_config() {
  local install_value="$1" replace_value="$2" src="$3" dst="$4"

  if ! yes_value "$install_value"; then
    printf 'skip\nnone\nnone'
    return 0
  fi

  if [ ! -e "$dst" ]; then
    copy_file "$src" "$dst"
    printf 'install\nactive\nnone'
    return 0
  fi

  if yes_value "$replace_value"; then
    local backup
    backup="$(backup_file "$dst")"
    copy_file "$src" "$dst"
    printf 'replace\nactive\n%s' "${backup:-none}"
    return 0
  fi

  printf 'preserve\npending\nnone'
}

mcp_profile_template() {
  case "$MCP_PROFILE_VALUE" in
    safe|research|browser|architecture|project)
      printf '%s/mcp.%s.template.json' "$TEMPLATES_SRC" "$MCP_PROFILE_VALUE"
      ;;
    *)
      die "unknown MCP profile: $MCP_PROFILE_VALUE (expected safe, research, browser, architecture, or project)"
      ;;
  esac
}

write_manifest() {
  local memory_action="$1" activation_state="$2" memory_backup="$3" settings_action="$4" settings_state="$5" settings_backup="$6" mcp_action="$7" mcp_state="$8" mcp_backup="$9" mcp_profile="${10}"
  shift 10
  local skills=("$@")

  if dry_run_enabled; then
    printf '[dry-run] write manifest %s\n' "$MANIFEST_DST" >&2
    return 0
  fi

  ensure_dir "$METADATA_DIR"
  env \
    MANIFEST_DST="$MANIFEST_DST" \
    TIMESTAMP="$TIMESTAMP" \
    MEMORY_ACTION="$memory_action" \
    ACTIVATION_STATE="$activation_state" \
    MEMORY_BACKUP="$memory_backup" \
    SETTINGS_ACTION="$settings_action" \
    SETTINGS_STATE="$settings_state" \
    SETTINGS_BACKUP="$settings_backup" \
    MCP_ACTION="$mcp_action" \
    MCP_STATE="$mcp_state" \
    MCP_BACKUP="$mcp_backup" \
    MCP_PROFILE="$mcp_profile" \
    CLAUDE_DIR="$CLAUDE_DIR" \
    SKILLS_DST="$SKILLS_DST" \
    REFERENCES_DST="$REFERENCES_DST" \
    TEMPLATES_DST="$TEMPLATES_DST" \
    KERNEL_DST="$KERNEL_DST" \
    SETTINGS_DST="$SETTINGS_DST" \
    PROJECT_MCP_DST="$PROJECT_MCP_DST" \
    SKILLS="${skills[*]}" \
    python3 - <<'PY'
import json
import os
from pathlib import Path

skills = [name for name in os.environ['SKILLS'].split() if name]
manifest = {
    'suite': 'b-agentic',
    'runtime': 'claude-code',
    'installedAt': os.environ['TIMESTAMP'],
    'activationState': os.environ['ACTIVATION_STATE'],
    'memoryAction': os.environ['MEMORY_ACTION'],
    'settingsAction': os.environ['SETTINGS_ACTION'],
    'settingsState': os.environ['SETTINGS_STATE'],
    'mcpAction': os.environ['MCP_ACTION'],
    'mcpState': os.environ['MCP_STATE'],
    'mcpProfile': os.environ['MCP_PROFILE'],
    'paths': {
        'claudeDir': os.environ['CLAUDE_DIR'],
        'kernel': os.environ['KERNEL_DST'],
        'skills': os.environ['SKILLS_DST'],
        'references': os.environ['REFERENCES_DST'],
        'templates': os.environ['TEMPLATES_DST'],
        'settings': os.environ['SETTINGS_DST'],
        'projectMcp': os.environ['PROJECT_MCP_DST'],
    },
    'skills': skills,
    'backups': {
        'claudeMd': os.environ['MEMORY_BACKUP'],
        'settings': os.environ['SETTINGS_BACKUP'],
        'projectMcp': os.environ['MCP_BACKUP'],
    },
}
Path(os.environ['MANIFEST_DST']).write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
PY
}

remove_managed_kernel() {
  if [ -f "$KERNEL_DST" ] && grep -Fq '<!-- b-agentic-managed -->' "$KERNEL_DST"; then
    if [ -f "$KERNEL_SNAPSHOT_DST" ] && cmp -s "$KERNEL_DST" "$KERNEL_SNAPSHOT_DST"; then
      run_cmd rm -f "$KERNEL_DST"
    else
      warn "preserving modified managed CLAUDE.md: $KERNEL_DST"
    fi
  fi
}

manifest_path_value() {
  local key="$1" fallback="$2"
  if [ ! -f "$MANIFEST_DST" ]; then
    printf '%s' "$fallback"
    return 0
  fi
  python3 - "$MANIFEST_DST" "$key" "$fallback" <<'PY'
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
key = sys.argv[2]
fallback = sys.argv[3]
try:
    data = json.loads(path.read_text())
    print(data.get('paths', {}).get(key, fallback))
except Exception:
    print(fallback)
PY
}

remove_managed_config() {
  local path="$1" template="$2" label="$3"
  [ -f "$path" ] || return 0
  if [ -f "$template" ] && cmp -s "$path" "$template"; then
    run_cmd rm -f "$path"
  else
    warn "preserving modified $label: $path"
  fi
}

remove_managed_mcp_config() {
  local path="$1"
  [ -f "$path" ] || return 0
  local template
  for template in "$TEMPLATES_DST"/mcp.*.template.json; do
    [ -f "$template" ] || continue
    if cmp -s "$path" "$template"; then
      run_cmd rm -f "$path"
      return 0
    fi
  done
  warn "preserving modified .mcp.json: $path"
}

uninstall() {
  log "Uninstalling b-agentic from Claude Code personal config"
  local name
  if [ -f "$MANIFEST_DST" ]; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      run_cmd rm -rf "$SKILLS_DST/$name"
    done < <(python3 - "$MANIFEST_DST" <<'PY'
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
except Exception:
    data = {}
for name in data.get('skills', []):
    print(name)
PY
)
  else
    for name in b-orchestrate b-spec b-plan b-research b-implement b-refactor b-debug b-test b-browser b-review b-audit; do
      run_cmd rm -rf "$SKILLS_DST/$name"
    done
  fi

  remove_managed_kernel
  local settings_path project_mcp_path
  settings_path="$(manifest_path_value settings "$SETTINGS_DST")"
  project_mcp_path="$(manifest_path_value projectMcp "$PROJECT_MCP_DST")"
  remove_managed_config "$settings_path" "$TEMPLATES_DST/settings.recommended.json" "settings.json"
  remove_managed_mcp_config "$project_mcp_path"
  run_cmd rm -rf "$METADATA_DIR"
  log "Uninstall complete. User-owned Claude Code files were preserved."
}

main() {
  parse_args "$@"

  if uninstall_enabled; then
    require_bin python3
    uninstall
    return 0
  fi

  sync_source
  command -v claude >/dev/null 2>&1 || warn "claude CLI not found; files will still be installed for Claude Code to discover later."

  local skill
  local installed_skills=()
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    installed_skills+=("$skill")
  done < <(skill_names)
  install_skills

  install_references_and_templates

  local kernel_result memory_action activation_state memory_backup
  local -a kernel_lines
  kernel_result="$(install_kernel)"
  readarray -t kernel_lines <<< "$kernel_result"
  memory_action="${kernel_lines[0]:-preserve}"
  activation_state="${kernel_lines[1]:-pending}"
  memory_backup="${kernel_lines[2]:-none}"

  local settings_result settings_action settings_state settings_backup
  local -a settings_lines
  settings_result="$(install_optional_config "$INSTALL_SETTINGS_VALUE" "$REPLACE_SETTINGS_VALUE" "$TEMPLATES_SRC/settings.recommended.json" "$SETTINGS_DST")"
  readarray -t settings_lines <<< "$settings_result"
  settings_action="${settings_lines[0]:-skip}"
  settings_state="${settings_lines[1]:-none}"
  settings_backup="${settings_lines[2]:-none}"

  local mcp_result mcp_action mcp_state mcp_backup mcp_template
  local -a mcp_lines
  mcp_template="$(mcp_profile_template)"
  [ -f "$mcp_template" ] || die "missing MCP profile template: $mcp_template"
  mcp_result="$(install_optional_config "$INSTALL_PROJECT_MCP_VALUE" "$REPLACE_PROJECT_MCP_VALUE" "$mcp_template" "$PROJECT_MCP_DST")"
  readarray -t mcp_lines <<< "$mcp_result"
  mcp_action="${mcp_lines[0]:-skip}"
  mcp_state="${mcp_lines[1]:-none}"
  mcp_backup="${mcp_lines[2]:-none}"

  write_manifest "$memory_action" "$activation_state" "$memory_backup" "$settings_action" "$settings_state" "$settings_backup" "$mcp_action" "$mcp_state" "$mcp_backup" "$MCP_PROFILE_VALUE" "${installed_skills[@]}"

  log "b-agentic Claude Code install complete"
  log "activationState: $activation_state"
  if [ "$activation_state" = "pending" ]; then
    log "Existing $KERNEL_DST was preserved. Review $KERNEL_SNAPSHOT_DST and rerun with --replace-memory to activate the kernel."
    return 2
  fi
}

main "$@"
