#!/usr/bin/env zsh

############### Helpers: Files
# Relies upon:
#   helpers-reporting.sh

function validate_string_as_a_filename() {
  # Validate that the supplied string can be used as one filename component.
  report_start_phase_standard

  local string="${1-}"

  if [[
    -z "$string" ||
    "$string" == "." ||
    "$string" == ".." ||
    "$string" == *"/"* ||
    "$string" == *$'\n'* ||
    "$string" == *$'\r'*
  ]]; then
    report_fail "String cannot be used as a filename: $string"
    return 1
  fi

  report_end_phase_standard
  return 0
}

function expand_user_home_in_filesystem_path() {
  # Expand "~" or "~/" at the beginning of a filesystem path and print
  # the resulting absolute path.
  report_start_phase_standard

  local filesystem_path="${1:?MISSING path}"

  case "$filesystem_path" in
    "~")
      print -r -- "$HOME"
      ;;

    "~/"*)
      print -r -- "$HOME/${filesystem_path#\~/}"
      ;;

    "~"*)
      report_fail "Unsupported filesystem path '$filesystem_path': ~user syntax is not supported."
      return 1
      ;;

    /*)
      print -r -- "$filesystem_path"
      ;;

    *)
      report_fail "Unsupported filesystem path “$filesystem_path”: expected ~, ~/, or an absolute path."
      return 1
      ;;
  esac
  
  report_end_phase_standard
}

function convert_filesystem_path_to_file_url() {
  # Converts "~", "~/...", or an absolute filesystem path into an
  # encoded file URL. The path does not need to exist.
  #
  # Usage:
  #   file_url="$(convert_filesystem_path_to_file_url "~/Team Files")"
  #
  #   The output will be: 'file:///Users/tom/Team%20Files'
  
  report_start_phase_standard

  local filesystem_path="$1"
  local expanded_path

  expanded_path="$(expand_user_home_in_filesystem_path "$filesystem_path")"

  # Print result to standard out
  jq -nr --arg path "$expanded_path" '
    $path
    | @uri
    | gsub("%2F"; "/")
    | "file://" + .
  '
  report_end_phase_standard
}

function check_file_exists_and_is_readable() {
  # Tests supplied file for (a) existence and, if so, (b) whether it is a readable regular file.
  # - If BOTH file exists and is readable, REPLY is set to 1. (true in an arithmetic test)
  # - If file does not exist, REPLY is set to 0. (false in an arithmetic test)
  # - If file exists but is not readable, crash out with fatal error.
  #
  # Usage in the calling function:
  #   local REPLY
  #   check_file_exists_and_is_readable "$user_specific_markdown_page_file"
  #   if (( REPLY )); then
  #     markdown_file_to_display="$user_specific_markdown_page_file"
  #   else
  #     markdown_file_to_display="$default_markdown_page_file"
  #   fi
  #
  # WIP TODO 9/19/2026
  # Replacement for file_exists_and_if_so_is_readable
  
  local filepath="${1:?missing file path}"
  REPLY=0

  report_start_phase_standard

  if [[ ! -e "$filepath" && ! -L "$filepath" ]]; then
    report_to_log "No file exists at “${filepath}”."
  elif [[ ! -f "$filepath" || ! -r "$filepath" ]]; then
    report_fail "The object at “${filepath}” isn’t a readable regular file."
    exit 1
  else
    report_to_log "There is a readable regular file at “${filepath}”."
    REPLY=1
  fi

  report_end_phase_standard
  return 0
}



############### DEPRECATION ZONE
# function file_exists_and_if_so_is_readable() {
#   # Tests supplied file for (a) existence and, if so, (b) whether it is a readable regular file.
#   # Returns 0 if both exists and readable/regular.
#   # Returns 1 if the file doesn’t exist (a non-error, normal outcome).
#   # Exits immediately as an error if the file exists but isn’t readable/regular.
#   #
#   # WARNING: This works semi-fine IF it is simply called, and nonexistence/nonreadable is a fatal error.
#   #          (Even then, an error in the function itself would trigger a false nonexistence/nonreadable signal.)
#   #          BUT, in every case to date, I’m actually calling this in an `if`, so an error in the function
#   #          is SILENT and thus is a false nonexistence/nonreadable signal.
#   #          SEE WIP replacement: check_file_exists_and_is_readable
#   
#   report_start_phase_standard
#   
#   local filepath="${1:?missing file path}"
# 
#   if [[ ! -e "${filepath}" && ! -L "${filepath}" ]]; then
#     report_to_log "No file exists at “${filepath}”."
#     report_end_phase_standard
#     return 1
#   elif [[
#     ! -f "${filepath}" ||
#     ! -r "${filepath}"
#   ]]; then
#     report_fail "The object at “${filepath}” isn’t a readable regular file."
#     exit 1
#   else
#     report_to_log "There is a readable regular file at “${filepath}”."
#     report_end_phase_standard
#     return 0
#   fi
# }
