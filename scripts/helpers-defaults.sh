#!/usr/bin/env zsh

############### Helpers related to using the macOS `defaults write` command

# Relies upon:
#   helpers-reporting.sh

function legacy_plist_path_from_domain() {
  # Constructs path of the .plist file corresponding to the defaults domain passed as an argument.
  # Usage:
  #   local plist_path=$(legacy_plist_path_from_domain "$domain")
  local domain="$1"
  local plist_path="$HOME/Library/Preferences/${domain}.plist"
  echo "$plist_path"
}

function sandboxed_plist_path_from_domain() {
  # Constructs path of the .plist file for a sandboxed app corresponding to the defaults domain 
  # passed as an argument.
  # Usage:
  #   local plist_path=$(sandboxed_plist_path_from_domain "$domain")
  
  local domain="$1"
  local plist_path="$HOME/Library/Containers/${domain}/Data/Library/Preferences/${domain}.plist"
  echo "$plist_path"
}

function ensure_plist_path_exists() {
  # Used to ensures the plist file at the supplied path exists.
  # Note: In some cases, e.g., iTerm2, a merely nonempty plist is insufficient to support all desired
  #       modifications. In that case, the function launch_and_quit_app() is used to initialize the plist.
  # Usage:
  #   domain="com.apple.DiskUtility"
  #   plist_path=$(legacy_plist_path_from_domain $domain")
  #   ensure_plist_path_exists "${plist_path}"
  #
  #   domain="com.apple.Preview""
  #   plist_path=$(sandboxed_plist_path_from_domain $domain")
  #   ensure_plist_path_exists "${plist_path}"
  
  local plist_path="$1"
  report_action_taken "Ensure that plist exists at: ${plist_path}"
  if [[ ! -f "$plist_path" ]]; then
    report_action_taken "plist doesn’t exist; creating…"

    # Ensure the directory structure exists
    local plist_dir=$(dirname "$plist_path")
    if [[ ! -d "$plist_dir" ]]; then
      report_action_taken "Creating directory structure: ${plist_dir}"
      mkdir -p "$plist_dir"
    fi
    
    local fictitious_key="_fictitious_key"
    plutil -create xml1 "$plist_path" && \
    plutil -insert "${fictitious_key}" -string "Nothing to see here; move along…" "$plist_path" && \
    plutil -remove "${fictitious_key}" "$plist_path"
    if [[ ! -f "$plist_path" ]]; then
      report_fail "${plist_path} still doesn’t exist; FAIL"
      return 1
    else
      report_success "${plist_path} now exists."
    fi
  else
    report_success "${plist_path} already exists."
  fi
}

function set_or_add_plist_bool() {
	# Sets a boolean key in a plist file, or adds it if it doesn’t yet exist.
	# This makes the operation idempotent: safe to call on both first runs (when
	# the key is absent) and subsequent re-runs (when the key already exists).
	#
	# PlistBuddy's `Set` succeeds if the key exists, fails if it doesn't.
	# PlistBuddy's `Add` succeeds if the key is absent, fails if it already exists.
	# By trying `Set` first and falling back to `Add` on failure, we handle both cases.
	#
	# `2>/dev/null` suppresses PlistBuddy's error message when `Set` fails because
	# the key doesn't exist — that failure is expected on first run and not an error.
	#
	# Arguments:
	#   $1  key    The plist key name
	#   $2  value  The boolean value: `true` or `false`
	#   $3  path   Absolute path to the .plist file
	#
	# Usage:
	#   set_or_add_plist_bool 'Show Search Field' false "$witch_plist_path"
  #   set_or_add_plist_bool 'Spring-Load' true "$witch_plist_path"

  report_start_phase_standard

  local key value path
	key="$1" 
	value="$2" 
	path="$3"

  report_action_taken "Setting plist item. Key: ${key} to value: {$value}"
  
	"$PLISTBUDDY_PATH" -c "Set '$key' $value" "$path" 2>/dev/null \
		|| "$PLISTBUDDY_PATH" -c "Add '$key' bool $value" "$path"
  success_or_not

  report_end_phase_standard
}

