############### Helpers related to copying resources

function copy_resource_between_local_directories() {
  # Helper function to copy a resource between two local directories.
  # The source resource may be either a file or a directory (e.g.,package).
  # Usage: copy_resource_between_local_directories <source_path> <destination_path> [--systemwide]
  #
  # Arguments:
  #   source_path         Full path to the resource in a local directory
  #   destination_path    Full path where the resource should be copied
  #
  # Options:
  #   --systemwide        Deploy systemwide (use sudo, set owner to root:wheel)
  #                       Default: false (deploy for current user)
  #
  # Returns: 0 on success, 1 on failure
  
  local source_path=""
  local destination_path=""
  local systemwide=false

  report_start_phase_standard
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --systemwide)
        systemwide=true
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
    report_fail "Usage: copy_resource_between_local_directories <source_path> <destination_path> [--systemwide]"
    return 1
  fi
  
  # Verify source exists
  report_action_taken "Verify that source resource exists"
  if [[ ! -e "$source_path" ]]; then
    report_fail "Source resource not found at: $source_path"
    return 1
  fi
  
  # Determine if source is a file or directory and set appropriate flags/permissions
  local is_directory
  local mode
  local cp_flags
  local chown_flags
  if [[ -d "$source_path" ]]; then
    is_directory=true
    mode="755"  # Directories need execute permission for traversal
    cp_flags="-R"  # Recursive copy for directories
    chown_flags="-R"  # Recursive ownership for directories
    report "Source is a directory/package."
  else
    is_directory=false
    mode="644"  # Files: owner read/write, others read-only
    cp_flags="-f"  # Force copy for files
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
  local parent_dir
  parent_dir=$(dirname "$destination_path")
  report_action_taken "Ensure destination folder exists: $parent_dir"
  $sudo_prefix mkdir -p "$parent_dir" ; success_or_not
  
  # Determine whether we need to copy
  local resource_name
  resource_name=$(basename "$destination_path")
  report_action_taken "Copy ${resource_name} to $(dirname "$destination_path") (idempotent)"
  
  local needs_copy=false
  if [[ ! -e "$destination_path" ]]; then
    needs_copy=true
    report "Resource doesn’t exist at destination, will copy"
  elif [[ "$is_directory" == true ]]; then
    # For directories, use rsync dry-run to check if content differs
    if ! rsync -aqn "$source_path/" "$destination_path/" >/dev/null 2>&1; then
      needs_copy=true
      report "Directory contents differ, will update"
    fi
  else
    # For files, use cmp
    if ! cmp -s "$source_path" "$destination_path" 2>/dev/null; then
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
    $sudo_prefix cp $cp_flags "$source_path" "$destination_path" ; success_or_not
    report_success "Installed or updated ${resource_name}"
  else
    report_success "${resource_name} already up to date"
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

  report_end_phase_standard
  
  return 0
}
