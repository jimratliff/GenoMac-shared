#!/usr/bin/env zsh

# State-management helpers to facilitate communication between system-scoped states
# and user-scoped states.
#
# These are used at least for example:
# - regarding new users pending initial configuration.
#   - The existence of the newly created user is set by GenoMac-system in a system-scoped
#     state.
#   - This system-scoped state is read by GenoMac-user. After GenoMac-user completes the
#     initial configuration of the user, GenoMac-user deletes this system-scoped 
#     user-pending state.
# - reading and writer user attributes
#   - When GenoMac-system creates new users, GenoMac-system reads a JSON configuration
#     from an item in a 1Password vault, which contains a list of attributes for each
#     new user.
#   - GenoMac-system writes, for each user, and each of those attributes, a system-scoped
#     state.
#   - GenoMac-user (at the beginning of its Hypervisor) reads those system-scoped 
#     user-attribute states that are specific to the particular user and:
#     - writes a corresponding user-scoped state for that attribute
#     - deletes the now-superfluous system-scoped state.

##############################
# State functions for user attributes
#
# User-attribute states are system-scoped states because, at the time they are created, the
# relevant user doesn’t yet have a home directory.

function construct_state_string_for_user_attribute(){
  # Constructs the state string for a user attribute of the form: "USER_ATTRIBUTE_shortname_attributename"
  # Hint: GENOMAC_STATE_USER_ATTRIBUTE_PREFIX="USER_ATTRIBUTE_"
  # $1: user_short_name: The user to whom the attribute belongs
  # $2: attribute_name
  #
  # The result is printed to stdout

  local user_short_name="$1"
  local attribute_name="$2"
  local state_string

  state_string="${GENOMAC_STATE_USER_ATTRIBUTE_PREFIX}${user_short_name}_${attribute_name}"

  print -- "$state_string"
}

function _test_state_for_user_attribute(){
  # $1: user_short_name: The user to whom the attribute belongs
  # $2: attribute_name
  # $3: the "scope," either 'system' or 'user' depending on whether this state characterizes 
  # 	  (a) the entire 'system' (e.g., that Mac) or instead (b) characterizes a particular 'user'

  local user_short_name="${1:?missing/empty user_short_name}"
  local attribute_name="${2:?missing/empty attribute_name}"
  local scope="${3:?missing/empty scope}"
  local state_string
  
  state_string="$(construct_state_string_for_user_attribute "$user_short_name" "$attribute_name")"
  
  # The following call to _test_state must be the last command of this function, because its return value is crucial to the caller
  _test_state "${state_string}" "$scope"
}

function _set_state_for_user_attribute(){
  # $1: user_short_name: The user to whom the attribute belongs
  # $2: attribute_name
  # $3: the "scope," either 'system' or 'user' depending on whether this state characterizes 
  # 	  (a) the entire 'system' (e.g., that Mac) or instead (b) characterizes a particular 'user'

  local user_short_name="${1:?missing/empty user_short_name}"
  local attribute_name="${2:?missing/empty attribute_name}"
  local scope="${3:?missing/empty scope}"
  local state_string
  
  state_string="$(construct_state_string_for_user_attribute "$user_short_name" "$attribute_name")"
  _set_state "${state_string}" "$scope"
}
