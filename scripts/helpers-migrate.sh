#!/usr/bin/env zsh

############### Helpers related to migrating state for GenoMac

_migrate_states() {
  report_start_phase_standard
  local scope="$1"
  local migration_id="$2"
  local -a states_to_delete

  # Validate scope
  if ! _validate_scope "$scope"; then
    report_fail "migrate_states: invalid scope: '${scope}'"
    return 1
  fi

  # Validate migration_id begins with $MIGRATION_STATE_PREFIX
  if [[ "$migration_id" != "${MIGRATION_STATE_PREFIX}"* ]]; then
    report_fail "migration_id (${migration_id}) must begin with '${MIGRATION_STATE_PREFIX}': '$migration_id'"
    return 1
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

  report_end_phase_standard
}
