#!/usr/bin/env zs

############### Helpers: Miscellaneous

# Relies upon:
#   helpers-reporting.sh

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

function show_file_using_quicklook() {
  # Shows a file using Quick Look, where that file is supplied by a path string in the only argument
  #
  # Usage:
  #   show_file_using_quicklook "${GENOMAC_USER_LOCAL_DOCUMENTATION_DIRECTORY}/test.md"
  
  report_start_phase_standard

  # Test whether argument specifies a valid file
  [[ -f $1 ]] || { report_warn "Error: file not found: $1" >&2; exit 1; }

  # Displays the file to user using QuickLook
  report_action_taken "I am showing you a file: «$1»${NEWLINE}Don’t see it? Look behind other windows."
  /usr/bin/qlmanage -p "$1" >/dev/null 2>&1 &

  sleep 0.1
  osascript -e 'tell application "System Events" to set frontmost of process "qlmanage" to true' 2>/dev/null

  report_end_phase_standard
}
