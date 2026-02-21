#!/usr/bin/env zsh

############### Helpers related to migrating state for GenoMac

_migrate_states() {
  # Helper for migration of state(s) for either 'system' or 'user' scope.
  #
  # Takes two positional arguments and one option followed by a sequence of strings.
  #
  # $1: scope, either 'system' or 'user'
  # $2: the ID of a particular migration. This is a string that begins with MIGRATION_STATE_PREFIX
  #     The migration ID itself refers to a state in the state spaced specified by scope ($1).
  #     If this state does not exist, the remainder of this function runs, at the end of which this 
  #     state is created.
  #     If this state already exists, then this migration had already been completed, and this function
  #     exits normally.
  # --delete: Currently, this is mandatory and the only available option.
  #           It must be followed by a sequence of one or more strings, each of which refers to a
  #           state within the state space specified by scope ($1).
  #           These are the states to be deleted as part of this migration.
  
  report_start_phase_standard
  local scope="$1"
  local migration_id="$2"
  local -a states_to_delete

  # Validate scope
  _validate_scope "$scope" || return 1

  # Validate migration_id begins with $MIGRATION_STATE_PREFIX
  if [[ "$migration_id" != "${MIGRATION_STATE_PREFIX}"* ]]; then
    report_fail "migration_id (“${migration_id}”) must begin with '${MIGRATION_STATE_PREFIX}': '$migration_id'"
    return 1
  fi

  if _test_state "${migration_id}" "${scope}"; then
    report_action_taken "Skipping this migration (“${migration_id}”) because it was completed in the past"
    report_end_phase_standard
    return 0
  fi

  # Parse options
  shift 2
  while (( $# > 0 )); do
    case "$1" in
      --delete)
        shift
        while (( $# > 0 )) && [[ "$1" != --* ]]; do
          states_to_delete+=("$1")
          shift
        done
        ;;
      *)
        echo "migrate_states: unknown option: '$1'" >&2
        return 1
        ;;
    esac
  done

  # Execute deletions
  local state
  for state in "${states_to_delete[@]}"; do
    _delete_state "$state" "$scope"
  done

  # Create state for this migration_ID so that the migration will never be executed again for this Mac-user combination
  _set_state "${migration_id}" "${scope}"
  
  report_end_phase_standard
}


