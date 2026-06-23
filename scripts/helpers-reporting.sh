#!/usr/bin/env zsh

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
  SYMBOL_HIGHLIGHT="‼️ "
}

function print_banner_text() {
  # Print banner text using figlet if available, otherwise fall back to echo
  
  local font
  local width="100"
  local text="$1"

  local FONT_DEFAULT="standard"
  local FONT_BANNER="banner"
  local FONT_BIG="big"
  local FONT_MINI="mini"

  local colorfull_banner
  local colorless_banner

  # Un-comment exactly one of the following font assignments
  font="$FONT_DEFAULT"
  # font="$FONT_BIG"
  # font="$FONT_BANNER"
  # font="$FONT_MINI"

  # Test whether figlet and lolcat is in PATH
  if command -v figlet &>/dev/null && command -v lolcat &>/dev/null; then
    colorless_banner "$(figlet -k -w "$width" -f "$font" "$text")"
    colorfull_banner "$(figlet -k -w "$width" -f "$font" "$text" | lolcat)"

    # Print with lolcat to terminal
    _report --message "$colorfull_banner" --no-report-log

    # Print without lolcal to report-log file
    _report --message "$colorless_banner" --no-terminal
  else
    report_warning "Either/both figlet and lolcat not found in PATH ⇒ Printing vanilla banner."
    report "=== $text ==="
  fi
}

function success_or_not() {
  # Print SYMBOL_SUCCESS if success (based on error code); otherwise SYMBOL_FAILURE
  if [[ $? -eq 0 ]]; then
    printf " ${SYMBOL_SUCCESS}\n" >&2
  else
    # printf "\n${SYMBOL_FAILURE}\n" >&2
    success_or_not_NOT
  fi
}

function success_or_not_NOT() {
  printf "\n${SYMBOL_FAILURE}\n" >&2
}

function report() {
  # Output supplied line of text in a distinctive color ($COLOR_REPORT by default).
  local message
  message="${1?MISSING message}"
  _report --message "$message"
}

function report_warning() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_WARNING.
  # Mark it to be also regurgitated in an end-of-Hypervisor-run summary.
  local message
  message="${1?MISSING message}"

  _report \
    --leading-format "$COLOR_WARNING" \
    --message "${SYMBOL_WARNING} ${message}" \
    --alert
}

function report_highlight() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_WARNING.
  # Mark it to be also regurgitated in an end-of-Hypervisor-run summary.
  local message
  message="${1?MISSING message}"

  _report \
    --leading-format "$COLOR_REPORT" \
    --message "${SYMBOL_WARNING} ${message}" \
    --alert
}

function report_fail() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_FAILURE.
  local message
  message="${1?MISSING message}"

  _report \
    --leading-format "$COLOR_ERROR" \
    --message "${SYMBOL_FAILURE} ${message}" \
    --alert
}

function report_success() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_SUCCESS.
  local message
  message="${1?MISSING message}"

  _report \
    --leading-format "$COLOR_SUCCESS" \
    --message "${SYMBOL_SUCCESS} ${message}"
}

function report_adjust_setting() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_ADJUST_SETTING.
  local message
  message="${1?MISSING message}"

  _report \
    --leading-format "$COLOR_ADJUST_SETTING" \
    --message "${SYMBOL_ADJUST_SETTING} ${message}"
}

function report_action_taken() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_ACTION_TAKEN.
  local message
  message="${1?MISSING message}"

  _report \
    --leading-format "$COLOR_ACTION_TAKEN" \
    --message "${SYMBOL_ACTION_TAKEN} ${message}"
}

function report_action_taken_to_log() {
  # Output report of action taken to the log and, if VERBOSE mode, to the terminal.
  # THe supplied text is prefaced by SYMBOL_ACTION_TAKEN.
  local message
  message="${1?MISSING message}"

  _report \
    --leading-format "$COLOR_ACTION_TAKEN" \
    --message "${SYMBOL_ACTION_TAKEN} ${message}" \
    --verbose-only
}

function report_about_to_kill_app() {
  # Output supplied line of text in a distinctive color prefaced by SYMBOL_KILLED.
  local message
  message="${1?MISSING message}"

  _report \
    --leading-format "$COLOR_KILLED" \
    --message "${SYMBOL_KILLED} ${message}"
}

function report_to_log() {
  # Output ONLY to report-log file (unless VERBOSE mode)..
  # Intended for echoing a value interactively supplied by the user to the report log
  # for completeness. Also goes to terminal only if VERBOSE mode.
  local message
  message="${1?MISSING message}"

  _report --message "${message}" --verbose-only
}

function report_argument_vector() {
  # Report argv in a readable form to stderr.
  #
  # Usage:[@]}"
  #   Report the received arguments to a function
  #     report_argument_vector "$@"
  #
  #   Report an array of argument-value pairs (where the value may be absent)
  #     report_argument_vector "${adduser_args[@]}"
  #
  # If the option name in an option/value pair contains "password",
  # the value is reported as "REDACTED".
  
  local arg=""
  local next_arg=""

  while (( $# > 0 )); do
    arg="$1"
    if [[ "$arg" == --* ]]; then
      if (( $# >= 2 )) && [[ "$2" != --* ]]; then
        next_arg="$2"
        if [[ "$arg" == *password* ]]; then
          next_arg="REDACTED"
        fi
        report "  ${arg}  ${next_arg}"
        shift 2
      else
        report "  ${arg}"
        shift
      fi
    else
      report "  ${arg}"
      shift
    fi
  done
}

function dump_accumulated_warnings_failures() {
  # Prints all accumulated warnings and/or failures from GENOMAC_ALERT_LOG
  
  # If we somehow never initialized, bail quietly.
  [[ -z "${GENOMAC_ALERT_LOG-}" ]] && return 0
  [[ ! -e "$GENOMAC_ALERT_LOG" ]] && return 0

  local leading_string
  local message
  local no_alerts_found_string
  local review_alerts_string
  local trailing_string

  leading_string="${NEWLINE}═════════ GenoMac warnings / failures (summary) ═════════${NEWLINE}"
  trailing_string="${NEWLINE}════════════════════════ end summary ════════════════════"
  no_alerts_found_string="✅ No GenoMac warnings or failures detected in this run."
  review_alerts_string="${NEWLINE}⬆️ Scroll back in the log to see these in context ⬆️"

  if [[ ! -s "$GENOMAC_ALERT_LOG" ]]; then
    message="${leading_string}${no_alerts_found_string}${trailing_string}"
    report_success "$message"
  else
    message="${leading_string}$(<"$GENOMAC_ALERT_LOG")${trailing_string}${review_alerts_string}"
    _report \
      --leading-format "$COLOR_WARNING" \
      --message "$message"
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

function _report_start_phase() {
  # Front end for the "entering" type of phase-reporting functions.
  local message="${1?MISSING message}"
  local entering_color="$COLOR_MAGENTA"
  _report --message "$message" --leading-format "$entering_color" --verbose-only
}

function _report_end_phase() {
  # Front end for the "leaving" type of phase-reporting functions.
  local message="${1?MISSING message}"
  local leaving_color="$COLOR_YELLOW"
  _report --message "$message" --leading-format "$leaving_color" --verbose-only
}

STAR_STUDDED_LINE="********************************************************************************"
DASH_STUDDED_LINE="--------------------------------------------------------------------------------"

function report_start_phase() {
  # printf "\n%b%s%b\n" "$COLOR_MAGENTA" "********************************************************************************" "$COLOR_RESET" >&2
  _report_start_phase "${STAR_STUDDED_LINE}"

  if (( $# == 2 )); then
    if [[ "$2" == "-" ]]; then
      # printf "%bEntering: %s%b\n" "$COLOR_MAGENTA" "$1" "$COLOR_RESET" >&2
      _report_start_phase "Entering: ${1}"
    else
      # printf "%bEntering: %s (file: %s)%b\n" "$COLOR_MAGENTA" "$1" "$2" "$COLOR_RESET" >&2
      _report_start_phase "Entering: ${1} (file: ${2})"
    fi
  elif (( $# == 1 )); then
    # printf "%b%s%b\n" "$COLOR_MAGENTA" "$1" "$COLOR_RESET" >&2
    _report_start_phase "${1}"
  else
    # printf "%bEntering phase%b\n" "$COLOR_MAGENTA" "$COLOR_RESET" >&2
    _report_start_phase "Entering phase"
  fi

  # printf "%b%s%b\n" "$COLOR_MAGENTA" "********************************************************************************" "$COLOR_RESET" >&2
  _report_start_phase "${STAR_STUDDED_LINE}"
}

function report_end_phase() {
  # printf "\n%b%s%b\n" "$COLOR_YELLOW" "--------------------------------------------------------------------------------" "$COLOR_RESET" >&2
  _report_end_phase "${DASH_STUDDED_LINE}"

  if (( $# == 2 )); then
    if [[ "$2" == "-" ]]; then
      # printf "%bLeaving: %s%b\n" "$COLOR_YELLOW" "$1" "$COLOR_RESET" >&2
      _report_end_phase "Leaving: ${1}"
    else
      # printf "%bLeaving: %s (file: %s)%b\n" "$COLOR_YELLOW" "$1" "$2" "$COLOR_RESET" >&2
      _report_end_phase "Leaving: ${1} (file: ${2})"
    fi
  elif (( $# == 1 )); then
    # printf "%b%s%b\n" "$COLOR_YELLOW" "$1" "$COLOR_RESET" >&2
    _report_end_phase "${1}"
  else
    # printf "%bLeaving phase%b\n" "$COLOR_YELLOW" "$COLOR_RESET" >&2
    _report_end_phase "Leaving phase"
  fi

  #printf "%b%s%b\n" "$COLOR_YELLOW" "--------------------------------------------------------------------------------" "$COLOR_RESET" >&2
  _report_end_phase "${DASH_STUDDED_LINE}"
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

############################################# GENERAL HELPERS #############################################
#                                                                                                         #

function _report() {
  # Helper to be called by only the report_* family of helpers.
  #
  # Always prints to report-log file (unless --no-report-log).
  # Also prints to terminal unless (--verbose-only was supplied and not in VERBOSE mode) or --no-terminal.
  # Also prints to GENOMAC_ALERT_LOG if --alert.
  #
  # Parameters:
  #
  #   --leading-format  "$COLOR_ERROR"   optional; defaults to "$COLOR_REPORT"
  #   --trailing-format "$COLOR_RESET"   optional; defaults to "$COLOR_RESET"
  #   --message         "App installed"  required
  #   --alert                            flag; also collected and regurgitated at end of Hypervisor run
  #   --no-terminal                      flag; do not print to terminal
  #   --no-report-log                    flag; skip printing to report-log file
  #   --verbose-only                     flag; displayed to terminal only in VERBOSE mode

  local leading_format="${COLOR_REPORT}"
  local is_alert=false
  local is_no_terminal=false
  local do_print_to_terminal=false
  local do_skip_report_log=false
  local is_verbose_only=false
  local message
  local trailing_format="${COLOR_RESET}"

  while (( $# )); do
    case "$1" in
      --leading-format)
        shift
        leading_format="${1:?MISSING value for --leading-format}"
        ;;

      --trailing-format)
        shift
        trailing_format="${1:?MISSING value for --trailing-format}"
        ;;

      --message)
        shift
        message="${1?MISSING value for --message}"
        ;;

      --alert)
        is_alert=true
        ;;

      --no-report-log)
        do_skip_report_log=true
        ;;
      
      --no-terminal)
        is_no_terminal=true
        ;;

      --verbose-only)
        is_verbose_only=true
        ;;

      --)
        shift
        break
        ;;

      -*)
        print "Unknown option to _report: $1" >&2
        return 1
        ;;

      *)
        print "Unexpected positional argument to _report: $1" >&2
        return 1
        ;;
    esac

    shift
  done

  if (( $# )); then
    print "Unexpected trailing arguments to _report: $*" >&2
    return 1
  fi

  if [[ ! -v message ]]; then
    print "MISSING required argument: --message" >&2
    return 1
  fi

  if [[ "$do_skip_report_log" == true && "$is_no_terminal" == true && "$is_alert" != true ]]; then
    print "Invalid options to _report: message would not be written anywhere" >&2
    return 1
  fi

  if [[ "$is_no_terminal" != true ]]; then
    if [[ "$is_verbose_only" != true ]] || is_VERBOSE; then
      do_print_to_terminal=true
    fi
  fi

  if [[ "$do_print_to_terminal" == true ]]; then
    _print_formatted_to_stderr "$leading_format" "$message" "$trailing_format"
  fi

  if [[ "$do_skip_report_log" != true ]]; then
    if [[ "${GM_STDOUT_STDERR_NOW_BEING_SENT_TO_GM_LOG_FILE:-false}" != true \
        || "$do_print_to_terminal" != true ]]; then
      _append_message_to_report_log "$message"
    fi
  fi

  if [[ "$is_alert" == true ]]; then
    _append_message_to_alert_log "$message"
  fi
}

function _print_formatted_to_stderr() {
  # Prints a message to stderr with an escape-character-interpreted prefix and suffix.
  #
  # Usage:
  #
  #   _print_formatted_to_stderr "$COLOR_REPORT" "${message}" "$COLOR_RESET"
  #   _print_formatted_to_stderr "$COLOR_ERROR" "${SYMBOL_FAILURE} ${message}" "$COLOR_RESET"
  #   _print_formatted_to_stderr "$COLOR_WARNING" "${SYMBOL_WARNING} ${message}" "$COLOR_RESET"
  #   _print_formatted_to_stderr "$COLOR_SUCCESS" "${SYMBOL_SUCCESS} ${message}" "$COLOR_RESET"
  #   _print_formatted_to_stderr "$COLOR_ADJUST_SETTING" "${SYMBOL_ADJUST_SETTING} ${message}" "$COLOR_RESET"
  #   _print_formatted_to_stderr "$COLOR_ACTION_TAKEN" "${SYMBOL_ACTION_TAKEN} ${message}" "$COLOR_RESET"
  #   _print_formatted_to_stderr "$COLOR_KILLED" "${SYMBOL_KILLED} ${message} is being killed (if necessary)" "$COLOR_RESET"

  local leading_format
  local message
  local trailing_format
  leading_format="${1:?MISSING leading_format}"
  message="${2?MISSING message}"
  trailing_format="${3:?MISSING trailing_format}"
  printf "%b%s%b\n" "$leading_format" "$message" "$trailing_format" >&2
}

function _append_message_to_alert_log() {
  # Append message to alert log
  #
  # The alert-log file is created by GenoMac-shared/scripts/assign_common_environment_variables.sh
  # See `############### GENOMAC_ALERT_LOG`
  
  local message="${1:MISSING message}"
  if [[ -n "${GENOMAC_ALERT_LOG-}" ]]; then
    printf '%s\n' "$message" >>"$GENOMAC_ALERT_LOG"
  fi
}

function _append_message_to_report_log() {
  # Append message to report log
  #
  # The report-log file is created by either (a) GenoMac-system/scripts/0_initialize_me_first.sh
  # or (b) GenoMac-user/scripts/0_initialize_me_first.sh
  # See `############### GM_LOG_FILE`
  
  local message="${1:?MISSING message}"
  
  if [[ -z "${GM_LOG_FILE-}" ]]; then
    printf 'FAIL: GM_LOG_FILE is unset or empty; cannot append to report log.\n' >&2
    return 1
  fi

  if ! printf '%s\n' "$message" >>"$GM_LOG_FILE"; then
    printf 'FAIL: Could not append to report log: %s\n' "$GM_LOG_FILE" >&2
    return 1
  fi
}

function is_VERBOSE() {
  # Returns 0 if in VERBOSE mode; returns 1 otherwise.
  #
  # Usage:
  #   if is_VERBOSE; then
  #     echo "VERBOSE"
  #   else
  #     echo "quiet"
  #   fi
  
  [[ "$GENOMAC_VERBOSE" == "true" ]]
}


