#!/usr/bin/env zsh

############### Helpers: Logging

function open_latest_log_file() {
  # Opens the most-recent GenoMac log file using the macOS default app.
  # Assumes the log files are in the directory $GM_LOGS_DIRECTORY and
  # that they are time stamped such that log filenames sort alphabetically
  # in chronological order.

  report_start_phase_standard

  local -a log_files

  if [[ ! -d "$GM_LOGS_DIRECTORY" ]]; then
    report_fail "Logs directory does not exist: “$GM_LOGS_DIRECTORY”."
    report_end_phase_standard
    return 1
  fi

  log_files=("$GM_LOGS_DIRECTORY"/*(.N))

  if (( ! ${#log_files[@]} )); then
    report_fail "No log files found in “$GM_LOGS_DIRECTORY”."
    report_end_phase_standard
    return 0
  fi

  open "${log_files[-1]}"

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
