#!/usr/bin/env zsh

# State-management helpers to facilitate communication between system-scoped states
# and user-scoped states.
#
# These are used at least for example:
# - regarding new users pending initial configuration.
#   - The existence of the newly created user is set by GenoMac-system in a system-scoped
#     state.
#     - GenoMac-system then presents a list of these users to USER_CONFIGURER
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

function display_users_to_be_initially_configured() {
  # Prints list of users still awaiting initial configuration.
  
  report_start_phase_standard
  
  local number_of_awaiting_users
  local report_string=""
  local user_short_name

  local -a user_short_names
  
  get_array_of_users_to_be_initially_configured
  user_short_names=("${reply[@]}")

  number_of_awaiting_users=${#user_short_names[@]}

  if (( ! number_of_awaiting_users )); then
    report_highlight "There are no users awaiting their initial configuration by GenoMac-user."
  else
    report_string="📋 The following $number_of_awaiting_users user(s) is/are awaiting their initial configuration by GenoMac-user:"
    for user_short_name in "${user_short_names[@]}"; do
      report_string+="${user_short_name}${NEWLINE}"
    done
    report_highlight "$report_string"
  fi
  
  report_end_phase_standard
}

function get_array_of_users_to_be_initially_configured() {
  # Return array of newly created users who haven’t yet been initially configured by GenoMac-user.
  #
  # See GenoMac-shared/scripts/helpers-state-xfer-btw-system-user.sh »
  #    				construct_system_state_string_for_user_in_need_of_initial_config()
  # for the format of the relevant state strings.
  
  report_start_phase_standard
  local short_name
  local state_string
  local state_string_prefix

  local -a state_strings
  local -a user_short_names=()

  # Collect state strings, one for each user awaiting initial configuration
  state_string_prefix="$(construct_system_state_string_for_user_in_need_of_initial_config --prefix-only)"
  _state_strings_with_prefix "${state_string_prefix}" "system"
  state_strings=("${reply[@]}")

  # Construct array of user short-names that are awaiting initial configuration

  for state_string in "${state_strings[@]}"; do
    short_name="$(
	    nonempty_content_between_delimiters \
	      "$state_string" \
        "$GENOMAC_STATE_STRING_DELIMITER_A" \
        "$GENOMAC_STATE_STRING_DELIMITER_B"
    )"
	  user_short_names+=("$short_name")
  done
  reply=("${user_short_names[@]}")
  
  report_end_phase_standard
}

function mark_user_as_in_need_of_initial_config(){
  # Set system-scoped state to mark user as in need of initial configuration
  report_start_phase_standard
  local short_name="$1"
  local state_string

  state_string="$(construct_system_state_string_for_user_in_need_of_initial_config "$short_name")"
  set_genomac_system_state "$state_string"
  
  report_end_phase_standard
}

function unmark_user_as_in_need_of_initial_config(){
  # Un-sets, by deleting, system-scoped state that marks user as in need of initial configuration
  report_start_phase_standard
  local short_name="$1"
  local state_string

  state_string="$(construct_system_state_string_for_user_in_need_of_initial_config "$short_name")"
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

function construct_system_state_string_for_user_in_need_of_initial_config() {
  # Constructs the system-scoped state string indicating that a user is in
  # need of initial configuration.
  #
  # Usage:
  #   construct_system_state_string_for_user_in_need_of_initial_config SHORT_NAME
  #   construct_system_state_string_for_user_in_need_of_initial_config --prefix-only
  #
  #   state_string_prefix="$(construct_system_state_string_for_user_in_need_of_initial_config --prefix-only)"
  #
  # Prints either:
  #   "${PREFIX}${DELIMITER_A}${short_name}${DELIMITER_B}"
  # or, with --prefix-only:
  #   "${PREFIX}${DELIMITER_A}"

  report_start_phase_standard

  local short_name
  local prefix
  local state_string
  local prefix_only=false

  if (( $# != 1 )); then
    report_fail "Expected exactly one argument: either short_name or --prefix-only."
    report_end_phase_standard
    return 64
  fi

  if [[ "$1" == "--prefix-only" ]]; then
    prefix_only=true
  else
    short_name="$1"
  fi

  prefix="${GENOMAC_STATE_USER_IS_PENDING_INITIAL_CONFIGURATION_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}"

  state_string="$prefix"

  if [[ "$prefix_only" != true ]]; then
    state_string+="${short_name}${GENOMAC_STATE_STRING_DELIMITER_B}"
  fi

  print -- "$state_string"

  report_end_phase_standard
}

##############################
# State functions for user attributes and user class
#
# User-attribute states are system-scoped states because, at the time they are created, the
# relevant user doesn’t yet have a home directory.

function mark_current_user_as_user_configger() {
  # To be called by GenoMac-system’s Hypervisor, which by definition is executed by USER_CONFIGURER.
  report_start_phase_standard
  
  local short_name
  short_name="$(short_name_of_user_from_HOME)"
  
  set_system_state_for_user_attribute "$short_name" "$USER_ATTRIBUTE_IS_USER_CONFIGURER"
  
  report_end_phase_standard
}

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
  
  state_string="$(construct_state_string_for_user_and_attribute "$user_short_name" "$attribute_name")"
  _set_state "${state_string}" "$scope"
}

function get_attribute_name_from_user_attribute_state_string() {
  # Prints the attribute name from a user-attribute state string to stdout.
  #
  # Currently, does NOT validate that the state string is a properly formed user-attribute state string.
  report_start_phase_standard
  local state_string="${1:?MISSING state_string}"
  local attribute_name

  attribute_name="$(nonempty_content_between_delimiters "$state_string" "$GENOMAC_STATE_STRING_DELIMITER_B" "$GENOMAC_STATE_STRING_DELIMITER_C")"
  print -- "$attribute_name"
  
  report_end_phase_standard
}

function construct_state_string_for_user_and_touch_ID_choice() {
  # Template for a Zsh function in Project GenoMac
  report_start_phase_standard
  local short_name="{1:?MISSING short_name}"
  local touch_id_choice="{2:?MISSING touch_id_choice}"

  local attribute_name="${USER_ATTRIBUTE_TOUCH_ID_PREFIX}${touch_id_choice}"
  construct_state_string_for_user_and_attribute "$short_name" "$attribute_name"

  report_end_phase_standard
}

function construct_state_string_for_user_and_attribute() {
  # Constructs a user-attribute state string.
  #
  # This state string applies to BOTH (a) system-scoped and (b) user-scoped state strings
  # for user attributes. (It’s redundant to encode the user’s short name into the
  # user-scoped state string, but that redundancy earns its keep by avoiding additional code
  # and by simplyfying code and improving maintainability.)
  #
  # Full form:
  #   USER_ATTRIBUTE∞§¶shortname¶§∞attributename§∞¶
  #
  # With --user-only:
  #   USER_ATTRIBUTE∞§¶shortname¶§∞
  #
  # Usage:
  #   construct_state_string_for_user_and_attribute short_name attribute_name
  #   construct_state_string_for_user_and_attribute --user-only short_name
  #   construct_state_string_for_user_and_attribute short_name --user-only
  #   construct_state_string_for_user_and_attribute short_name attribute_name --user-only
  
  # Hints: 
  #       GENOMAC_STATE_USER_ATTRIBUTE_PREFIX="USER_ATTRIBUTE"
  #       GENOMAC_STATE_STRING_DELIMITER_A="∞§¶"
  #       GENOMAC_STATE_STRING_DELIMITER_B="¶§∞"
  #       GENOMAC_STATE_STRING_DELIMITER_C="§∞¶"
  #
  # Prints result to stdout.

  local user_only=false
  local short_name=""
  local attribute_name=""
  local arg

  for arg in "$@"; do
    case "$arg" in
      --user-only)
        user_only=true
        ;;

      --*)
        report_fail "Unknown option: $arg"
        return 1
        ;;

      *)
        if [[ -z "$short_name" ]]; then
          short_name="$arg"
        elif [[ -z "$attribute_name" ]]; then
          attribute_name="$arg"
        else
          report_fail "Too many positional arguments: $arg"
          return 1
        fi
        ;;
    esac
  done

  [[ -n "$short_name" ]] || {
    report_fail "Missing short_name"
    return 1
  }

  if [[ "$user_only" != true && -z "$attribute_name" ]]; then
    report_fail "Missing attribute_name"
    return 1
  fi

  local state_string

  state_string="${GENOMAC_STATE_USER_ATTRIBUTE_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}${short_name}${GENOMAC_STATE_STRING_DELIMITER_B}"

  if [[ "$user_only" != true ]]; then
    state_string+="${attribute_name}${GENOMAC_STATE_STRING_DELIMITER_C}"
  fi

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
  
  state_string="$(construct_state_string_for_user_and_attribute "$user_short_name" "$attribute_name")"
  
  # The following call to _test_state must be the last command of this function, because its return value is crucial to the caller
  _test_state "${state_string}" "$scope"
}

# function construct_state_string_for_user_has_attribute() {
#   # Constructs state string that asserts that the user has at least one attribute.
#   #
#   # This state string applies to BOTH (a) system-scoped and (b) user-scoped state strings
#   # for user attributes. (It’s redundant to encode the user’s short name into the
#   # user-scoped state string, but that redundancy earns its keep by avoiding additional code
#   # and by simplyfying code and improving maintainability.)
#   #
#   # Full form:
#   #   USER_HAS_ATTRIBUTE∞§¶shortname¶§∞
#   #
#   # Usage:
#   #   construct_state_string_for_user_has_attribute short_name
#   #
#   # Hints: 
#   #       # GENOMAC_STATE_USER_HAS_AN_ATTRIBUTE_PREFIX="USER_HAS_ATTRIBUTE"
#   #       GENOMAC_STATE_STRING_DELIMITER_A="∞§¶"
#   #       GENOMAC_STATE_STRING_DELIMITER_B="¶§∞"
#   #
#   # Prints result to stdout.
#   
#   local short_name
#   short_name="${1:?missing short_name}"
# 
#   local state_string
#   state_string="${GENOMAC_STATE_USER_HAS_AN_ATTRIBUTE_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}${short_name}${GENOMAC_STATE_STRING_DELIMITER_B}"
# 
#   print -- "$state_string"
# }

# function _set_state_for_user_class(){
#   # $1: user_short_name: The user to whom the attribute belongs
#   # $2: user_class
#   # $3: the "scope," either 'system' or 'user' depending on whether this state characterizes 
#   # 	  (a) the entire 'system' (e.g., that Mac) or instead (b) characterizes a particular 'user'
#   #
#   # First deletes any existing system-scoped states asserting a user-class for this user,
#   # in order that the subsequent assignment will be on a blank slate.
# 
#   local user_short_name="${1:?missing/empty user_short_name}"
#   local user_class="${2:?missing/empty user_class}"
#   local scope="${3:?missing/empty scope}"
#   
#   local state_string
#   local user_only_prefix
# 
#   # Delete all $scope-scoped states asserting a user-class for this user, in order that
#   # the subsequent assignment will be on a blank slate.
#   user_only_prefix="$(construct_state_string_for_user_class "$user_short_name" --user-only )"
#   delete_all_system_states_matching_prefix "$delete_all_system_states_matching_prefix"
# 
#   # Set $scope-scoped state asserting this user has the supplied user-class
#   state_string="$(construct_state_string_for_user_class "$user_short_name" "$user_class")"
#   _set_state "${state_string}" "$scope"
# }
# 
# function set_system_state_for_user_class(){
#   # Set system-scoped state asserting given user has given user class.
# 
#   report_start_phase_standard
#   local short_name="${1:?missing short name}"
#   local user_class="${2:?missing user class}"
# 
#   _set_state_for_user_class "$short_name" "$user_class" "system"
# 
#   report_end_phase_standard
# }

# function construct_state_string_for_user_class() {
#   # Constructs a user-class state string.
#   #
#   # Full form:
#   #   USER_CLASS∞§¶shortname¶§∞user_class§∞¶
#   #
#   # With --user-only:
#   #   USER_CLASS∞§¶shortname¶§∞
#   #
#   # Usage:
#   #   construct_state_string_for_user_class short_name user_class
#   #   construct_state_string_for_user_class --user-only short_name
#   #   construct_state_string_for_user_class short_name --user-only
#   #
#   # Prints result to stdout.
# 
#   local user_only=false
#   local short_name=""
#   local user_class=""
#   local arg
# 
#   for arg in "$@"; do
#     case "$arg" in
#       --user-only)
#         user_only=true
#         ;;
# 
#       --*)
#         report_fail "Unknown option: $arg"
#         return 1
#         ;;
# 
#       *)
#         if [[ -z "$short_name" ]]; then
#           short_name="$arg"
#         elif [[ -z "$user_class" ]]; then
#           user_class="$arg"
#         else
#           report_fail "Too many positional arguments: $arg"
#           return 1
#         fi
#         ;;
#     esac
#   done
# 
#   if [[ -z "$short_name" ]]; then
#     report_fail "Missing short_name"
#     return 1
#   fi
# 
#   if [[ "$user_only" == true && -n "$user_class" ]]; then
#     report_fail "user_class must not be supplied with --user-only"
#     return 1
#   fi
# 
#   if [[ "$user_only" != true && -z "$user_class" ]]; then
#     report_fail "Missing user_class"
#     return 1
#   fi
# 
#   local state_string
# 
#   state_string="${GENOMAC_STATE_USER_CLASS_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}${short_name}${GENOMAC_STATE_STRING_DELIMITER_B}"
# 
#   if [[ "$user_only" != true ]]; then
#     state_string+="${user_class}${GENOMAC_STATE_STRING_DELIMITER_C}"
#   fi
# 
#   print -- "$state_string"
# }

