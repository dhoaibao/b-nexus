# Copy to runtimes/<name>/scripts/install.sh and replace placeholders.
# Sourced by install.sh — do not run directly.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  echo "error: this script is sourced by install.sh" >&2
  exit 1
fi

runtime_warn_missing_cli() {
  command -v runtime-cli-placeholder >/dev/null 2>&1 || warn "runtime-cli-placeholder not found; files will still be installed for runtime-placeholder to discover later."
}

runtime_install_config_stage_count() {
  printf '0'
}

runtime_install_configs() {
  :
}

runtime_write_manifest() {
  die "replace runtimes/runtime-template/scripts/install.sh with a real runtime driver before use"
}

runtime_print_install_report() {
  # Replace this with the shared report shape used by supported runtimes:
  #   print_install_report_header "Runtime Name"
  #   report_section "Summary"
  #   report_item "activation" "$INSTALL_ACTIVATION_STATE"
  #   ...
  #   report_section "Backups"
  #   ...
  #   print_install_report_readiness
  #   print_shell_tool_recommendations
  #   print_install_report_next_steps "Runtime Name"
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
