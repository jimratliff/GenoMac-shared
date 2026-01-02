# Prevent multiple sourcing
if [[ -n "${__already_loaded_genomac_bootstrap_helpers_sh:-}" ]]; then return 0; fi
__already_loaded_genomac_bootstrap_helpers_sh=1
export __already_loaded_genomac_bootstrap_helpers_sh

# Resolve this script's directory (even if sourced)
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

safe_source() {
  # Ensures that an error is raised if a `source` of the file in the supplied argument fails.
  # Usage:
  #  safe_source "${PREFS_FUNCTIONS_DIR}/set_safari_settings.sh"
  local file="$1"
  if ! source "$file"; then
    echo "ERROR: Failed to source $file"
    exit 1
  fi
}

# Source common environment variables
# Assumes that assign_common_environment_variables.sh resides in same directory as this file
safe_source "${this_script_dir}/assign_common_environment_variables.sh"

# Source each subsidiary helper file, all assumed to reside in same directory as this file
safe_source "${this_script_dir}/helpers-apps.sh"
safe_source "${this_script_dir}/helpers-copying.sh"
safe_source "${this_script_dir}/helpers-defaults.sh"
safe_source "${this_script_dir}/helpers-interactive.sh""
safe_source "${this_script_dir}/helpers-misc.sh"
safe_source "${this_script_dir}/helpers-reporting.sh"
safe_source "${this_script_dir}/helpers-state.sh

function main() {
  define_colors_and_symbols
}

main

