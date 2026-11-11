#!/usr/bin/env zsh

############### Helpers related to tracking whether a given user has run the latest version of genomac-user.

function record_that_user_has_run_this_version_of_genomac_user() {
  # Writes a system state indicating that the current genomac-user user has run the current version of
  # genomac-user’s Hypervisor.
  # Deletes the obsolete prior state(s) for this user, if any.
  # This is intended to be run near the end of the Hypervisor process, and thus to mark a *successful*
  # run of this verion.
  # A partial, failed run of a version will not be recorded (until it is run ultimately successfully).

  report_start_phase_standard
  local commit_id
  local compliance_state_name
  local compliance_state_name_preamble
  local timestamp
  local username

  local -a preexisting_state_strings

  username="$(short_name_of_user_from_HOME)"
  commit_id="$(get_commit_id)"		           # scripts/helpers-git.sh
  timestamp="$(get_timestamp)"		           # scripts/helpers-misc.sh

  compliance_state_name_preamble="$(get_compliance_state_name_preamble_from_username "$username" )"

  # Collect complicance state strings, if any, for given user, to be deleted after the new
  # compliance state is successfully created.
  # _state_strings_with_prefix is at scripts/helpers-state.sh
  _state_strings_with_prefix "${compliance_state_name_preamble}" "system"
  preexisting_state_strings=("${reply[@]}")


  # Sets new, updated compliance state
  compliance_state_name="$( construct_compliance_state_name_from_elements \
                             "$username" \
                             "$commit_id" \
                             "$timestamp" \
                           )"
  set_genomac_system_state "$compliance_state_name"


  # Delete obsolete compliance states for this user, not that the replacement state has been successfully created.
  #
  # If there is zero preexisting_state_strings, that’s fine; there’s just no state to delete.
  # There should be at most 1 preexisting_state_strings, but it’s possible that one wasn’t cleaned
  # up in the past, and I don’t see a reason to throw a fuss if there are more than one.
  for state_string_to_delete in "${preexisting_state_strings[@]}"; do
    delete_genomac_system_state "$state_string_to_delete"
  done

  report_end_phase_standard
}

function construct_compliance_state_name_from_elements() {
  # Constructs a compliance state name from its elements.
  # Example:
  #   'USER_RAN_THIS_VERSION_OF_GENOMAC_USER∞§¶jim¶§∞v0.8.3-14-g7f3a2c1§∞¶2026_11_10_1530_45§¶∞'
  # Hints:
  #   USER_COMPLIANCE_PREFIX="USER_RAN_THIS_VERSION_OF_GENOMAC_USER"
  #   GENOMAC_STATE_STRING_DELIMITER_A="∞§¶"
  #   GENOMAC_STATE_STRING_DELIMITER_B="¶§∞"
  #   GENOMAC_STATE_STRING_DELIMITER_C="§∞¶"
  #   GENOMAC_STATE_STRING_DELIMITER_D="§¶∞"
  #
  report_start_phase_standard
  local username="${1:?MISSING user name}"
  local commit_id="${2:?MISSING commit id}"
  local timestamp="${3:?MISSING time stamp}"

  local compliance_state_name
  local compliance_state_name_preamble

  compliance_state_name_preamble="$(get_compliance_state_name_preamble_from_username "$username" )"

  compliance_state_name="${compliance_state_name_preamble}"
  compliance_state_name+="${commit_id}"
  compliance_state_name+="${GENOMAC_STATE_STRING_DELIMITER_C}"
  compliance_state_name+="${timestamp}"
  compliance_state_name+="${GENOMAC_STATE_STRING_DELIMITER_D}"

  print -r -- "$compliance_state_name"

  report_end_phase_standard
}

function get_compliance_state_name_preamble_from_username() {
  # Returns the preamble for the compliance state name, which is $USER_COMPLIANCE_PREFIX concatenated
  # with the user’s short name, separated by $GENOMAC_STATE_STRING_DELIMITER_A
  #
  # HINT: GENOMAC_STATE_STRING_DELIMITER_A="∞§¶"

  report_start_phase_standard

  local username="${1:?MISSING username}"

  local compliance_state_name_preamble

  compliance_state_name_preamble="${USER_COMPLIANCE_PREFIX}"
  compliance_state_name_preamble+="${GENOMAC_STATE_STRING_DELIMITER_A}"
  compliance_state_name_preamble+="${username}"
  compliance_state_name_preamble+="${GENOMAC_STATE_STRING_DELIMITER_B}"

  print -r -- "$compliance_state_name_preamble"

  report_end_phase_standard
}
