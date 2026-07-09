#!/usr/bin/env zsh

############### Helpers: Users

function short_name_of_user_from_HOME() {
  # Prints the current user's short name, inferred from $HOME.
  #
  # Assumes the user's home directory path ends with the short name, e.g.:
  #   /Users/configger
  #   /Volumes/Personal/Users/jim
  #
  # Returns:
  #   0 if $HOME appears usable
  #   1 otherwise

  local home_dir="${HOME:-}"

  if [[ -z "$home_dir" ]]; then
    report_fail "HOME is not set."
    return 1
  fi

  print -- "${home_dir:t}"
}

function user_home_directory_is_on_startup_volume() {
  # Return 0 if user’s home directory is on startup volume; otherwise, return 1
  report_start_phase_standard
  if [[ "$HOME" != "/Users/$USER" ]]; then
    report_to_log "Current user does NOT reside on startup volume."
    report_end_phase_standard
    return 1
  fi
  report_to_log "Current user does reside on startup volume."
  report_end_phase_standard
  return 0
}

function is_HOME_too_long_for_1P_SSH_Agent_socket() {
  # Returns 0 if $HOME is so long that the resulting path to 1Password’s SSH Agent
  # socket will exceed MAX_LENGTH_1P_SSH_AGENT_SOCKET_PATH.
  # Returns 1 otherwise.
  report_start_phase_standard
  if (( ${#HOME} <= MAX_LENGTH_HOME_PER_1P_SSH_AGENT_SOCKET_PATH_LIMITATION )); then
    report_end_phase_standard
    return 1
  fi

  local warning_message
  warning_message="Choice of volume and user results in \$HOME being longer than $MAX_LENGTH_HOME_PER_1P_SSH_AGENT_SOCKET_PATH_LIMITATION characters."
  warning_message+="${NEWLINE}\$HOME: $HOME"
  warning_message+="Length of \$HOME: ${#HOME}"
  report_warning "$warning_message"
  report_end_phase_standard
  return 0
}
