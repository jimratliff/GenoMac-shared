#!/usr/bin/env zsh

############### Helpers related to migrating state for GenoMac

# See “Bootstrap and maintenance operations in Project GenoMac and their corresponding
# families of states”: GenoMac-shared/docs/States_migration_operations.md
# https://github.com/jimratliff/GenoMac-shared/blob/main/docs/States_migration_operations.md

_migrate_states() {
  # Helper for migration of state(s) for either 'system' or 'user' scope.
  #
  # Takes two positional arguments followed by options in any order.
  #       $1: scope, either 'system' or 'user'
  #       $2: migration ID
  # --delete: One or more state names to delete, ending at the next option.
  # --run:    One function name to execute after any deletions.
  # --user:   One user name; only valid for user scope.
  #           If the actual $USER is different, the migration peacefully ends for that user.
  # At least one of --delete or --run is required.
  #
  # The migration ID is:
  # - a string that begins with MIGRATION_STATE_PREFIX ("MIGRATION_ID_")
  # - corresponds to a state within the scope $1
  # - is in 1:1 correspondence with a particular state migration for scope $1.
  #
  # Consider a particular *environment*, i.e., a combination of (a) a particular startup volume and
  # (b) a particular user account.
  #
  # A typical case of a migration is to, exactly once, delete one or more PERM_ states for the given
  # scope in every environment. (In more complex cases, a given function might be executed either
  # instead or in addition.)
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
  #       “never” (until a later migration) be repeated for this environment.
  #
  # This function is intended to be called by either migrate_system_states() or migrate_user_states()
  #
  # Usage:
  #   _migrate_states "user" "MIGRATION_ID_2026_03_11" --delete "$PERM_PREVIEW_BASE_TOOLBAR_HAS_BEEN_SPECIFIED"
  #
  # Migrations are to be specified in hypervisor.sh (a) after the repo has been tested for changes (and updated if
  # necessary) and (b) before calling `subdermis`.
  # If there are multiple migrations specified, they will be performed in the order they are listed. Typically, then,
  # new migrations should be *appended* to the list of migrations.
  # There is no rush to remove a migration from hypevisor.sh, because a migration will never to be repeated for the
  # same environment. That said, after it is clear that all environments have executed a given migration, it can be
  # pruned from the migration list as a housekeeping step.

  report_start_phase_standard

  local scope="$1"
  local migration_id="$2"

  local has_run=0
  local has_user=0
  local run_function=""
  local target_user=""

  local -a states_to_delete

  # Validate scope
  _validate_scope "$scope"

  # Validate that migration_id begins with $MIGRATION_STATE_PREFIX
  if [[ "$migration_id" != "${MIGRATION_STATE_PREFIX}"* ]]; then
    report_fail "migration_id (“${migration_id}”) must begin with '${MIGRATION_STATE_PREFIX}': '$migration_id'"
    return 1
  fi

  # Parse options
  if (( $# < 2 )); then
    report_fail "_migrate_states: scope and migration ID are required"
    return 1
  fi
  shift 2
  while (( $# > 0 )); do
    case "$1" in
      --delete)
        shift
        if (( $# == 0 )) || [[ -z "$1" || "$1" == --* ]]; then
          report_fail "_migrate_states: --delete requires at least one state name"
          return 1
        fi
        while (( $# > 0 )) && [[ "$1" != --* ]]; do
          states_to_delete+=("$1")
          shift
        done
        ;;
      --run)
        run_function=$(required_value_for_option "$1" "${2-}") || return 1
        has_run=1
        shift 2
        ;;
      --user)
        target_user=$(required_value_for_option "$1" "${2-}") || return 1
        has_user=1
        shift 2
        ;;
      *)
        report_fail "_migrate_states: unknown option: '$1'" >&2
        return 1
        ;;
    esac
  done

  if (( ${#states_to_delete[@]} == 0 && ! has_run )); then
    report_fail "_migrate_states: at least one of --delete or --run is required"
    return 1
  fi

  if (( has_user )) && [[ "$scope" == system ]]; then
    report_fail "_migrate_states: --user is only valid for user scope"
    return 1
  fi

  if (( has_user )) && [[ "$USER" != "$target_user" ]]; then
    report_to_log "Migration $migration_id skipped because it was specific to user $target_user"
    report_end_phase_standard
    return 0
  fi

  if _test_state "${migration_id}" "${scope}"; then
    report_action_taken "Skipping this migration (“${migration_id}”) because it was completed in the past"
    report_end_phase_standard
    return 0
  fi

  report_action_taken "Performing state migration ${migration_id}"

  if (( has_run )) && (( ! $+functions[$run_function] )); then
    report_fail "_migrate_states: --run function does not exist: '$run_function'"
    return 1
  fi

  # Execute deletions
  local state
  for state in "${states_to_delete[@]}"; do
    _delete_state "$state" "$scope"
  done

  # A failed function leaves the migration unmarked so it can be retried.
  if (( has_run )); then
    "$run_function" || return $?
  fi

  # Create state for this migration_ID so that the migration will never be executed again for this Mac-user combination
  _set_state "${migration_id}" "${scope}"

  report_end_phase_standard
}

function migrate_system_states() {
  # Migrates state(s) of the 'system' scope
  #
  # Takes a migration_id followed by --delete and/or --run (see _migrate_states).
  #
  # $1: the ID of a particular migration. This is a string that begins with $MIGRATION_STATE_PREFIX
  #     The migration ID itself refers to a state in the 'system' state space.
  #     If this state does not exist, the remainder of this function runs, at the end of which this
  #     state is created.
  #     If this state already exists, then this migration had already been completed, and this function
  #     exits normally.
  #
  # --delete: Optional when --run is supplied; followed by one or more strings referring to
  #           state within the 'system' state space.
  #           These are the states to be deleted as part of this migration.
  # --run:    Function to execute after any deletions.
  #
  # Usage:
  #   migrate_system_states "MIGRATION_ID_2026_03_11" --delete "$PERM_MAC_NAMES_AND_LOGIN_WINDOW_MESSAGE_OBTAINED"

  report_start_phase_standard

  _migrate_states "system" "$@"

  report_end_phase_standard
}

function migrate_user_states() {
  # Migrates state(s) of the 'user' scope
  # --user optionally restricts this migration to the named user.
  #
  # Takes a migration_id followed by --delete and/or --run (see _migrate_states).
  #
  # $1: the ID of a particular migration. This is a string that begins with $MIGRATION_STATE_PREFIX
  #     The migration ID itself refers to a state in the 'user' state space.
  #     If this state does not exist, the remainder of this function runs, at the end of which this
  #     state is created.
  #     If this state already exists, then this migration had already been completed, and this function
  #     exits normally.
  #
  # --delete: Optional when --run is supplied; followed by one or more strings referring to
  #           state within the 'user' state space.
  #           These are the states to be deleted as part of this migration.
  # --run:    Function to execute after any deletions.
  #
  # Usage:
  #   migrate_user_states "MIGRATION_ID_2026_03_11" --delete "$PERM_PREVIEW_BASE_TOOLBAR_HAS_BEEN_SPECIFIED"

  report_start_phase_standard

  _migrate_states "user" "$@"

  report_end_phase_standard
}
