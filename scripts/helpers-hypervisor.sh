#!/usr/bin/env zsh

############### Helpers related to the Hypervisor

# Relies upon:
#   - helpers-reporting.sh
#   - helpers-state.sh
#
#   Environment variables:
#   - HYPERVISOR_HOW_TO_RESTART_STRING
#   - GENOMAC_STATE_FILE_EXTENSION
#   - GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY

function _run_based_on_state() {
  # Executes a function (with no arguments) based on whether a state variable is set.
  # Core helper that powers both _run_if_not_already_done and _run_if_state and run_if_user_state.
  #
  # Usage:
  #   _run_based_on_state [--negate-state] [--force-logout] <scope> <state_var>  <func_to_run> <skip_message>
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --negate-state  Optional. If present, runs func_to_run when state is NOT set.
  #                   If absent, runs func_to_run when state IS set.
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after execution.
  #   scope           Either 'user' or 'system'.
  #   state_var       The state variable to check (e.g., $GMU_SESH_...).
  #   func_to_run     Name of the function to execute if condition is met.
  #   skip_message    Message to display if condition is not met and action is skipped.
  #
  # If func_to_run is executed, then state_var is SET. (This has effect only when --negate-state
  # because when --negate-state is absent, func_to_run is executed only when state_var is already set.)
  # Legacy wrapper. Positional order: scope, state_var, func_to_run, skip_message
  # New function expects:              scope, state_var, skip_message, func_to_run

  local flags=()
  local positional=()

  while (( $# > 0 )); do
    case "$1" in
      --negate-state|--force-logout) flags+=("$1"); shift ;;
      *)                             positional+=("$1"); shift ;;
    esac
  done

  if (( ${#positional[@]} != 4 )); then
    report_fail "Error: expected 4 positional arguments (scope, state_var, func_to_run, skip_message), got ${#positional[@]}"
    return 1
  fi

  # Reorder: swap func_to_run and skip_message
  _run_func_and_args_based_on_state "${flags[@]}" \
    "${positional[1]}" "${positional[2]}" "${positional[4]}" "${positional[3]}"
}

function _run_func_and_args_based_on_state() {
  # Executes a function, optionally with arguments, based on whether a state variable is set.
  # Core helper that powers both _run_func_and_args_if_not_already_done and _run_func_and_args_if_state.
  #
  # Usage:
  #   _run_func_and_args_based_on_state [--negate-state] [--force-logout] <scope> <state_var> <skip_message> <func_to_run> [args...]
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --negate-state  Optional. If present, runs func_to_run when state is NOT set.
  #                   If absent, runs func_to_run when state IS set.
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after execution.
  #   scope           Either 'user' or 'system'.
  #   state_var       The state variable to check (e.g., $GMU_SESH_...).
  #   skip_message    Message to display if condition is not met and action is skipped.
  #   func_to_run     Name of the function to execute if condition is met.
  #   [args, …]       Optional arguments to func_to_run
  #
  # If func_to_run is executed, then state_var is SET. (This has effect only when --negate-state
  # because when --negate-state is absent, func_to_run is executed only when state_var is already set.)
  #
  # This is a refactor of _run_based_on_state, which didn’t accept arguments to func_to_run, that required a breaking
  # reordering of parameters: skip_message moves before func_to_run to allow variable-length args.

  local negate_state=false
  local force_logout=false
  local positional=()
  local func_desc

  while (( $# > 0 )); do
    case "$1" in
      --negate-state) negate_state=true; shift ;;
      --force-logout) force_logout=true; shift ;;
      *)              positional+=("$1"); shift ;;
    esac
  done

  if (( ${#positional[@]} < 4 )); then
    report_fail "Error: expected at least 4 positional arguments (scope, state_var, skip_message, func_to_run [args...]), got ${#positional[@]}"
    return 1
  fi

  local scope="${positional[1]}"
  local state_var="${positional[2]}"
  local skip_message="${positional[3]}"
  local func_to_run="${positional[4]}"
  local func_args=("${positional[@]:4}")
  _validate_scope "$scope" || return 1

  local should_run=false
  if $negate_state; then
    _test_state "$state_var" "$scope" || should_run=true
  else
    _test_state "$state_var" "$scope" && should_run=true
  fi

  if $should_run; then
    report_action_taken "Running $func_to_run"
    $func_to_run "${func_args[@]}"
    func_desc="$func_to_run${func_args:+ ${func_args[*]}}"
    report_action_taken "Back from ${func_desc}.${NEWLINE}Setting $state_var"
    _set_state "$state_var" "$scope"
    if $force_logout; then
      hypervisor_force_logout
    fi
  else
    report_action_taken "$skip_message"
  fi
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

  # report_start_phase_standard "Entering _run_if_not_already_done $*"

  _run_based_on_state --negate-state "$@"

  # report_end_phase "Leaving _run_if_not_already_done $*"
}

function _run_func_and_args_if_not_already_done() {
  # Executes a function, optionally with arguments, if a completion state variable is false (absent) indicating
  # a task hasn't been done yet.
  # Sets the state variable after successful execution
  #
  # Flags can appear in any position.
  # Like _run_if_not_already_done, but func_to_run can receive arguments.
  # skip_message moves before func_to_run to allow variable-length args.
  #
  # Usage:
  #   _run_func_and_args_if_not_already_done [--force-logout] <state_var> <skip_message> <func_to_run> [args...]
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after setting state.
  #   state_var       The state variable to check and set (e.g., $GMU_SESH_...).
  #   skip_message    Message to display if state is already set and action is skipped.
  #   func_to_run     Name of the function to execute if state is not set.
  #   [args...]       Optional arguments to pass to func_to_run.

  _run_func_and_args_based_on_state --negate-state "$@"
}

function hypervisor_force_logout() {
  echo ""
  echo "ℹ️  You will be logged out semi-automatically to fully internalize all the work we’ve done."
  echo "   Please log back in."
  echo "   $HYPERVISOR_HOW_TO_RESTART_STRING"
  echo ""

  dump_accumulated_warnings_failures
  force_user_logout
}

############################## Scope-specific wrappers
############### Scope: user

function run_if_user_has_not_done() {
  # Executes a function if a user completion state variable is false (absent) indicating a task hasn't been done yet.
  # Sets the state variable after successful execution.
  #
  # Usage:
  #   run_if_user_has_not_done [--force-logout] <state_var> <func_to_run> <skip_message>
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after setting state.
  #   state_var       The user state variable to check and set (e.g., $SESH_...).
  #   func_to_run     Name of the function to execute if state is not set.
  #   skip_message    Message to display if state is already set and action is skipped.
  #
  # Usage examples:
  #   run_if_user_has_not_done "$PERM_INTRO_QUESTIONS_ASKED_AND_ANSWERED" \
  #     ask_initial_questions \
  #     "Skipping introductory questions, because you've answered them in the past."
  #   
  #   run_if_user_has_not_done --force-logout "$GMU_SESH_DOTFILES_HAVE_BEEN_STOWED" \
  #     stow_dotfiles \
  #     "Skipping stowing dotfiles, because you've already stowed them during this session."

  # report_start_phase "Entering run_if_user_has_not_done $*"

  _run_based_on_state 'user' --negate-state "$@"

  # report_end_phase "Leaving run_if_user_has_not_done $*"
}

function run_if_user_state() {
  # Executes a function if a user completion state variable is true (present) indicating a task has been done.
  #
  # Usage:
  #   run_if_user_state [--force-logout] <state_var> <func_to_run> <skip_message>
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after execution.
  #   state_var       The state variable to check (e.g., $GMU_SESH_...).
  #   func_to_run     Name of the function to execute if state is set.
  #   skip_message    Message to display if state is not set and action is skipped.

  # report_start_phase "Entering run_if_user_state $*"

  _run_based_on_state 'user' "$@"

  # report_end_phase "Leaving run_if_user_state $*"
}

function run_func_and_args_if_user_has_not_done() {
  # Executes a function if a user completion state variable is false (absent) indicating a task hasn't been done yet.
  # Sets the state variable after successful execution.
  #
  # Usage:
  #   run_func_and_args_if_user_has_not_done [--force-logout] <state_var>  <skip_message> <func_to_run> [args…]
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after setting state.
  #   state_var       The user state variable to check and set (e.g., $SESH_...).
  #   skip_message    Message to display if state is already set and action is skipped.
  #   func_to_run     Name of the function to execute if state is not set.
  #   [args…]         Optional arguments to pass to func_to_run
  #
  # Usage examples:
  #   run_func_and_args_if_user_has_not_done "$PERM_INTRO_QUESTIONS_ASKED_AND_ANSWERED" \
  #     "Skipping introductory questions, because you've answered them in the past." \
  #     ask_initial_questions \
  #     "value for some argument not yet implemented"

  _run_func_and_args_based_on_state 'user' --negate-state "$@"
}

function run_func_and_args_if_user_state() {
  # Executes a function if a user completion state variable is true (present) indicating a task has been done.
  #
  # Usage:
  #   run_func_and_args_if_user_state [--force-logout] <state_var> <skip_message> <func_to_run> [args…]
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after execution.
  #   state_var       The state variable to check (e.g., $GMU_SESH_...).
  #   skip_message    Message to display if state is not set and action is skipped.
  #   func_to_run     Name of the function to execute if state is set.
  #   [args…]         Optional arguments to pass to func_to_run

  _run_based_on_state 'user' "$@"
}


############### Scope: system

function run_if_system_has_not_done() {
  # Executes a function if a system completion state variable is false (absent) indicating a task hasn't been done yet.
  # Sets the state variable after successful execution.
  #
  # Usage:
  #   run_if_system_has_not_done [--force-logout] <state_var> <func_to_run> <skip_message>
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after setting state.
  #   state_var       The system state variable to check and set (e.g., $SESH_...).
  #   func_to_run     Name of the function to execute if state is not set.
  #   skip_message    Message to display if state is already set and action is skipped.
  #
  # Usage examples:
  #   run_if_system_has_not_done "$PERM_INTRO_QUESTIONS_ASKED_AND_ANSWERED" \
  #     ask_initial_questions \
  #     "Skipping introductory questions, because you've answered them in the past."
  #   
  #   run_if_system_has_not_done --force-logout "$SESH_DOTFILES_HAVE_BEEN_STOWED" \
  #     stow_dotfiles \
  #     "Skipping stowing dotfiles, because you've already stowed them during this session."

  # report_start_phase "Entering run_if_system_has_not_done $*"

  _run_based_on_state 'system' --negate-state "$@"

  # report_end_phase "Leaving run_if_system_has_not_done $*"
}

function run_if_system_state() {
  # Executes a function if a system completion state variable is true (present) indicating a task has been done.
  #
  # Usage:
  #   run_if_system_state [--force-logout] <state_var> <func_to_run> <skip_message>
  #
  # Flags can appear in any position.
  #
  # Parameters:
  #   --force-logout  Optional. If present, calls hypervisor_force_logout after execution.
  #   state_var       The state variable to check (e.g., $SESH_...).
  #   func_to_run     Name of the function to execute if state is set.
  #   skip_message    Message to display if state is not set and action is skipped.

  # report_start_phase "Entering run_if_system_state $*"

  _run_based_on_state 'system' "$@"

  # report_end_phase "Leaving run_if_system_state $*"
}

function output_hypervisor_welcome_banner() {
  # Takes 1 argument: scope, either 'system' or 'user', corresponding to GenoMac-system
  # or GenoMac-user, respectively
  local scope="$1"
  local welcome_prefix
  if _test_state "$SESH_SESSION_HAS_STARTED" "$scope" ; then
    welcome_prefix="Welcome back"
  else
    welcome_prefix="Welcome"
  fi

  welcome_message="${welcome_prefix} to the GenoMac-${scope} Hypervisor!"
  print_banner_text "${welcome_message}"
  report "$HYPERVISOR_HOW_TO_RESTART_STRING"
}

function output_hypervisor_departure_banner() {
  # Takes 1 argument: scope, either 'system' or 'user', corresponding to GenoMac-system
  # or GenoMac-user, respectively
  local scope="$1"
  departure_message="TTFN!"
  print_banner_text "${departure_message}"
}


