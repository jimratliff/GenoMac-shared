############### Helpers: Miscellaneous

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
