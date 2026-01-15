############### Helpers related to the Hypervisor

# Relies upon:
#   - helpers-reporting.sh
#   - helpers-state.sh
#
#   Environment variables:
#   - GMU_HYPERVISOR_HOW_TO_RESTART_STRING
#   - GENOMAC_STATE_FILE_EXTENSION
#   - GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY

function _run_based_on_state() {
  # Executes a function based on whether a state variable is set or not.
  # Core helper that powers both _run_if_not_already_done and _run_if_state.
  #
  # Usage:
  #   _run_based_on_state [--negate-state] [--force-logout] <state_var> <func_to_run> <skip_message>
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --negate-state  Optional. If present, runs func_to_run when state is NOT set.
  #                   If absent, runs func_to_run when state IS set.
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after execution.
  #   state_var       The state variable to check (e.g., $GMU_SESH_...).
  #   func_to_run     Name of the function to execute if condition is met.
  #   skip_message    Message to display if condition is not met and action is skipped.
  #
  # If func_to_run is executed, then state_var is SET. (This has effect only when --negate-state,
  # because when --negate-state is absent, func_to_run is executed only when state_var is already set.)

  report_start_phase_standard

  local negate_state=false
  local force_logout=false
  local positional=()
  
  # Parse arguments - flags can appear anywhere
  while (( $# > 0 )); do
    case "$1" in
      --negate-state)
        negate_state=true
        shift
        ;;
      --force-logout)
        force_logout=true
        shift
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  # Validate positional argument count
  if (( ${#positional[@]} != 3 )); then
    report_fail "Error: expected 3 positional arguments (state_var, func_to_run, skip_message), got ${#positional[@]}"
    return 1
  fi

  local state_var="${positional[1]}"
  local func_to_run="${positional[2]}"
  local skip_message="${positional[3]}"

  report "Entering _run_based_on_state: function_to_run:${func_to_run} state_var:${state_var}"

  # Determine whether to run based on state and negation flag
  local should_run=false
  if $negate_state; then
    # Run if state is NOT set
    test_genomac_user_state "$state_var" || should_run=true
  else
    # Run if state IS set
    test_genomac_user_state "$state_var" && should_run=true
  fi

  if $should_run; then
    $func_to_run
    set_genomac_user_state "$state_var"
    if $force_logout; then
      hypervisor_force_logout
    fi
  else
    report_action_taken "$skip_message"
  fi

  report_end_phase "Leaving _run_based_on_state: function_to_run:${func_to_run} state_var:${state_var}"
}

function _run_if_not_already_done() {
  # Executes a function if a completion state variable is false (absent) indicating a task hasn't been done yet.
  # Sets the state variable after successful execution.
  #
  # Usage:
  #   _run_if_not_already_done [--force-logout] <state_var> <func_to_run> <skip_message>
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after setting state.
  #   state_var       The state variable to check and set (e.g., $GMU_SESH_...).
  #   func_to_run     Name of the function to execute if state is not set.
  #   skip_message    Message to display if state is already set and action is skipped.
  #
  # Usage examples:
  #   _run_if_not_already_done "$PERM_INTRO_QUESTIONS_ASKED_AND_ANSWERED" \
  #     ask_initial_questions \
  #     "Skipping introductory questions, because you've answered them in the past."
  #   
  #   _run_if_not_already_done --force-logout "$GMU_SESH_DOTFILES_HAVE_BEEN_STOWED" \
  #     stow_dotfiles \
  #     "Skipping stowing dotfiles, because you've already stowed them during this session."

  _run_based_on_state --negate-state "$@"
}

function _run_if_state() {
  # Executes a function if a completion state variable is true (present) indicating a task has been done.
  #
  # Usage:
  #   _run_if_state [--force-logout] <state_var> <func_to_run> <skip_message>
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after execution.
  #   state_var       The state variable to check (e.g., $GMU_SESH_...).
  #   func_to_run     Name of the function to execute if state is set.
  #   skip_message    Message to display if state is not set and action is skipped.

  _run_based_on_state "$@"
}

function hypervisor_force_logout() {
  echo ""
  echo "ℹ️  You will be logged out semi-automatically to fully internalize all the work we’ve done."
  echo "   Please log back in."
  echo "   $GMU_HYPERVISOR_HOW_TO_RESTART_STRING."
  echo ""

  dump_accumulated_warnings_failures
  force_user_logout
}
