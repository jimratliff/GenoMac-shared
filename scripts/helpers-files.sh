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

function files_without_given_extensions() {
  # Returns `reply` array of files within given directory that do *not* have an
  # extension that matches any of the specified file extensions.
  #
  # $1: Path of directory to check
  # $2 … $n: either (A) an array of file extensions or (B) a sequence of individual
  #     arguments, each of which is a file extension.
  # Usage:
  #
  #   typeset -a reply files
  #   extensions=(jpg png gif)
  #   files_without_extensions "/path/to/folder" "${extensions[@]}"
  #   files=("${reply[@]}")
  #   
  #   Or:
  #
  #   typeset -a reply files
  #   files_without_extensions "/path/to/folder" jpg .png gif
  #   files=("${reply[@]}")
  
  report_start_phase_standard

  local directory="${1:?MISSING directory}"
  shift

  local ext
  local file
  
  local -i excluded
  
  reply=()

  [[ -d $directory ]] || {
    report_fail "Not a directory: $directory"
    return 1
  }

  for file in "$directory"/*(ND.); do
    excluded=0

    for ext in "$@"; do
      if [[ ${file:e} == "${ext#.}" ]]; then
        excluded=1
        break
      fi
    done

    (( excluded )) || reply+=("$file")
  done

  report_end_phase_standard
}

function files_with_given_extensions() {
  # Returns `reply` array of files within given directory that *do* have an
  # extension that matches any of the specified file extensions.
  #
  # $1: Path of directory to check
  # $2 … $n: either (A) an array of file extensions or (B) a sequence of individual
  #     arguments, each of which is a file extension.
  # Usage:
  #
  #   typeset -a reply files
  #   extensions=(jpg png gif)
  #   files_with_given_extensions "/path/to/folder" "${extensions[@]}"
  #   files=("${reply[@]}")
  #   
  #   Or:
  #
  #   typeset -a reply files
  #   files_with_given_extensions "/path/to/folder" jpg .png gif
  #   files=("${reply[@]}")
  
  report_start_phase_standard
  _files_by_given_extensions with "$@"
  report_end_phase_standard
}

function files_without_given_extensions() {
  # Returns `reply` array of files within given directory that do *not* have an
  # extension that matches any of the specified file extensions.
  #
  # $1: Path of directory to check
  # $2 … $n: either (A) an array of file extensions or (B) a sequence of individual
  #     arguments, each of which is a file extension.
  # Usage:
  #
  #   typeset -a reply files
  #   extensions=(jpg png gif)
  #   files_without_given_extensions "/path/to/folder" "${extensions[@]}"
  #   files=("${reply[@]}")
  #   
  #   Or:
  #
  #   typeset -a reply files
  #   files_without_given_extensions "/path/to/folder" jpg .png gif
  #   files=("${reply[@]}")
  
  report_start_phase_standard
  _files_by_given_extensions without "$@"
  report_end_phase_standard
}

function _files_by_given_extensions() {
  # Helper to support files_with_given_extensions and files_without_given_extensions
  # $1: mode (either "with" or "without")
  # $2: directory to search
  # $3 … $n: either (A) an array of file extensions or (B) a sequence of individual
  #     arguments, each of which is a file extension.
  
  report_start_phase_standard
  
  local mode="${1:?MISSING mode}"
  ensure_string_belongs_to_list "$mode" with without
  
  shift

  local directory="${1:?MISSING directory}"
  shift

  local ext
  local file
  local -i matched

  reply=()

  [[ -d $directory ]] || {
    report_fail "Not a directory: $directory"
    return 1
  }

  for file in "$directory"/*(ND.); do
    matched=0

    for ext in "$@"; do
      if [[ ${file:e} == "${ext#.}" ]]; then
        matched=1
        break
      fi
    done

    if [[ $mode == with ]] && (( matched )); then
      reply+=("$file")
    elif [[ $mode == without ]] && (( ! matched )); then
      reply+=("$file")
    fi
  done

  report_end_phase_standard
}


