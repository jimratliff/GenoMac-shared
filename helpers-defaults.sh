# Prevent multiple sourcing
if [[ -n "${__already_loaded_genomac_bootstrap_helpers_sh:-}" ]]; then return 0; fi
__already_loaded_genomac_bootstrap_helpers_sh=1
export __already_loaded_genomac_bootstrap_helpers_sh

############### HELPERS

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
  # local plist_path="$HOME/Library/Preferences/${domain}.plist"
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
