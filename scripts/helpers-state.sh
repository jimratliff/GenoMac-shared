############### Helpers related to managing state for GenoMac

# Relies upon:
#   helpers-reporting.sh
#
#   Environment variables:
#     GENOMAC_USER_LOCAL_STATE_DIRECTORY
#	  GENOMAC_STATE_FILE_EXTENSION
#	  GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY

# TODOs: Rather than `_reset_state()`, what I really need is:
#		 - delete_all_SESH_state()
#		 - delete_all_PERM_state() (though it’s not clear this was is necessary)

function _state_directory_for_scope() {
  # Internal helper. Takes one argument that is either 'system' or 'user' and returns correspondingly either 
  # (a) $GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY or (b) $GENOMAC_USER_LOCAL_STATE_DIRECTORY, respectively
  #
  #    state_dir="$(_state_directory_for_scope "user")"   # Returns user directory
  #    state_dir="$(_state_directory_for_scope "system")" # Returns system directory
  #    state_dir="$(_state_directory_for_scope "bogus")"  # Reports error, returns 1
  
  local scope="$1"
  case "$scope" in
    user)
      echo "${GENOMAC_USER_LOCAL_STATE_DIRECTORY}"
      ;;
    system)
      echo "${GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY}"
      ;;
    *)
      report_fail "Unexpected value '$scope'. Expected either 'system' or 'user'."
      return 1
      ;;
  esac
}

function _state_file_path() {
  # Returns the path of the state file corresponding to a given state string and scope.
  #
  # Internal helper. Takes two string arguments:
  #   $1: the “state string” that labels the state
  #   $2: the “scope,” either 'system' or 'user' depending on whether this state characterizes
  # 	  (a) the entire 'system' (e.g., that Mac) or instead (b) characterizes a particular 'user'
  # Returns the path of the corresponding state file.
  #
  # Usage:
  #     _state_file_path "launch-and-sign-in-to-microsoft-word" "user"
  #   Returns: ~/.genomac-user-state/launch-and-sign-in-to-microsoft-word.state
  #
  #     _state_file_path "machine-is-laptop" "system"
  #   Returns: /etc/genomac/state/machine-is-laptop.state

  local state_string="$1"
  local scope="$2"
  local state_dir
  state_dir="$(_state_directory_for_scope "$scope")" || return 1
  echo "${state_dir}/${state_string}.${GENOMAC_STATE_FILE_EXTENSION}"
}

function _user_state_file_path() {
    # Internal helper: returns the path of the state file corresponding to a given state string
	_state_file_path "$1" "user"
}

function _system_state_file_path() {
    # Internal helper: returns the path of the state file corresponding to a given state string
    _state_file_path "$1" "system"
}

function _test_state() {
  # Test whether the state represented by the state-key string in $1 exists in the 'system'/'user' scope in $2.
  #
  # Internal helper. Takes two string arguments:
  #   $1: the “state string” that labels the state
  #   $2: the “scope,” either 'system' or 'user' depending on whether this state characterizes 
  # 	  (a) the entire 'system' (e.g., that Mac) or instead (b) characterizes a particular 'user'
  #
  # Returns 0 if the state exists, 1 otherwise.
  # Usage: test_state "launch-and-sign-in-to-microsoft-word" "user"
  #
  # NOTE: Currently, a state's existence is equivalent to the existence of a corresponding .state 
  #		  file (more generally a file with .GENOMAC_STATE_FILE_EXTENSION).
  #		  This is an implementation detail. The test_state() API does not rely upon or expose this 
  # 	  implementation detail.
  #
  #	Example:
  #    if ! _test_state "launch-and-sign-in-to-microsoft-word" "user"; then
  #        # Perform the one-time operation
  #        open -a "Microsoft Word"
  #        echo "Please sign in to Microsoft Word, then press Enter..."
  #        read
  #        set_state "launch-and-sign-in-to-microsoft-word" "user"
  #    fi
  
  local state_string="$1"
  local scope="$2"
  local state_file
  state_file="$(_state_file_path "$state_string" "$scope")" || return 1
  if [[ -f "$state_file" ]]; then
  	report "State detected: “${state_string}”"
  	return 0
  else
  	report "State not present: “${state_string}”"
  	return 1
  fi
}

function _set_state() {
  # Establish a state for a given (key, scope) pair.
  #
  # Internal helper. Takes two string arguments:
  #   $1: the "state string" that labels the state
  #   $2: the "scope," either 'system' or 'user' depending on whether this state characterizes 
  # 	  (a) the entire 'system' (e.g., that Mac) or instead (b) characterizes a particular 'user'
  #
  # NOTE: Currently, a state's existence is equivalent to the existence of a corresponding .state 
  #		  (more generally .GENOMAC_STATE_FILE_EXTENSION) file.
  #		  This is an implementation detail. The test_state() API does not rely upon or expose this 
  # 	  implementation detail.
  #
  # 	  Creates the state directory if it doesn't exist.
  #
  # Usage: _set_state "launch-and-sign-in-to-microsoft-word" "user"
  #
  local state_string="$1"
  local scope="$2"
  local state_file
  state_file="$(_state_file_path "$state_string" "$scope")" || return 1
  mkdir -p "${state_dir}"
  report_action_taken "Setting state: “${state_string}”"
  touch "$state_file" ; success_or_not
}

function _delete_state() {
  # Remove a state for a given (key, scope) pair.
  #
  # Internal helper. Takes two string arguments:
  #   $1: the "state string" that labels the state
  #   $2: the "scope," either 'system' or 'user' depending on whether this state characterizes 
  # 	  (a) the entire 'system' (e.g., that Mac) or instead (b) characterizes a particular 'user'
  #
  # NOTE: Currently, a state's existence is equivalent to the existence of a corresponding .state 
  #		  (more generally .GENOMAC_STATE_FILE_EXTENSION) file.
  #		  This is an implementation detail. The _delete_state() API does not rely upon or expose this 
  # 	  implementation detail.
  #
  # 	  Does nothing if the state does not exist.
  #
  # Usage: _delete_state "launch-and-sign-in-to-microsoft-word" "user"
  #
  local state_string="$1"
  local scope="$2"
  local state_file
  state_file="$(_state_file_path "$state_string" "$scope")" || return 1
  if [[ -f "$state_file" ]]; then
  	rm -f "$state_file"
  	report_action_taken "Deleted state: “${state_string}”"
  else
  	report "State not present (nothing to delete): “${state_string}”"
  fi
}

function _reset_state() {
  # Resets all state for a given scope by deleting all state files, but leaving the state directory intact.
  #
  # Internal helper. Takes one string argument:
  #   $1: the "scope," either 'system' or 'user' depending on whether to reset (a) system-wide state
  #       or (b) the current user's state
  # Exits normally even if state directory doesn’t exist or is empty.
  #
  # Usage: _reset_state "user"
  #
  local scope="$1"
  local state_dir
  state_dir="$(_state_directory_for_scope "$scope")" || return 1
  [[ -d "${state_dir}" ]] || {
    report "State directory does not exist: ${state_dir}" ; success_or_not
    return 0
  }
  local state_files=("${state_dir}"/*."${GENOMAC_STATE_FILE_EXTENSION}"(N))
  if (( ${#state_files[@]} > 0 )); then
    report_action_taken "Reset all state in ${state_dir}"
    rm -f "${state_files[@]}" ; success_or_not
  else
    report "No state files to reset in ${state_dir}" ; success_or_not
  fi
}

function _set_state_based_on_yes_no() {
  # Conditionally set or delete a state based on user's yes/no response.
  #
  # Internal helper. Takes three string arguments:
  #   $1: the "state string" that labels the state
  #   $2: the prompt to display to the user
  #   $3: the "scope," either 'system' or 'user' depending on whether this state characterizes 
  #       (a) the entire 'system' (e.g., that Mac) or instead (b) characterizes a particular 'user'
  #
  # Prompts the user with a yes/no question. If yes, sets the state; if no, deletes the state.
  #
  # Usage: _set_state_based_on_yes_no "machine-is-laptop" "Is this machine a laptop?" "system"
  #
  local state_string="$1"
  local prompt="$2"
  local scope="$3"
  if get_yes_no_answer_to_question "$prompt"; then
    _set_state "$state_string" "$scope"
  else
    _delete_state "$state_string" "$scope"
  fi
}

# User-scope state functions

function test_genomac_user_state() {
  _test_state "$1" "user"
}

function set_genomac_user_state() {
  _set_state "$1" "user"
}

function delete_genomac_user_state() {
  _delete_state "$1" "user"
}

function reset_genomac_user_state() {
  _reset_state "user"
}

function set_user_state_based_on_yes_no() {
  _set_state_based_on_yes_no "$1" "$2" "user"
}

# System-scope state functions

function test_genomac_system_state() {
  _test_state "$1" "system"
}

function set_genomac_system_state() {
  _set_state "$1" "system"
}

function delete_genomac_system_state() {
  _delete_state "$1" "system"
}

function reset_genomac_system_state() {
  _reset_state "system"
}

function set_system_state_based_on_yes_no() {
  _set_state_based_on_yes_no "$1" "$2" "system"
}
