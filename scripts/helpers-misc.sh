#!/usr/bin/env zsh

############### Helpers: Miscellaneous

# Relies upon:
#   helpers-reporting.sh

function this_mac_is_a_laptop() {
  # Returns 0 if Mac is a laptop (has a battery installed); otherwise returns 1
  #
  # Usage:
  #   if this_mac_is_a_laptop; then
  #   	echo "This is a laptop"
  #   else
  #   	echo "This is a desktop"
  #   fi
  #
  report_start_phase_standard

  if /usr/sbin/ioreg -c AppleSmartBattery -r | awk '
    /BatteryInstalled/ {
      found = 1
      exit ($3 == "Yes" ? 0 : 1)
    }
    END {
      if (!found) {
        exit 1
      }
    }
  '; then
    status=0
  else
    status=1
  fi

  report_end_phase_standard
  return "$status"
}

function ask_and_set_verbosity_preference() {
  # Asks user whether verbose output is desired and sets the environment variable accordingly.
  report_start_phase_standard
  if get_yes_no_answer_to_question "Do you want verbose output from the Hypervisor?"; then
    turn_on_verbose_genomac_output
  else
    turn_off_verbose_genomac_output
  fi
  report_end_phase_standard
}

function interactive_ensure_terminal_has_fda() {
  # Run at the beginning of a terminal session to try to ensure that the currently running terminal
  # app has Full Disk Access (FDA) permission.
  #
  # If the terminal app does *not* have FDA, the Settings » Privacy & Security » Full Disk Access
  # panel is opened (this terminal app should already be pre-populated, but un-enabled, on the 
  # list of apps), so the user can simply flip the switch for this app.
  #
  # The reason this terminal app will be pre-populated on the FDA list: The current script tests
  # whether the current terminal app has FDA by attempting to query a restricted location.
  # If the app doesn’t have FDA, this query is sufficient for macOS to add this app to that list.
  # NOTE: This is *not* conditioned on a PERM state variable, because there are multiple possible
  #       terminal apps. Each would need to tracked separately, requiring the script to interrogate
  #       what terminal app was running for that shell session. Too complicated!

  report_start_phase_standard

  report_action_taken "Testing whether currently running terminal application has Full Disk Access."
  # Query a restricted location (a) to test FDA and (b) if not, add terminal app to list
  if ! ls ~/Library/Mail &>/dev/null; then
    # The currently running terminal app does *not* have FDA
    # macOS will add the terminal app to the list, but un-enabled
    report_warning "The currently running terminal app needs, but doesn’t have, Full Disk Access."

    # Tests whether this is an interactive session
    if [[ -t 0 ]]; then
    
      # The session is interactive
      report_action_taken "I will open (a) the Full Disk Access panel in System Settings and (b) a Quick Look window with instructions"
      launch_app_and_prompt_user_to_act \
        --no-app \
        --open "$SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_FULL_DISK" \
        --show-doc "${GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY}/full_disk_access_how_to_configure.md" \
        "Follow the instructions in the Quick Look window to grant the current terminal app Full Disk Access"

      report "Configuring user confirms they have given FDA to the running terminal application" ; success_or_not
      report_end_phase_standard
      return 0
        
    else
      # The session is not interactive
      report_warning "Warning: Terminal lacks FDA and no interactive session to fix it"
      report_end_phase_standard
      return 1
    fi
  fi
  report_success "This terminal application already had Full Disk Access. No additional action required."
  report_end_phase_standard
}

function interactive_ensure_terminal_has_accessibility() {
  # Ensure the terminal application responsible for this shell can use
  # System Events to emit keyboard events.

  report_start_phase_standard

  if terminal_can_emit_keystrokes; then
    report_to_log \
      "This terminal application already has Accessibility permission. No additional action required."
    report_end_phase_standard
    return 0
  fi

  report_to_log \
    "The currently running terminal application needs, but doesn’t have, Accessibility permission."

  if [[ ! -t 0 ]]; then
    report_fail \
      "Terminal lacks Accessibility permission and there is no interactive session in which to fix it."
    report_end_phase_standard
    return 1
  fi

  report_action_taken \
    "I will open (a) the Accessibility panel in System Settings and (b) a Quick Look window with instructions."

  launch_app_and_prompt_user_to_act \
    --no-app \
    --open "$SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_ACCESSIBILITY" \
    --show-doc "${GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY}/accessibility_permissions_how_to_configure.md" \
    "Follow the instructions in the Quick Look window to grant the current terminal app Accessibility permission"

  # Do not depend solely on the user's confirmation. Verify the permission again.
  if terminal_can_emit_keystrokes; then
    report_success \
      "Confirmed that the terminal application can now emit keystrokes."
    report_end_phase_standard
    return 0
  fi

  report_fail \
    "The terminal application still cannot emit keystrokes. Accessibility permission may not have been enabled yet."
  report_end_phase_standard
  return 1
}

function terminal_can_emit_keystrokes() {
  # Tests whether the current terminal app can emit keystrokes as a test for whether additional macOS Accessibility permissions are necessary.
  /usr/bin/osascript >/dev/null 2>&1 <<'APPLESCRIPT'
tell application "System Events"
  key code 56 -- Shift
end tell
APPLESCRIPT
}
