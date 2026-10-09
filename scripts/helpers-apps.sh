#!/usr/bin/env zsh

############### Helpers related to launching/quitting apps (and logging out generally)

# TODO: As of 1/2/2026, the function naming is inconsistent: `quit_app_by_bundle_id_if_running` includes
#       `by_bundle_id` but the other functions’ names do not include this, even though they *all*
#       take a bundle_id as their first argument.

# Relies upon:
#   helpers-misc.sh (for show_file_using_quicklook().)
#   helpers-reporting.sh

function launch_app_by_bundle_id_in_background_hidden() {
  # Launches app in background (hidden, if possible).
  
  report_start_phase_standard
  local bundle_id="${1:?MISSING bundle id}"
  
  report_action_taken_to_log "Launching app $bundle_id (in the background, if possible)"
  open -gj -b "$bundle_id" 2>/dev/null || open -g -b "$bundle_id" ; success_or_not
  
  report_end_phase_standard
}

function launch_app_by_bundle_id_in_foreground() {
  report_start_phase_standard
  local bundle_id="${1:?MISSING bundle id}"

  report_action_taken_to_log "Launching app $bundle_id in the foreground"
  open -b "$bundle_id" ; success_or_not

  report_end_phase_standard
}

function launch_and_quit_app() {
  # Launches in background (hidden if possible) and then quits an app identified by its bundle ID
  # Required in some cases, e.g., iTerm2, where a sufficiently populated plist isn’t available to modify
  #   until the app has been launched once. (I.e., it is not enough simply to have created an empty
  #   plist file, as can be done with the function ensure_plist_exists().
  # Examples:
  #   launch_and_quit_app "com.apple.DiskUtility"
  #   launch_and_quit_app "com.googlecode.iterm2"
  report_start_phase_standard
  
  local bundle_id="$1"
  report_action_taken "Launch and quit app $bundle_id"
  report_action_taken_to_log "Launching app $bundle_id (in the background, if possible)"
  launch_app_by_bundle_id_in_background_hidden "$bundle_id"
  # open -gj -b "$bundle_id" 2>/dev/null || open -g -b "$bundle_id" ; success_or_not
  sleep 2
  
  # report_action_taken_to_log "Quitting app $bundle_id"
  # osascript -e "tell application id \"$bundle_id\" to quit" ; success_or_not

  quit_app_by_bundle_id_if_running "$bundle_id"

  report_end_phase_standard
}

function quit_app_by_bundle_id_if_running() {
  # Quit the app identified by its bundle ID if (and only if) it is running.
  # - bundle_id: e.g., "com.tylerhall.Alan"
  #
  # Behavior:
  # - If the app is not running: no stdout output, logs and returns 0.
  # - If the app is running:
  #     1. Request a graceful quit via AppleScript.
  #     2. Sleep briefly to allow a clean shutdown.
  #     3. If still running, force-kill any processes under the app's
  #        Contents/MacOS directory, using Spotlight (mdfind) to locate the .app.
  report_start_phase_standard
  
  local delay_in_seconds_for_normal_quitting=3
  local bundle_id="${1:?MISSING bundle ID}"

  # Tests whether the app is currently running
  if ! app_is_running "$bundle_id"; then
    report_to_log "Application ${bundle_id} is not running. Nothing to do."
    report_end_phase_standard
    return 0
  fi

  # Request graceful quit
  report_action_taken "App with bundle ID ${bundle_id} is running. Requesting that it quit"
  osascript -e "tell application id \"$bundle_id\" to quit" >/dev/null 2>&1 ; success_or_not

  # Allow some time for the app to shut down and flush any state (plists, etc.).
  sleep "$delay_in_seconds_for_normal_quitting"

  if ! app_is_running "$bundle_id"; then
    report_to_log "Application ${bundle_id} is not running."
    report_end_phase_standard
    return 0
  fi

  force_quit_app_by_bundle_id "$bundle_id"
  
  report_end_phase_standard
  return 0
}

function force_quit_app_by_bundle_id() {
  # Force-quits the app identified by its bundle ID.
  # Returns 0 if already stopped or successfully stopped.
  # Returns 1 if the app cannot be located or remains running.
  #
  # Usage:
  #   force_quit_app_by_bundle_id "$BUNDLE_ID_HELIUM"

  report_start_phase_standard

  local bundle_id="${1:?MISSING bundle ID}"
  local app_path
  local spotlight_results
  local process_path_pattern
  local -a app_paths
  local -i delay_in_seconds=3

  if ! app_is_running "$bundle_id"; then
    report_to_log "Application ${bundle_id} is not running. Nothing to do."
    report_end_phase_standard
    return 0
  fi

  if ! spotlight_results=$(
    mdfind "kMDItemCFBundleIdentifier == '${bundle_id}'"
  ); then
    report_fail "Unable to locate app ${bundle_id} via Spotlight"
    return 1
  fi

  if [[ -z "$spotlight_results" ]]; then
    report_fail "App ${bundle_id} is running, but Spotlight could not locate its .app"
    return 1
  fi

  app_paths=("${(@f)spotlight_results}")
  app_path="${app_paths[1]}"

  # Avoid choosing an arbitrary installation.
  if (( ${#app_paths} > 1 )); then
    report_fail "Multiple installations found for ${bundle_id}; unable to choose one safely"
    return 1
  fi

  if [[ ! -d "${app_path}/Contents/MacOS" ]]; then
    report_fail "App executable directory not found: ${app_path}/Contents/MacOS"
    return 1
  fi

  # Escape regex metacharacters so pkill matches the path literally.
  process_path_pattern=$(
    printf '%s\n' "${app_path}/Contents/MacOS/" |
      sed 's/[][\\.^$*+?(){}|]/\\&/g'
  )

  report_warning "Force-quitting app ${bundle_id} at ${app_path}"

  # The app may exit between checking its state and invoking pkill.
  # Verify the resulting state regardless of pkill's exit status.
  if ! pkill -9 -f "$process_path_pattern" >/dev/null 2>&1; then
    report_warning "pkill did not report success for ${bundle_id}; checking whether it has exited"
  fi

  sleep "$delay_in_seconds"

  if app_is_running "$bundle_id"; then
    report_fail "App ${bundle_id} is still running after force quit"
    return 1
  fi

  report_end_phase_standard
  return 0
}

function app_is_running() {
  # Returns 0 if running, 1 if not running.
  # Exits the current shell with status 2 if the check fails.
  #
  # Usage:
  #   if app_is_running "$BUNDLE_ID_HELIUM"; then
  #     report_to_log "Helium is running"
  #   else
  #     report_to_log "Helium is not running"
  #   fi

  report_start_phase "app_is_running $*"

  local bundle_id="${1:?MISSING bundle ID}"
  local result

  if ! result=$(osascript \
    -e "application id \"$bundle_id\" is running" 2>/dev/null); then
    report_fail "Unable to check whether app ${bundle_id} is running"
    exit 2
  fi

  case "$result" in
    true)  return 0 ;;
    false) return 1 ;;
    *)
      report_fail "Unexpected running-state response for ${bundle_id}: '$result'"
      exit 2
      ;;
  esac

  report_end_phase "app_is_running $*"
}

function force_user_logout(){
  report_start_phase_standard
  
  report $'\n\nYou are about to be logged out…'
  sleep 5  # Give user time to read the message

  # Graceful logout using familiar system behavior
  osascript -e 'tell application "System Events" to log out'

  report_end_phase_standard

  # Ensure the calling script doesn’t continue to run
  leave_genomac_hypervisor
}

get_homebrew_prefix() {
  # Usage:
  #   export HOMEBREW_PREFIX="$(get_homebrew_prefix)"
  if [[ -d /opt/homebrew ]]; then
    print /opt/homebrew
  elif [[ -d /usr/local/Homebrew ]]; then
    print /usr/local
  else
    report_fail "Homebrew not installed. Install Homebrew first."
    return 1
  fi
}

