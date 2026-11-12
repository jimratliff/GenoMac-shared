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

function parse_compliance_state_string_into_array_of_components() {
  # Parse a compliance state string into a 3-element array of components.
  report_start_phase_standard

  local compliance_state_string="${1:?MISSING compliance state string}"

  local commit_id
  local timestamp
  local username


  reply=()

  username="$(
    nonempty_content_between_delimiters \
      "$compliance_state_string" \
      "$GENOMAC_STATE_STRING_DELIMITER_A" \
      "$GENOMAC_STATE_STRING_DELIMITER_B"
  )"

  commit_id="$(
    nonempty_content_between_delimiters \
      "$compliance_state_string" \
      "$GENOMAC_STATE_STRING_DELIMITER_B" \
      "$GENOMAC_STATE_STRING_DELIMITER_C"
  )"

  timestamp="$(
    nonempty_content_between_delimiters \
      "$compliance_state_string" \
      "$GENOMAC_STATE_STRING_DELIMITER_C" \
      "$GENOMAC_STATE_STRING_DELIMITER_D"
  )"

  reply=("$username" "$commit_id" "$timestamp")

  report_end_phase_standard
}

function output_compliance_status() {
  # Report the most recent recorded GenoMac-user run for each user on this Mac.
  # Run from a GenoMac-user checkout. The remote main branch is the baseline.
  report_start_phase_standard

  local compliance_state_string
  local commit_id
  local current_commit_id
  local current_hash
  local recorded_hash
  local unverified_run
  local timestamp
  local username
  local -i i
  local -i number_of_up_to_date_users
  local -i number_of_out_of_date_users
  local -i number_of_unverified_users
  local -a reply
  local -a compliance_state_strings
  local -a up_to_date_users=()
  local -a out_of_date_users_components=()
  local -a unverified_runs=()
  local -A latest_commit_ids=()
  local -A latest_timestamps=()

  _state_strings_with_prefix "${USER_COMPLIANCE_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}" "system"
  compliance_state_strings=("${reply[@]}")

  git fetch --tags origin +refs/heads/main:refs/remotes/origin/main
  current_hash="$(git rev-parse --verify refs/remotes/origin/main)"
  current_commit_id="$(git describe --tags --long --always "$current_hash")"
  report "The current commit ID on origin/main is $current_commit_id"

  for compliance_state_string in "${compliance_state_strings[@]}"; do
    parse_compliance_state_string_into_array_of_components "$compliance_state_string"
    username="${reply[1]}"
    commit_id="${reply[2]}"
    timestamp="${reply[3]}"

    # The fixed-width, year-first timestamps sort in chronological order.
    if [[ "$timestamp" > "${latest_timestamps[$username]-}" ]]; then
      latest_timestamps[$username]="$timestamp"
      latest_commit_ids[$username]="$commit_id"
    fi
  done

  for username in "${(@ok)latest_commit_ids}"; do
    commit_id="${latest_commit_ids[$username]}"
    if ! recorded_hash="$(git rev-parse --verify --quiet --end-of-options "${commit_id}^{commit}")"; then
      unverified_runs+=("• ${username} recorded ${commit_id} at ${latest_timestamps[$username]}")
    elif [[ "$recorded_hash" == "$current_hash" ]]; then
      up_to_date_users+=("$username")
    else
      out_of_date_users_components+=("$username" "$commit_id" "${latest_timestamps[$username]}")
    fi
  done

  number_of_up_to_date_users=${#up_to_date_users}
  number_of_out_of_date_users=$(( ${#out_of_date_users_components} / 3 ))

  number_of_unverified_users=${#unverified_runs}

  if (( number_of_unverified_users > 0 )); then
    report "Up-to-date users: ${number_of_up_to_date_users}${NEWLINE}Out-of-date users: ${number_of_out_of_date_users}${NEWLINE}Users with unverified versions: ${number_of_unverified_users}"
  elif (( number_of_up_to_date_users == 0 && number_of_out_of_date_users == 0 )); then
    report "No successful GenoMac-user runs have been recorded."
  elif (( number_of_out_of_date_users == 0 )); then
    report "🎉 All users with recorded runs are up to date!"
  elif (( number_of_up_to_date_users == 0 )); then
    report "😭 All users with recorded runs are OUT OF DATE!"
  else
    report "Up-to-date users: ${number_of_up_to_date_users}${NEWLINE}Out-of-date users: ${number_of_out_of_date_users}"
  fi

  if (( number_of_up_to_date_users > 0 )); then
    report "Up-to-date users:"
    for username in "${up_to_date_users[@]}"; do
      report "• ${username}"
    done
  fi

  if (( number_of_out_of_date_users > 0 )); then
    report "Out-of-date users:"
    for (( i = 1; i <= ${#out_of_date_users_components}; i += 3 )); do
      username="${out_of_date_users_components[i]}"
      commit_id="${out_of_date_users_components[i + 1]}"
      timestamp="${out_of_date_users_components[i + 2]}"
      report "• ${username} ran ${commit_id} at ${timestamp}"
    done
  fi

  if (( number_of_unverified_users > 0 )); then
    report "Users with unverified versions:"
    for unverified_run in "${unverified_runs[@]}"; do
      report "$unverified_run"
    done
  fi

  report_end_phase_standard
}
