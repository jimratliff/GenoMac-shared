#!/usr/bin/env zsh

############### Helpers: Files
# Relies upon:
#   helpers-reporting.sh

function file_exists_and_is_readable() {
  # Tests supplied file for (a) existence and, if so, (b) whether it is a readable regular file.
  # Returns 0 if both exists and readable/regular.
  # Returns 1 if the file doesn’t exist (a non-error, normal outcome).
  # Exits immediately as an error if the file exists but isn’t readable/regular.
  
  report_start_phase_standard
  
  local filepath="${1:?missing file path}"

  if [[ ! -e "${filepath}" && ! -L "${filepath}" ]]; then
    report_to_log "No file exists at “${filepath}”."
    report_end_phase_standard
    return 1
  elif [[
    ! -f "${filepath}" ||
    ! -r "${filepath}"
  ]]; then
    report_fail "The object at “${filepath}” isn’t a readable regular file."
    exit 1
  else
    report_to_log "There is a readable regular file at “${filepath}”."
    report_end_phase_standard
    return 0
  fi
}

function get_array_of_2_tuples_from_json_file() {
  # Reads a top-level JSON array and returns each element as one compact
  # JSON value in the conventional zsh $reply array.
  #
  # This function validates only that the file contains valid JSON whose
  # top-level value can be enumerated. It assigns no meaning to the items.
  #
  # Usage:
  #   get_array_of_2_tuples_from_json_file "$input_file"
  #   local -a tuples=("${reply[@]}")
  
  report_start_phase_standard

  local file_to_read="$1"
  local output

  reply=()

  output="$(jq -c '.[]' "$file_to_read")" || return 1

  if [[ -n "$output" ]]; then
    reply=("${(@f)output}")
  fi
  
  report_end_phase_standard
}
