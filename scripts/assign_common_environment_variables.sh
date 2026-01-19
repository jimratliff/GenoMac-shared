#!/usr/bin/env zsh

# Establishes values for environment variables shared by both GenoMac-system and GenoMac-user 

set -euo pipefail

GENOMAC_NAMESPACE="com.virtualperfection.genomac"

# Specify a variable that, when expanded, is a newline character
# I can use $NEWLINE inside arguments to my `report()` series functions without changing how 
# I quote strings.
NEWLINE=$'\n'

# Specify the location of the user’s `Dropbox` directory
# Although currently (1/2/2026) used only by GenoMac-user, it may well be soon used by
#   GenoMac-system as a place from which to obtain resources for user creation (such as
#   profile avatars. For this reason, I’m including this environment variable in GenoMac-shared.
#
# TODO: GENOMAC_USER_DROPBOX_DIRECTORY should be refactored to USER_DROPBOX_DIRECTORY
#       because GENOMAC_USER_DROPBOX_DIRECTORY misleadingly suggests it’s associated
#       with the GenoMac-user repo, rather than as intended: the location of the user’s
#       Dropbox directory within the user’s home directory.
GENOMAC_USER_DROPBOX_DIRECTORY="$HOME/Library/CloudStorage/Dropbox"

############### Related to cloning GenoMac-user
# Note: These variables must be available to GenoMac-system because that repo has a script
#       that facilitates cloning GenoMac-user
# Specify local directory into which the GenoMac-user repository will be cloned
GENOMAC_USER_LOCAL_DIRECTORY="$HOME/.genomac-user"
# Specify URL for cloning the public GenoMac-user repository using HTTPS
GENOMAC_USER_REPO_URL="https://github.com/jimratliff/GenoMac-user.git"

############### Location of submodule within each GenoMac-system and GenoMac-user repo
GENOMAC_SUBMODULE_DIRECTORY="external/genomac-shared"

############### Custom alert sound
# (These environment variables are located in GenoMac-shared because (a) GenoMac-system *installs*
# the custom alert sound but (b) it is GenoMac-user that *consumes* the alert sound, so both the
# -system and -user repos need to know the installation location.)

# Systemwide directory that stores available alert sounds
SYSTEM_ALERT_SOUNDS_DIRECTORY="/Library/Audio/Sounds/Alerts"

# Name of custom-chosen alert sound
CUSTOM_ALERT_SOUND_FILENAME="Uh_oh.aiff"

# Path to installed custom alert sound
PATH_TO_INSTALLED_CUSTOM_ALERT_SOUND_FILE="${SYSTEM_ALERT_SOUNDS_DIRECTORY}/${CUSTOM_ALERT_SOUND_FILENAME}"

############### GENOMAC_ALERT_LOG
# Creates and names a temporary file to accumulate warning/failure messages for
#   later regurgitation at the end of a main script.
# Only create if not already defined (e.g. nested/nested sourcing)
if [[ -z "${GENOMAC_ALERT_LOG-}" ]]; then
  local tmpdir="${TMPDIR:-/tmp}"
  GENOMAC_ALERT_LOG="$(mktemp "${tmpdir}/genomac_alerts.XXXXXX")"
fi

############### State-related

GENOMAC_STATE_FILE_EXTENSION="state"

GENOMAC_STATE_PERSISTENCE_PERMANENT="PERM"
GENOMAC_STATE_PERSISTENCE_SESSION="SESH"

# Despite each being seemingly specific to either GenoMac-system or GenoMac-user,
#   these two environment variables are defined in GenoMac-shared because:
#   - GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY is used by GenoMac-user, because GenoMac-user *can*
#     care about system-level state
#   - GENOMAC_USER_LOCAL_STATE_DIRECTORY appears in helpers-state.sh » _state_directory_for_scope()
#     (although that reference should never be encountered in the normal operation of GenoMac-user)

# Specify local directory in which machine-level state can be stored
GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY="/etc/genomac/state"
# Specify local directory that will retain user-level state information
GENOMAC_USER_LOCAL_STATE_DIRECTORY="${GENOMAC_USER_LOCAL_DIRECTORY}-state"

############### Homebrew-related
#
# NOTE: Even though Homebrew seems directly related only to GenoMac-system rather than
#       GenoMac-user, the below code (a) enforcing the presence of Homebrew and (b) setting
#       HOMEBREW_PREFIX *is* used by GenoMac-user.
# --- Homebrew: hard dependency ------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  # First attempt failed - try adding Homebrew to PATH and retry
  if [ -x /opt/homebrew/bin/brew ]; then
    # Homebrew exists but isn't in PATH - fix temporarily
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! command -v brew >/dev/null 2>&1; then
      echo "❌ Homebrew installation appears corrupted. Aborting."
      exit 1
    fi
  else
    echo "❌ Homebrew is required but not installed. Aborting."
    exit 1
  fi
fi

# Resolve once (don’t recompute if already set by the environment)
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(/usr/bin/env brew --prefix)}"

############### Bundle IDs

# Bundle IDs for apps
BUNDLE_ID_1PASSWORD="com.1password.1password"
BUNDLE_ID_ALAN_APP="studio.retina.Alan"
BUNDLE_ID_ALFRED="com.runningwithcrayons.Alfred"
BUNDLE_ID_BBEDIT="com.barebones.bbedit"
BUNDLE_ID_BETTERTOUCHTOOL="com.hegenberg.BetterTouchTool"
BUNDLE_ID_CLAUDE="com.anthropic.claudefordesktop"
BUNDLE_ID_DISKUTILITY="com.apple.DiskUtility"
BUNDLE_ID_DROPBOX="com.getdropbox.dropbox"
BUNDLE_ID_ELMEDIA_PLAYER_MAS="com.Eltima.ElmediaPlayer.MAS"
BUNDLE_ID_GLANCE="com.chamburr.Glance"
BUNDLE_ID_ITERM2="com.googlecode.iterm2"
BUNDLE_ID_KEYBOARDMAESTRO_EDITOR="com.stairways.keyboardmaestro.editor"
BUNDLE_ID_KEYBOARDMAESTRO_ENGINE="com.stairways.keyboardmaestro.engine"
BUNDLE_ID_MICROSOFT_WORD="com.microsoft.Word"
BUNDLE_ID_PLAIN_TEXT_EDITOR="com.sindresorhus.Plain-Text-Editor"
BUNDLE_ID_PREVIEW="com.apple.Preview"
BUNDLE_ID_TERMINAL="com.apple.Terminal"
BUNDLE_ID_TEXTEDIT="com.apple.TextEdit"
BUNDLE_ID_TEXTEXPANDER="com.smileonmymac.textexpander"

############### Domain for defaults write commands
DEFAULTS_DOMAINS_ALFRED="com.runningwithcrayons.Alfred-Preferences"
DEFAULTS_DOMAINS_KEYBOARD_MAESTRO="com.stairways.keyboardmaestro"
DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_EDITOR="com.stairways.keyboardmaestro.editor"
DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_ENGINE="com.stairways.keyboardmaestro.engine"
DEFAULTS_DOMAINS_ITERM2="com.googlecode.iterm2"

############### Privacy & Security panel URLs
PRIVACY_SECURITY_PANEL_URL_STUB="x-apple.systempreferences:com.apple.preference.security"
PRIVACY_SECURITY_PANEL_URL_MAIN="${PRIVACY_SECURITY_PANEL_URL_STUB}?Privacy"
PRIVACY_SECURITY_PANEL_URL_FULL_DISK="${PRIVACY_SECURITY_PANEL_URL_STUB}?Privacy_AllFiles"
PRIVACY_SECURITY_PANEL_URL_ACCESSIBILITY="${PRIVACY_SECURITY_PANEL_URL_STUB}?Privacy_Accessibility"
PRIVACY_SECURITY_PANEL_URL_SCREEN_RECORDING="${PRIVACY_SECURITY_PANEL_URL_STUB}?Privacy_ScreenCapture"


############### Export and report
echo "Exporting environment variables common to both GenoMac-system and GenoMac-user"

function export_and_report() {
  local var_name="$1"
  echo "export $var_name: '${(P)var_name}'"
  export "$var_name"
}

export_and_report CUSTOM_ALERT_SOUND_FILENAME
export_and_report GENOMAC_ALERT_LOG
export_and_report GENOMAC_NAMESPACE
export_and_report GENOMAC_SUBMODULE_DIRECTORY
export_and_report GENOMAC_STATE_FILE_EXTENSION
export_and_report GENOMAC_STATE_PERSISTENCE_PERMANENT
export_and_report GENOMAC_STATE_PERSISTENCE_SESSION
export_and_report GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY
export_and_report GENOMAC_USER_DROPBOX_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_STATE_DIRECTORY
export_and_report GENOMAC_USER_REPO_URL
export_and_report HOMEBREW_PREFIX
export_and_report NEWLINE
export_and_report PATH_TO_INSTALLED_CUSTOM_ALERT_SOUND_FILE
export_and_report SYSTEM_ALERT_SOUNDS_DIRECTORY

export_and_report BUNDLE_ID_1PASSWORD
export_and_report BUNDLE_ID_ALAN_APP
export_and_report BUNDLE_ID_ALFRED
export_and_report BUNDLE_ID_BBEDIT
export_and_report BUNDLE_ID_BETTERTOUCHTOOL
export_and_report BUNDLE_ID_CLAUDE
export_and_report BUNDLE_ID_DISKUTILITY
export_and_report BUNDLE_ID_DROPBOX
export_and_report BUNDLE_ID_ELMEDIA_PLAYER_MAS
export_and_report BUNDLE_ID_GLANCE
export_and_report BUNDLE_ID_ITERM2
export_and_report BUNDLE_ID_KEYBOARDMAESTRO_EDITOR
export_and_report BUNDLE_ID_KEYBOARDMAESTRO_ENGINE
export_and_report BUNDLE_ID_MICROSOFT_WORD
export_and_report BUNDLE_ID_PLAIN_TEXT_EDITOR
export_and_report BUNDLE_ID_PREVIEW
export_and_report BUNDLE_ID_TERMINAL
export_and_report BUNDLE_ID_TEXTEDIT
export_and_report BUNDLE_ID_TEXTEXPANDER

export_and_report DEFAULTS_DOMAINS_ALFRED
export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO
export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_EDITOR
export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_ENGINE
export_and_report DEFAULTS_DOMAINS_ITERM2

export_and_report PRIVACY_SECURITY_PANEL_URL_ACCESSIBILITY
export_and_report PRIVACY_SECURITY_PANEL_URL_FULL_DISK
export_and_report PRIVACY_SECURITY_PANEL_URL_MAIN
export_and_report PRIVACY_SECURITY_PANEL_URL_SCREEN_RECORDING
