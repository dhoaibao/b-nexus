# Copy to runtimes/<name>/scripts/install.sh and replace placeholders.
# Sourced by install.sh — do not run directly.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "error: this script is sourced by install.sh" >&2
  exit 1
fi

runtime_warn_missing_cli() {
  command -v runtime-cli-placeholder >/dev/null 2>&1 || warn "runtime-cli-placeholder not found; files will still be installed for runtime-placeholder to discover later."
}

runtime_install_configs() {
  :
}

runtime_write_manifest() {
  die "replace runtimes/runtime-template/scripts/install.sh with a real runtime driver before use"
}

runtime_print_install_report() {
  die "replace runtimes/runtime-template/scripts/install.sh with a real runtime driver before use"
}

runtime_uninstall_configs() {
  :
}

runtime_main() {
  die "replace runtimes/runtime-template/scripts/install.sh with a real runtime driver before use"
}

runtime_uninstall() {
  die "replace runtimes/runtime-template/scripts/install.sh with a real runtime driver before use"
}
