#!/usr/bin/env zsh

############### Helpers: Miscellaneous

# Relies upon:
#   helpers-reporting.sh

function export_and_report() {
  local var_name="$1"
  report_action_taken "Export $var_name: '${(P)var_name}'"
  export "$var_name"
}

function keep_sudo_alive() {
  report_action_taken "I very likely am about to ask you for your administrator password. I hope you trust me! 😉"

  # Update user’s cached credentials for `sudo`.
  sudo -v

  # Keep-alive: update existing `sudo` time stamp until this shell exits
  while true; do 
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &  # background process, silence errors
}

safe_source() {
  # Ensures that an error is raised if a `source` of the file in the supplied argument fails.
  # Usage:
  #  safe_source "${GMU_PREFS_SCRIPTS}/set_safari_settings.sh"
  local file="$1"
  if ! source "$file"; then
    report_fail "ERROR: Failed to source ${file}"
    exit 1
  fi
  report_success "Sourced ${file}"
}

function this_mac_is_a_laptop() {
  # Exits with zero if Mac is a laptop (has a battery installed); otherwise exits with 1
  #
  # Usage:
  #   if this_mac_is_a_laptop; then
  #   	echo "This is a laptop"
  #   else
  #   	echo "This is a desktop"
  #   fi
  #
  report_start_phase_standard
  
  /usr/sbin/ioreg -c AppleSmartBattery -r | awk '/BatteryInstalled/ {exit ($3 == "Yes" ? 0 : 1)}'

  report_end_phase_standard
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

function interactive_ensure_terminal_has_fda() {
  # Run at the beginning of a terminal session to try to ensure that the currently running terminal
  # app has Full Disk Access (FDA) permission.
  #
  # If the terminal app does *not* have FDA, the Settings » Privacy & Security » Full Disk Access
  # panel is opened (this terminal app should already be pre-populated, but un-enabled, on the 
  # list of apps), so the user can simply flip the switch for this app.
  #
  # The reason this terminal app will be pre-populated on the FDA list: The current script tests
  # whether the current terminal app has FDA by attempting to query a restricted location.
  # If the app doesn’t have FDA, this query is sufficient for macOS to add this app to that list.
  # NOTE: This is *not* conditioned on a PERM state variable, because there are multiple possible
  #       terminal apps. Each would need to tracked separately, requiring the script to interrogate
  #       what terminal app was running for that shell session. Too complicated!

  report_start_phase_standard

  report_action_taken "Testing whether currently running terminal application has FUll Disk Access."
  # Query a restricted location (a) to test FDA and (b) if not, add terminal app to list
  if ! ls ~/Library/Mail &>/dev/null; then
    # The currently running terminal app does *not* have FDA
    # macOS will add the terminal app to the list, but un-enabled
    report_warning "The currently running terminal app needs, but doesn’t have, Full Disk Access."

    # Tests whether this is an interactive session
    if [[ -t 0 ]]; then
    
      # The session is interactive
      report_action_taken "I will open (a) the Full Disk Access panel in System Settings and (b) a Quick Look window with instructions"
      open_privacy_panel_for_full_disk_permissions
      launch_app_and_prompt_user_to_act \
        --no-app \
        --show-doc "${GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY}/full_disk_access_how_to_configure.md" \
        "Follow the instructions in the Quick Look window to grant the current terminal app Full Disk Access"

      report "Configuring user confirms they have given FDA to the running terminal application" ; success_or_not
      report_end_phase_standard
      return 0
        
    else
      # The session is not interactive
      report_warning "Warning: Terminal lacks FDA and no interactive session to fix it"
      report_end_phase_standard
      return 1
    fi
  fi
  report_success "This terminal application already had Full Disk Access. No additional action required."
  report_end_phase_standard
}

function set_env_var_if_not_set() {
  # TODO: This is likely DEPRECATED because it is no longer used.
  #
  # Sets an environment variable to a default value if it’s not already defined.
  #
  # $1: the name of the environment variable
  # $2: the default value to set if the variable is not already defined
  #
  # Usage:
  #   set_env_var_if_not_set "GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT" "https://github.com/jimratliff"

  local var_name="$1"
  local default_value="$2"

  # NOTES regarding the below:
  # - The ${!var_name} is bash indirect expansion. It treats the value of var_name as the name of another variable and returns that variable’s value.
  # - The :- handles the set -u case, preventing an error if the variable is unset.

  if [[ -z "${!var_name:-}" ]]; then
    export "$var_name"="$default_value"
  fi
}
