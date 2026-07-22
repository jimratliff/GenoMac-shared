#!/usr/bin/env zsh

# Utility script to open (a) the latest log file and (b) the directory containing the log files.

set -euo pipefail

this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

host_repo_dir="$(
    git -C "$this_script_dir" rev-parse --show-superproject-working-tree
)"

if [[ -z "$host_repo_dir" ]]; then
    print -u2 -- "error: cannot determine the containing GenoMac repository"
    exit 1
fi

initialization_script="$host_repo_dir/scripts/0_initialize_me_first.sh"

echo "Source ${initialization_script}"
source "${initialization_script}"

function usage() {
  local script_name="${0:t}"
  cat >&2 <<EOF
Usage:
  ${script_name} show-latest
  ${script_name} show-directory
EOF
}

function main() {
  emulate -L zsh
  set -euo pipefail

  if (( $# != 1 )); then
    usage
    return 64
  fi

  local command="$1"

  case "${command}" in
    show-latest)
      report_action_taken "Show latest log file"
      open_latest_log_file ; success_or_not
      ;;

    show-directory)
      report_action_taken "Show log-file directory"
      open_logs_directory ; success_or_not
      ;;

    *)
      report_fail "Unknown logging command: ${command}"
      usage
      return 64
      ;;
  esac
}

main "$@"
