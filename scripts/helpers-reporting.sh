#!/usr/bin/env zs

############### Helpers related to reporting events to the executing user

# Relies upon:
#   Environment variables:
#     GENOMAC_ALERT_LOG

function define_colors_and_symbols() {
  # Example usage
  # Each %b and %s maps to a successive argument to printf
  # printf "%b[ok]%b %s\n" "$COLOR_GREEN" "$COLOR_RESET" "some message"

  ESC_SEQ="\033["
  
  COLOR_RESET="${ESC_SEQ}0m"
  
  COLOR_BLACK="${ESC_SEQ}30;01m"
  COLOR_RED="${ESC_SEQ}31;01m"
  COLOR_GREEN="${ESC_SEQ}32;01m"
  COLOR_YELLOW="${ESC_SEQ}33;01m"
  COLOR_BLUE="${ESC_SEQ}34;01m"
  COLOR_MAGENTA="${ESC_SEQ}35;01m"
  COLOR_CYAN="${ESC_SEQ}36;01m"
  COLOR_WHITE="${ESC_SEQ}37;01m"
  
  COLOR_QUESTION="$COLOR_MAGENTA"
  COLOR_REPORT="$COLOR_BLUE"
  COLOR_ADJUST_SETTING="$COLOR_CYAN"
  COLOR_ACTION_TAKEN="$COLOR_GREEN"
  COLOR_WARNING="$COLOR_YELLOW"
  COLOR_ERROR="$COLOR_RED"
  COLOR_SUCCESS="$COLOR_GREEN"
  COLOR_KILLED="$COLOR_RED"
  
  SYMBOL_SUCCESS="✅ "
  SYMBOL_FAILURE="❌ "
  SYMBOL_QUESTION="❓ "
  SYMBOL_ADJUST_SETTING="⚙️  "
  SYMBOL_KILLED="☠️ "
  SYMBOL_ACTION_TAKEN="🪚 "
  SYMBOL_WARNING="🚨 "
}

function success_or_not() {
  # Print SYMBOL_SUCCESS if success (based on error code); otherwise SYMBOL_FAILURE
  if [[ $? -eq 0 ]]; then
    printf " ${SYMBOL_SUCCESS}\n"
  else
    printf "\n${SYMBOL_FAILURE}\n"
  fi
}

function report() {
  # Output supplied line of text in a distinctive color.
  printf "%b%s%b\n" "$COLOR_REPORT" "$1" "$COLOR_RESET"
}

function report_fail() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_FAILURE.
  local message="$1"
  printf "%b%s%s%b\n" "$COLOR_ERROR" "$SYMBOL_FAILURE" "$message" "$COLOR_RESET"
  
  # Also append a plain-text version to the alert log, if it's set.
  if [[ -n "${GENOMAC_ALERT_LOG-}" ]]; then
    printf 'FAIL: %s\n' "$message" >>"$GENOMAC_ALERT_LOG"
  fi
}

function report_success() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_SUCCESS.
  printf "%b%s%s%b\n" "$COLOR_SUCCESS" "$SYMBOL_SUCCESS" "$1" "$COLOR_RESET"
}

function report_warning() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_WARNING.
  local message="$1"
  printf "%b%s%s%b\n" "$COLOR_WARNING" "$SYMBOL_WARNING" "$message" "$COLOR_RESET"

  # Also append a plain-text version to the alert log, if it's set.
  if [[ -n "${GENOMAC_ALERT_LOG-}" ]]; then
    printf 'WARN: %s\n' "$message" >>"$GENOMAC_ALERT_LOG"
  fi
}

function report_adjust_setting() {
  # Output supplied line of text in a distinctive color, prefaced by "$SYMBOL_ADJUST_SETTING.
  # It is intentional to NOT have a newline. This will be supplied by success().
  printf "%b%s%s%b" "$COLOR_ADJUST_SETTING" "$SYMBOL_ADJUST_SETTING" "$1" "$COLOR_RESET"
}

function report_action_taken() {
  # Output supplied line of text in a distinctive color, prefaced by "$SYMBOL_ADJUST_SETTING.
  printf "%b%s%s%b\n" "$COLOR_ACTION_TAKEN" "$SYMBOL_ACTION_TAKEN" "$1" "$COLOR_RESET"
}

function report_about_to_kill_app() {
  # Takes `app` as argument
  # Outputs message that the app was killed.
  printf "%b%s %s is being killed (if necessary) %b" "$COLOR_KILLED" "$SYMBOL_KILLED" "$1" "$COLOR_RESET"
}

dump_accumulated_warnings_failures() {
  # Prints all assumulated warnings and/or failures from GENOMAC_ALERT_LOG
  
  # If we somehow never initialized, bail quietly.
  [[ -z "${GENOMAC_ALERT_LOG-}" ]] && return 0
  [[ ! -e "$GENOMAC_ALERT_LOG" ]] && return 0

  if [[ ! -s "$GENOMAC_ALERT_LOG" ]]; then
    echo "✅ No GenoMac warnings or failures detected in this run." >&2
  else
    echo >&2
    echo "═════════ GenoMac warnings / failures (summary) ═════════" >&2
    cat "$GENOMAC_ALERT_LOG" >&2
    echo "════════════════════════ end summary ════════════════════" >&2
    echo "↑ Scroll back in the log to see these in context." >&2
  fi

  rm -f -- "$GENOMAC_ALERT_LOG"
}

################################################################################
# PHASE REPORTING HELPERS
#
# The below four functions provide a consistent way to mark in the terminal output 
# the start and end of output-intensive or semantically distinct “phases” within the
# bootstrap process.
#
# They emit color-coded separator blocks, with textual content like:
#
#   ********************************************************************************
#   Entering: configure_firewall
#   ********************************************************************************
#
# USAGE GUIDELINES:
#
# ⏺ report_start_phase
# ⏺ report_end_phase
#
#   Use these when you want fine-grained control.
#
#   • Zero arguments → print "Entering phase" or "Leaving phase", respectively
#   • One argument   → print the argument exactly as a message line (e.g. emoji + text)
#   • Two arguments  → interpret as function name and file name; format as:
#       Entering: func_name (file: /path/to/file)
#     If the second argument is "-", the file-name clause is omitted:
#       Entering: func_name
#
# ⏺ report_start_phase_standard
# ⏺ report_end_phase_standard
#
#   Use these inside functions when you want standard behavior without manual quoting
#   or boilerplate. These extract (a) the function name from the call stack and,
#   (b) if available, the file name using `functions -t`.
#
#   - If the file name is unavailable, the file-name clause is silently omitted.
#   - These accept no arguments — just call them:
#
#       function configure_firewall() {
#         report_start_phase_standard
#         # ...
#         report_end_phase_standard
#       }
#
#   This is the recommended style for all GenoMac bootstrap functions.
#
################################################################################

function report_start_phase() {
  printf "\n%b%s%b\n" "$COLOR_MAGENTA" "********************************************************************************" "$COLOR_RESET"

  if (( $# == 2 )); then
    if [[ "$2" == "-" ]]; then
      printf "%bEntering: %s%b\n" "$COLOR_MAGENTA" "$1" "$COLOR_RESET"
    else
      printf "%bEntering: %s (file: %s)%b\n" "$COLOR_MAGENTA" "$1" "$2" "$COLOR_RESET"
    fi
  elif (( $# == 1 )); then
    printf "%b%s%b\n" "$COLOR_MAGENTA" "$1" "$COLOR_RESET"
  else
    printf "%bEntering phase%b\n" "$COLOR_MAGENTA" "$COLOR_RESET"
  fi

  printf "%b%s%b\n\n" "$COLOR_MAGENTA" "********************************************************************************" "$COLOR_RESET"
}

function report_end_phase() {
  printf "\n%b%s%b\n" "$COLOR_YELLOW" "--------------------------------------------------------------------------------" "$COLOR_RESET"

  if (( $# == 2 )); then
    if [[ "$2" == "-" ]]; then
      printf "%bLeaving: %s%b\n" "$COLOR_YELLOW" "$1" "$COLOR_RESET"
    else
      printf "%bLeaving: %s (file: %s)%b\n" "$COLOR_YELLOW" "$1" "$2" "$COLOR_RESET"
    fi
  elif (( $# == 1 )); then
    printf "%b%s%b\n" "$COLOR_YELLOW" "$1" "$COLOR_RESET"
  else
    printf "%bLeaving phase%b\n" "$COLOR_YELLOW" "$COLOR_RESET"
  fi

  printf "%b%s%b\n\n" "$COLOR_YELLOW" "--------------------------------------------------------------------------------" "$COLOR_RESET"
}

function report_start_phase_standard() {
  local fn_name="${funcstack[2]}"
  local fn_file="$(functions -t "$fn_name" 2>/dev/null)"
  [[ -n "$fn_file" && "$fn_file" == "$HOME"* ]] && fn_file="~${fn_file#$HOME}"

  [[ -z "$fn_file" ]] && fn_file="-"  # Sentinel: no file

  report_start_phase "$fn_name" "$fn_file"
}

function report_end_phase_standard() {
  local fn_name="${funcstack[2]}"
  local fn_file="$(functions -t "$fn_name" 2>/dev/null)"
  [[ -n "$fn_file" && "$fn_file" == "$HOME"* ]] && fn_file="~${fn_file#$HOME}"

  [[ -z "$fn_file" ]] && fn_file="-"  # Sentinel: no file

  report_end_phase "$fn_name" "$fn_file"
}
