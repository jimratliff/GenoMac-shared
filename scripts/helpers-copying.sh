#!/usr/bin/env zsh

############### Helpers related to copying resources

# Relies upon:
#   helpers-reporting.sh

#!/usr/bin/env zsh

############### Helpers related to copying resources

# Relies upon:
#   helpers-reporting.sh

#!/usr/bin/env zsh

############### Helpers related to copying resources

# Relies upon:
#   helpers-reporting.sh

function copy_resource_between_local_directories() {
  # Helper function to copy a resource between two local directories.
  # The source resource may be either a file or a directory (e.g., package).
  # Usage: copy_resource_between_local_directories <source_path> <destination_path> [options]
  #
  # Arguments:
  #   source_path         Full path to the resource in a local directory
  #   destination_path    Full path where the resource should be copied
  #
  # Options:
  #   --systemwide        Deploy systemwide (use sudo, set owner to root:wheel)
  #                       Default: false (deploy for current user)
  #   --unzip             Source is a .zip file containing a single top-level
  #                       directory; unzip to a temp directory first, then copy
  #                       the extracted directory to destination_path.
  #
  # Returns: 0 on success, 1 on failure
  
  local source_path=""
  local destination_path=""
  local systemwide=false
  local unzip=false

  report_start_phase_standard
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --systemwide)
        systemwide=true
        shift
        ;;
      --unzip)
        unzip=true
        shift
        ;;
      *)
        if [[ -z "$source_path" ]]; then
          source_path="$1"
        elif [[ -z "$destination_path" ]]; then
          destination_path="$1"
        else
          report_fail "Too many arguments provided to copy_resource_between_local_directories"
          report_end_phase_standard
          return 1
        fi
        shift
        ;;
    esac
  done
  
  # Validate required arguments
  if [[ -z "$source_path" ]] || [[ -z "$destination_path" ]]; then
    report_fail "Usage: copy_resource_between_local_directories <source_path> <destination_path> [--systemwide] [--unzip]"
    report_end_phase_standard
    return 1
  fi

  report "Source:${source_path}${NEWLINE}Destination:${destination_path}${NEWLINE}Systemwide?:${systemwide} Unzip?:${unzip}"
  
  # Verify source exists
  report_action_taken "Verify that source resource exists"
  if [[ ! -e "$source_path" ]]; then
    report_fail "Source resource not found at: $source_path"
    report_end_phase_standard
    return 1
  fi
  success_or_not

  # If --unzip, extract to a temp directory and rewrite source_path
  local tmp_dir=""
  if [[ "$unzip" == true ]]; then
    if [[ ! -f "$source_path" ]] || [[ "${source_path}" != *.zip ]]; then
      report_fail "--unzip requires source_path to be a .zip file: $source_path"
      report_end_phase_standard
      return 1
    fi

    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    report_action_taken "Unzip ${source_path} to temp directory"
    unzip -q "$source_path" -d "$tmp_dir" ; success_or_not

    # Locate the single top-level directory inside the zip
    source_path="${tmp_dir}"/*(N)

    if [[ ! -d "$source_path" ]]; then
      report_fail "Expected a single top-level directory inside zip; got: $(ls "$tmp_dir")"
      rm -rf "$tmp_dir"
      trap - EXIT
      report_end_phase_standard
      return 1
    fi
    report "Extracted source directory: $(basename "$source_path")"
  fi
  
  # Determine if source is a file or directory and set appropriate flags/permissions
  local is_directory
  local mode
  local cp_flags
  local chown_flags
  local parent_dir
  if [[ -d "$source_path" ]]; then
    is_directory=true
    parent_dir="$destination_path"
    mode="755"        # Directories need execute permission for traversal
    cp_flags="-R"     # Recursive copy for directories
    chown_flags="-R"  # Recursive ownership for directories
    report "Source is a directory/package."
  else
    is_directory=false
    parent_dir=$(dirname "$destination_path")
    mode="644"         # Files: owner read/write, others read-only
    cp_flags="-f"      # Force copy for files
    chown_flags=""
    report "Source is a regular file, not a directory/package."
  fi
  
  # Set sudo prefix and owner based on deployment type
  local sudo_prefix
  local owner
  if [[ "$systemwide" == true ]]; then
    sudo_prefix="sudo"
    owner="root:wheel"
  else
    sudo_prefix=""
    owner="${USER}:$(id -gn)"
  fi
  
  # Create parent directory
  report_action_taken "Ensure destination folder exists: $parent_dir"
  $sudo_prefix mkdir -p "$parent_dir" ; success_or_not
  
  # Determine whether we need to copy
  local dest_resource_name
  dest_resource_name=$(basename "$destination_path")
  report_action_taken "Copy ${dest_resource_name} to ${parent_dir} (idempotent)"
  
  local needs_copy=false
  if [[ "$is_directory" == true ]]; then
    # For directories, use rsync dry-run to check if content differs
    if [[ -n $(rsync -n --no-perms --no-times --out-format="%n" "$source_path/" "$destination_path/") ]]; then
      needs_copy=true
      report "Directory contents differ, will update"
    else
      report "Directory contents are the same, will not update"
    fi
  else
    # For files, use cmp
    if [[ ! -e "$destination_path" ]]; then
      needs_copy=true
      report "Resource doesn't exist at destination, will copy"
    elif ! cmp -s "$source_path" "$destination_path" 2>/dev/null; then
      needs_copy=true
      report "File contents differ, will update"
    fi
  fi
  
  if [[ "$needs_copy" == true ]]; then
    # Remove existing destination if it exists and we're updating
    if [[ -e "$destination_path" ]]; then
      report_action_taken "Remove existing resource before copying"
      $sudo_prefix rm -rf "$destination_path" ; success_or_not
    fi
    
    # Copy the resource
    $sudo_prefix cp $cp_flags "$source_path" "$destination_path"
    report_success "Installed or updated ${dest_resource_name}"
  else
    report_success "${dest_resource_name} already up to date"
  fi
  
  # Set ownership
  report_action_taken "Set ownership to ${owner} on ${destination_path}"
  $sudo_prefix chown $chown_flags "${owner}" "$destination_path" ; success_or_not
  
  # Set permissions (644 for files, 755 for directories)
  report_action_taken "Set permissions to ${mode} on ${destination_path}"
  $sudo_prefix chmod "$mode" "$destination_path" ; success_or_not
  
  # For directories, ensure all subdirectories have proper execute permissions
  if [[ "$is_directory" == true ]]; then
    $sudo_prefix find "$destination_path" -type d -exec chmod 755 {} \; 2>/dev/null
  fi

  # Clean up temp directory if we created one
  if [[ -n "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
    trap - EXIT
  fi

  report_end_phase_standard
  
  return 0
}

