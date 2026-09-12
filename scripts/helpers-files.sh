#!/usr/bin/env zsh

############### Helpers: Files
# Relies upon:
#   helpers-reporting.sh

function validate_string_as_a_filename() {
  # Return success if the supplied string can be used as one filename
  # component. Return failure without reporting when it cannot.
  report_start_phase_standard
  local string="${1-}"

  [[ -n "$string" ]] || return 1
  [[ "$string" != "." ]] || return 1
  [[ "$string" != ".." ]] || return 1
  [[ "$string" != *"/"* ]] || return 1
  [[ "$string" != *$'\n'* ]] || return 1
  [[ "$string" != *$'\r'* ]] || return 1
  
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

function create_Finder_alias_file() {
  # Creates a Finder alias file.
  # Two mandatory options, accepted in either order:
  #   --path_of_original     <path of original file or folder>
  #   --path_of_alias_file   <desired path of Finder alias file>
  # Fails if path_of_alias_file already exists.

  report_start_phase_standard

  local destination=""
  local option
  local original=""
  local usage='Usage: create_Finder_alias_file --path_of_original PATH --path_of_alias_file PATH'

  local -i destination_seen=0
  local -i original_seen=0

  while (( $# )); do
    option=$1
    case $option in
      --path_of_original)
        if (( original_seen )); then
          report_fail "Duplicate option: “--path_of_original”"
          return 1
        fi
        original=$(required_value_for_option "$option" "${2-}")
        original_seen=1
        ;;
      --path_of_alias_file)
        if (( destination_seen )); then
          report_fail "Duplicate option: “--path_of_alias_file”"
          return 1
        fi
        destination=$(required_value_for_option "$option" "${2-}")
        destination_seen=1
        ;;
      *)
        report_fail "Unknown option: “$option”"
        print -ru2 -- "$usage"
        return 1
        ;;
    esac
    shift 2
  done

  require_mandatory_parameters \
    original    --path_of_original \
    destination --path_of_alias_file

  # Convert relative paths to absolute paths without evaluating shell text.
  original=${original:a}
  destination=${destination:a}

  local parent=${destination:h}
  local alias_name=${destination:t}

  if [[ ! -e $original ]]; then
    report_fail "Original object does not exist: “$original”"
    return 1
  fi
  
  if [[ ! -d $parent ]]; then
    report_fail "Destination directory does not exist: “$parent”"
    return 1
  fi
  
	if [[ $original -ef $destination ]]; then
    report_fail "Original and alias destination refer to the same object: “$destination”"
    return 1
  fi
  
  if [[ -e $destination || -L $destination ]]; then
    report_fail "Destination ($destination) already exists."
    return 1
    }
  fi

  # Pass paths as arguments, never as interpolated AppleScript source.
  /usr/bin/osascript - "$original" "$parent" "$alias_name" <<'APPLESCRIPT' >/dev/null
on run argv
  set originalItem to (POSIX file (item 1 of argv)) as alias
  set destinationFolder to (POSIX file (item 2 of argv)) as alias
  set aliasName to item 3 of argv
  tell application "Finder"
    make new alias file at destinationFolder to originalItem with properties {name:aliasName}
  end tell
end run
APPLESCRIPT

  report_end_phase_standard
}
