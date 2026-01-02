# Prevent multiple sourcing
if [[ -n "${__already_loaded_genomac_bootstrap_helpers_sh:-}" ]]; then return 0; fi
__already_loaded_genomac_bootstrap_helpers_sh=1
export __already_loaded_genomac_bootstrap_helpers_sh

############### HELPERS

# Set up and assign colors
ESC_SEQ="\033["

COLOR_RESET="${ESC_SEQ}0m"

COLOR_BLACK="${ESC_SEQ}30;01m"
COLOR_RED="${ESC_SEQ}31;01m"
COLOR_GREEN="${ESC_SEQ}32;01m"
COLOR_YELLOW="${ESC_SEQ}33;01m"
COLOR_BLUE="${ESC_SEQ}34;01m"
COLOR_MAGENTA="${ESC_SEQ}35;01m"
COLOR_CYAN="${ESC_SEQ}36;01m"
COLOR_WHITE="${ESC_SEQ}37;01m"

COLOR_QUESTION="$COLOR_MAGENTA"
COLOR_REPORT="$COLOR_BLUE"
COLOR_ADJUST_SETTING="$COLOR_CYAN"
COLOR_ACTION_TAKEN="$COLOR_GREEN"
COLOR_WARNING="$COLOR_YELLOW"
COLOR_ERROR="$COLOR_RED"
COLOR_SUCCESS="$COLOR_GREEN"
COLOR_KILLED="$COLOR_RED"

SYMBOL_SUCCESS="✅ "
SYMBOL_FAILURE="❌ "
SYMBOL_QUESTION="❓ "
SYMBOL_ADJUST_SETTING="⚙️  "
SYMBOL_KILLED="☠️ "
SYMBOL_ACTION_TAKEN="🪚 "
SYMBOL_WARNING="🚨 "

# Example usage
# Each %b and %s maps to a successive argument to printf
# printf "%b[ok]%b %s\n" "$COLOR_GREEN" "$COLOR_RESET" "some message"

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

function success_or_not() {
  # Print SYMBOL_SUCCESS if success (based on error code); otherwise SYMBOL_FAILURE
  if [[ $? -eq 0 ]]; then
    printf " ${SYMBOL_SUCCESS}\n"
  else
    printf "\n${SYMBOL_FAILURE}\n"
  fi
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



