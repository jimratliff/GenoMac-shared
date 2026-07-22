#!/usr/bin/env zsh

############### Helpers: Logging

function open_latest_log_file() {
  # Opens the most-recent GenoMac log file that predates this invocation.
  # Assumes the log files are in $GM_LOGS_DIRECTORY and are timestamped
  # such that their filenames sort chronologically.

  report_start_phase_standard

  local -a log_files

  if [[ ! -d "$GM_LOGS_DIRECTORY" ]]; then
    report_fail "Logs directory does not exist: “$GM_LOGS_DIRECTORY”."
    report_end_phase_standard
    return 1
  fi

  log_files=("$GM_LOGS_DIRECTORY"/*(.N))

  # One file is the log created by this utility invocation. Therefore,
  # at least two files are required for a previous log to exist.
  if (( ${#log_files[@]} < 2 )); then
    report_fail "No previous log file found in “$GM_LOGS_DIRECTORY”."
    report_end_phase_standard
    return 1
  fi

  open "${log_files[-2]}"

  report_end_phase_standard
}

function open_logs_directory() {
  # Opens the GenoMac logs directory in Finder.

  report_start_phase_standard

  if [[ ! -d "$GM_LOGS_DIRECTORY" ]]; then
    report_warning "Logs directory does not exist: “$GM_LOGS_DIRECTORY”."
    report_end_phase_standard
    return 1
  fi

  open "$GM_LOGS_DIRECTORY"

  report_end_phase_standard
}
