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

# Source each subsidiary helper file, all assumed to reside in same directory as this file
safe_source "${this_script_dir}/helpers-apps.sh"
safe_source "${this_script_dir}/helpers-copying.sh"
safe_source "${this_script_dir}/helpers-defaults.sh"
safe_source "${this_script_dir}/helpers-interactive.sh"
safe_source "${this_script_dir}/helpers-reporting.sh"
safe_source "${this_script_dir}/helpers-state.sh"

############### HELPERS

function keep_sudo_alive() {
  report_action_taken "I very likely am about to ask you for your administrator password. Do you trust me??? 😉"

  # Update user’s cached credentials for `sudo`.
  sudo -v

  # Keep-alive: update existing `sudo` time stamp until this shell exits
  while true; do 
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &  # background process, silence errors
}

function sanitize_filename() {
  echo "$1" | tr -cd '[:alnum:]._-'
}

is_semantic_version_arg1_at_least_arg2() {
  # is_semantic_version_arg1_at_least_arg2 ARG1 ARG2
  #
  # Returns 0 (success) iff (normalized ARG1) >= (normalized ARG2)
  # according to semantic version ordering.
  #
  # Normalization rules:
  #   - Strips a leading "v" if present
  #   - Removes everything from the first "-" or "+" onward
  #     e.g., "1.3-", "1.3-1", and "1.3+5" would each reduce to "1.3"
  #
  # Examples:
  #   is_semantic_version_arg1_at_least_arg2 "1"   "1.5"  → returns 1 (false)
  #   is_semantic_version_arg1_at_least_arg2 "1.5" "1.0"  → returns 0 (true)
  #   is_semantic_version_arg1_at_least_arg2 "2.2" "2.2"  → returns 0 (true)

  local arg1="$1"
  local arg2="$2"

  arg1="${arg1#v}"
  arg2="${arg2#v}"

  arg1="${arg1%%[-+]*}"
  arg2="${arg2%%[-+]*}"

  is-at-least "$arg2" "$arg1"
}

function main() {
  define_colors_and_symbols
}

main

