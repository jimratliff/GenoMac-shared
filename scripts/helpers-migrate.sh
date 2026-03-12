#!/usr/bin/env zsh

############### Helpers related to migrating state for GenoMac

_migrate_states() {
  # Helper for migration of state(s) for either 'system' or 'user' scope.
  #
  # Takes two positional arguments and one option followed by a sequence of strings.
  #       $1: scope, either 'system' or 'user'
  #       $2: migration ID
  # --delete: Must follow the two positional arguments.
  #           Currently, this is mandatory and the only available option.
  #           It must be followed by a sequence of one or more strings, each of which refers to a
  #           state within the state space specified by scope ($1) that should be deleted by this migration.
  #
  # The migration ID is:
  # - a string that begins with MIGRATION_STATE_PREFIX ("MIGRATION_ID_")
  # - corresponds to a state within the scope $1
  # - is in 1:1 correspondence with a particular state migration for scope $1.
  #
  # Consider a particular *environment*, i.e., a combination of (a) a particular startup volume and 
  # (b) a particular user account.
  #
  # The typical case of a migration is to, exactly once, delete one or more PERM_ states for the given 
  # scope in every environment.
  #
  # For example, the first time GenoMac-user’s Hypervisor is executed within a given environment,
  # the base toolbar configuration for Preview.app is implemented, and the user state
  # $PERM_PREVIEW_BASE_TOOLBAR_HAS_BEEN_SPECIFIED is set to signal to subsequent runs of Hypervisor that
  # this toolbar-setting bootstrap step has been completed for this environment.
  #
  # If, at some later time, it is decided that each environment should reset the toolbar of 
  # Preview.app to a different base configuration, a migration (identified by some state, 
  # e.g., MIGRATION_ID_2026_03_11) is specified such that, when executed by an environment:
  # - Checks whether the migration has already been performed for this environment (by checking whether
  #   the state MIGRATION_ID_2026_03_11 exists)
  #   - If the state MIGRATION_ID_2026_03_11 exists, then the migration has already been performed for this environment,
  #     and execution of this migration for this environment ends.
  #   - If the state MIGRATION_ID_2026_03_11 doesn’t exist, then the migration has not already been performed for this
  #     environment. In that case:
  #     - the state $PERM_PREVIEW_BASE_TOOLBAR_HAS_BEEN_SPECIFIED is deleted (so that, on the next execution of 
  #       GenoMac-user’s Hypervisor, the toolbar for Preview.app will be reset to the most-recently specified 
  #       configuration)
  #     - the migration state MIGRATION_ID_2026_03_11 will be set for this environment so that this migration will
  #       never be repeated for this environment.
  #
  # This function is intended to be called by either migrate_system_states() or migrate_user_states()
  #
  # Usage:
  #   _migrate_states "user" "MIGRATION_ID_2026_03_11" "$PERM_PREVIEW_BASE_TOOLBAR_HAS_BEEN_SPECIFIED"
  
  report_start_phase_standard
  
  local scope="$1"
  local migration_id="$2"
  local -a states_to_delete

  # Validate scope
  _validate_scope "$scope" || return 1

  # Validate that migration_id begins with $MIGRATION_STATE_PREFIX
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

function migrate_system_states() {
  # Migrates state(s) of the 'system' scope
  #
  # Takes one positional argument (migration_id) and one option (--delete) followed by a sequence of strings.
  #
  # $1: the ID of a particular migration. This is a string that begins with MIGRATION_STATE_PREFIX
  #     The migration ID itself refers to a state in the 'system' state space.
  #     If this state does not exist, the remainder of this function runs, at the end of which this 
  #     state is created.
  #     If this state already exists, then this migration had already been completed, and this function
  #     exits normally.
  # --delete: Currently, this is mandatory and the only available option.
  #           It must be followed by a sequence of one or more strings, each of which refers to a
  #           state within the 'system' state space.
  #           These are the states to be deleted as part of this migration.
  
  report_start_phase_standard
  
  _migrate_states "system" "$@"
  
  report_end_phase_standard
}

function migrate_user_states() {
  # Migrates state(s) of the 'user' scope
  #
  # Takes one positional argument (migration_id) and one option (--delete) followed by a sequence of strings.
  #
  # $1: the ID of a particular migration. This is a string that begins with MIGRATION_STATE_PREFIX
  #     The migration ID itself refers to a state in the 'user' state space.
  #     If this state does not exist, the remainder of this function runs, at the end of which this 
  #     state is created.
  #     If this state already exists, then this migration had already been completed, and this function
  #     exits normally.
  # --delete: Currently, this is mandatory and the only available option.
  #           It must be followed by a sequence of one or more strings, each of which refers to a
  #           state within the 'user' state space.
  #           These are the states to be deleted as part of this migration.
  
  report_start_phase_standard
  
  _migrate_states "user" "$@"
  
  report_end_phase_standard
}
