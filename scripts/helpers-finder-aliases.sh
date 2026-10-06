#!/usr/bin/env zsh

############### Helpers: File alias files

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
  fi

  report_to_log "Create Finder alias file in “${parent}”, pointing to “${original}”, nicknamed “${alias_name}”."
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

function remove_Finder_alias_files_from_directory() {
  # Remove only Finder alias files directly within the supplied directory.
  # Preserve original files, symbolic links, and subdirectories.
  #
  # Test each directory entry’s kMDItemContentType and remove it only when the type is
  # exactly com.apple.alias-file, Apple’s identifier for a Finder alias file.

  report_start_phase_standard

  local directory="${1:?MISSING directory}"
  
  local content_type
  local item

  for item in "$directory"/*(DN); do
    if [[ ! -f "$item" || -L "$item" ]]; then
      report_to_log "Preserving item because it is not a regular Finder alias file: $item"
      continue
    fi
  
    if ! content_type="$(
      mdls -raw \
        -name kMDItemContentType \
        "$item" 2>/dev/null
    )"; then
      report_warning "Unable to determine whether item is a Finder alias file; preserving it: $item"
      continue
    fi
  
    if [[ "$content_type" != "com.apple.alias-file" ]]; then
      report_to_log "Preserving non-alias item: $item (content type: $content_type)"
      continue
    fi
  
    report_action_taken_to_log "Removing Finder alias file: $item"
    rm -f -- "$item"
    
  done

  report_end_phase_standard
}
