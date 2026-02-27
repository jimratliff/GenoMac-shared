#!/usr/bin/env zsh

############### Helpers related to launching/quitting apps (and logging out generally)

# TODO: As of 1/2/2026, the function naming is inconsistent: `quit_app_by_bundle_id_if_running` includes
#       `by_bundle_id` but the other functions’ names do not include this, even though they *all*
#       take a bundle_id as their first argument.

# Relies upon:
#   helpers-misc.sh (for show_file_using_quicklook().)
#   helpers-reporting.sh

function launch_and_quit_app() {
  # Launches (in background if possible) and then quits an app identified by its bundle ID
  # Required in some cases, e.g., iTerm2, where a sufficiently populated plist isn’t available to modify
  #   until the app has been launched once. (I.e., it is not enough simply to have created an empty
  #   plist file, as can be done with the function ensure_plist_exists().
  # Examples:
  #   launch_and_quit_app "com.apple.DiskUtility"
  #   launch_and_quit_app "com.googlecode.iterm2"
  report_start_phase_standard
  
  local bundle_id="$1"
  report_action_taken "Launch and quit app $bundle_id"
  report_action_taken "Launching app $bundle_id (in the background, if possible)"
  open -gj -b "$bundle_id" 2>/dev/null || open -g -b "$bundle_id" ; success_or_not
  sleep 2
  
  # report_action_taken "Quitting app $bundle_id"
  # osascript -e "tell application id \"$bundle_id\" to quit" ; success_or_not

  quit_app_by_bundle_id_if_running "$bundle_id"

  report_end_phase_standard
}

function quit_app_by_bundle_id_if_running() {
  # Quit the app identified by its bundle ID if (and only if) it is running.
  # - bundle_id: e.g., "com.tylerhall.Alan"
  #
  # Behavior:
  # - If the app is not running: no output, returns 0.
  # - If the app is running:
  #     1. Request a graceful quit via AppleScript.
  #     2. Sleep briefly to allow a clean shutdown.
  #     3. If still running, force-kill any processes under the app's
  #        Contents/MacOS directory, using Spotlight (mdfind) to locate the .app.
  report_start_phase_standard
  
  local delay_in_seconds_for_normal_quitting=3
  local bundle_id="$1"

  # Tests whether the app is currently running
  # If osascript errors (e.g., unknown bundle ID), grep sees nothing and this
  # condition is just false -> we treat that as "not running".
  if ! osascript -e "application id \"$bundle_id\" is running" 2>/dev/null | grep -qi true; then
    report_success "Application ${bundle_id} is not running. Nothing to do."
    report_end_phase_standard
    return 0
  fi

  # Request graceful quit
  report_action_taken "App with bundle ID ${bundle_id} is running. Requesting that it quit"
  osascript -e "tell application id \"$bundle_id\" to quit" >/dev/null 2>&1 ; success_or_not

  # Allow some time for the app to shut down and flush any state (plists, etc.).
  sleep $delay_in_seconds_for_normal_quitting

  # If still running, force quit
  if osascript -e "application id \"$bundle_id\" is running" 2>/dev/null | grep -qi true; then
    # Derive the .app path from the bundle ID using Spotlight.
    # We take the first match; if there are multiple installs, that's already
    # a slightly weird situation for an updater.
    local app_path
    app_path=$(mdfind "kMDItemCFBundleIdentifier == '${bundle_id}'" | head -n 1)

    if [[ -n "$app_path" ]]; then
      report_warning "App ${bundle_id} still running despite our polite request; forcing quit for processes under ${app_path}/Contents/MacOS/"
      # pkill returns 1 if nothing matched; that's fine for our semantics
      # ("ensure it's not running"), so we mask that with `|| true` to avoid making success_or_not print a ❌.
      pkill -9 -f "${app_path}/Contents/MacOS/" >/dev/null 2>&1 || true
      sleep $delay_in_seconds_for_normal_quitting
      success_or_not
    else
      # We think it's running but can't find the bundle on disk; that's
      # suspicious enough to mark as a failure in your alert summary.
      report_fail "App ${bundle_id} appears to be running, but its .app could not be found via mdfind; unable to force quit"
      false
    fi
  fi
  
  report_end_phase_standard
  return 0
}

function force_user_logout(){
  report_start_phase_standard
  
  report_action_taken $'\n\nYou are about to be logged out…'
  sleep 3  # Give user time to read the message

  # Graceful logout using familiar system behavior
  osascript -e 'tell application "System Events" to log out'

  report_end_phase_standard

  # Ensure the calling script doesn’t continue to run
  exit
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

