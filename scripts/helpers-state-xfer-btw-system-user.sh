#!/usr/bin/env zsh

# State-management helpers to facilitate communication between system-scoped states
# and user-scoped states.
#
# These are used at least for example:
# - regarding new users pending initial configuration.
#   - The existence of the newly created user is set by GenoMac-system in a system-scoped
#     state.
#     - GenoMac-system then presents a list of these users to user_configurer
#   - After the newly created user uses GenoMac-user to complete that user’s
#     initial configuration, GenoMac-user deletes this system-scoped user-pending state
#     (so that this user will no longer be flagged as requiring initial configuration).
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
# State functions for marking a newly created user as in need of configuration
#
# These states are system-scoped states because, at the time they are created, the
# relevant user doesn’t yet have a home directory.

function mark_user_as_in_need_of_initial_config(){
  # Set system-scoped state to mark user as in need of initial configuration
  report_start_phase_standard
  local short_name="$1"
  local state_string

  state_string="$(construct_state_string_for_user_in_need_of_initial_config "$short_name")"
  set_genomac_system_state "$state_string"
  
  report_end_phase_standard
}

function unmark_user_as_in_need_of_initial_config(){
  # Un-sets, by deleting, system-scoped state that marks user as in need of initial configuration
  report_start_phase_standard
  local short_name="$1"
  local state_string

  state_string="$(construct_state_string_for_user_in_need_of_initial_config "$short_name")"
  delete_genomac_system_state "$state_string"
  
  report_end_phase_standard
}

function unmark_current_user_as_in_need_of_initial_config(){
  # Un-sets, by deleting, system-scoped state that marks current user as in need of initial configuration
  report_start_phase_standard
  local short_name
  short_name="$(short_name_of_user_from_HOME)"
  unmark_user_as_in_need_of_initial_config "$short_name"
  report_end_phase_standard
}

function construct_state_string_for_user_in_need_of_initial_config(){
  # Constructs state string for the system-scoped state indicating a user is in
  # need of initial configuration.

  report_start_phase_standard
  local short_name="$1"
  local state_string

  state_string="${GENOMAC_STATE_USER_IS_PENDING_INITIAL_CONFIGURATION_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}${short_name}${GENOMAC_STATE_STRING_DELIMITER_B}"

  print -- "$state_string"

  report_end_phase_standard
}

##############################
# State functions for user attributes and user class
#
# User-attribute states are system-scoped states because, at the time they are created, the
# relevant user doesn’t yet have a home directory.

function set_system_state_for_user_attribute(){
  # Set system-scoped state asserting given user has given attribute.

  report_start_phase_standard
  local short_name="${1:?missing short name}"
  local attribute_name="${2:?missing attribute name}"

  _set_state_for_user_attribute "$short_name" "$attribute_name" "system"

  report_end_phase_standard
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

  state_string="${GENOMAC_STATE_USER_ATTRIBUTE_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}${short_name}${GENOMAC_STATE_STRING_DELIMITER_B}${attribute_name}${GENOMAC_STATE_STRING_DELIMITER_C}"

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

function set_system_state_for_user_class(){
  # Set system-scoped state asserting given user has given user class.

  report_start_phase_standard
  local short_name="${1:?missing short name}"
  local user_class="${2:?missing user class}"

  _set_state_for_user_attribute "$short_name" "$user_class" "system"

  report_end_phase_standard
}

function construct_state_string_for_user_class(){
  # Constructs the state string for a user class of the form: "USER_ATTRIBUTE_shortname_attributename"
  # Hint: GENOMAC_STATE_USER_ATTRIBUTE_PREFIX="USER_ATTRIBUTE_"
  # $1: user_short_name: The user to whom the attribute belongs
  # $2: user_class
  #
  # The result is printed to stdout

  local user_short_name="$1"
  local user_class="$2"
  
  local state_string
  state_string="${GENOMAC_STATE_USER_CLASS_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}${short_name}${GENOMAC_STATE_STRING_DELIMITER_B}${user_class}${GENOMAC_STATE_STRING_DELIMITER_C}"
  print -- "$state_string"
  
}

