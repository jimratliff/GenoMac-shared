############### Helpers related to managing state for GenoMac

# Relies upon:
#   helpers-reporting.sh
#
#   Environment variables:
#     GENOMAC_USER_LOCAL_STATE_DIRECTORY
#	  GENOMAC_STATE_FILE_EXTENSION
#	  GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY

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

function _list_states() {
  # List all states for a given scope.
  #
  # Internal helper. Takes one string argument:
  #   $1: the "scope," either 'system' or 'user' depending on whether to list
  #       (a) system-wide states or (b) the current user's states
  #
  # Prints each state name (without path or extension) on its own line.
  # Exits normally if state directory doesn't exist or is empty.
  #
  # Usage: _list_states "user"
  #
  local scope="$1"
  local state_dir
  state_dir="$(_state_directory_for_scope "$scope")" || return 1

  [[ -d "${state_dir}" ]] || {
    report "State directory does not exist: ${state_dir}"
    return 0
  }

  local state_files=("${state_dir}"/*."${GENOMAC_STATE_FILE_EXTENSION}"(N))

  if (( ${#state_files[@]} > 0 )); then
    local state_file
    for state_file in "${state_files[@]}"; do
      # Extract just the state name: remove directory and extension
      local state_name="${state_file:t}"          # :t gives the "tail" (filename)
      state_name="${state_name%.${GENOMAC_STATE_FILE_EXTENSION}}"  # remove extension
      print -r -- "$state_name"
    done
  else
    report "No states found in ${state_dir}"
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
  #		  If the state file already exists, its timestamp is updated.
  #
  # Usage: _set_state "launch-and-sign-in-to-microsoft-word" "user"
  #
  local state_string="$1"
  local scope="$2"
  local state_file
  state_file="$(_state_file_path "$state_string" "$scope")" || return 1
  mkdir -p "${state_file:h}"  # zsh: :h gives the "head" (directory portion)
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

function _delete_states_matching() {
  # Internal helper that deletes state files for a given scope, optionally filtered by persistence type.
  #
  # Arguments:
  #   $1: the "scope," either 'system' or 'user'
  #   $2: (optional) persistence filter, either 'SESH' or 'PERM'. If omitted, deletes all state files.
  #
  # Usage:
  #   _delete_states_matching "user"          # deletes all user state files
  #   _delete_states_matching "user" "SESH"   # deletes only user SESH state files
  #
  local scope="$1"
  local persistence="$2"  # optional
  local state_dir
  state_dir="$(_state_directory_for_scope "$scope")" || return 1

  [[ -d "${state_dir}" ]] || {
    report "State directory does not exist: ${state_dir}" ; success_or_not
    return 0
  }

  local pattern
  if [[ -n "$persistence" ]]; then
    # Determine the prefix based on scope: GMS for system, GMU for user
    local prefix
    if [[ "$scope" == "system" ]]; then
      prefix="GMS"
    elif [[ "$scope" == "user" ]]; then
      prefix="GMU"
    else
      report "Invalid scope: ${scope}"
      return 1
    fi
    pattern="${prefix}_${persistence}_*"
  else
    pattern="*"
  fi

  local state_files=("${state_dir}"/${~pattern}."${GENOMAC_STATE_FILE_EXTENSION}"(N))

  if (( ${#state_files[@]} > 0 )); then
    rm -f "${state_files[@]}"
    local description
    if [[ -n "$persistence" ]]; then
      description="${#state_files[@]} ${persistence} state file(s)"
    else
      description="all ${#state_files[@]} state file(s)"
    fi
    report_action_taken "Deleted ${description} in ${state_dir}"
  else
    local description
    if [[ -n "$persistence" ]]; then
      description="${persistence} state files"
    else
      description="state files"
    fi
    report "No ${description} to delete in ${state_dir}" ; success_or_not
  fi
}

function _delete_all_states() {
  # Deletes all state files for a given scope.
  # Usage: _delete_all_states "user"
  _delete_states_matching "$1"
}

function _delete_all_SESH_states() {
  # Deletes all SESH (session) state files for a given scope.
  # Usage: _delete_all_SESH_states "user"
  _delete_states_matching "$1" "SESH"
}

##############################
# State functions scoped specifically to either (a) user or (b) system
############### User-scope state functions

function test_genomac_user_state() {
  _test_state "$1" "user"
}

function list_user_states() {
  # List all user-scope states.
  # Usage: _list_user_states
  _list_states "user"
}

function set_genomac_user_state() {
  _set_state "$1" "user"
}

function delete_genomac_user_state() {
  _delete_state "$1" "user"
}

function set_user_state_based_on_yes_no() {
  _set_state_based_on_yes_no "$1" "$2" "user"
}

function delete_all_user_states() {
  # Deletes all state files for user scope.
  # Usage: _delete_all_user_states
  _delete_states_matching "user"
}

############### System-scope state functions

function test_genomac_system_state() {
  _test_state "$1" "system"
}

function list_system_states() {
  # List all system-scope states.
  # Usage: _list_system_states
  _list_states "system"
}

function set_genomac_system_state() {
  _set_state "$1" "system"
}

function delete_genomac_system_state() {
  _delete_state "$1" "system"
}

function set_system_state_based_on_yes_no() {
  _set_state_based_on_yes_no "$1" "$2" "system"
}

function delete_all_system_states() {
  # Deletes all state files for system scope.
  # Usage: _delete_all_system_states
  _delete_states_matching "system"
}

function delete_all_GMS_SESH_states() {
  # Deletes all SESH (session) state files for system scope.
  # Usage: _delete_all_GMS_SESH_states
  _delete_states_matching "system" "SESH"
}

function delete_all_GMU_SESH_states() {
  # Deletes all SESH (session) state files for user scope.
  # Usage: _delete_all_GMU_SESH_states
  _delete_states_matching "user" "SESH"
}
