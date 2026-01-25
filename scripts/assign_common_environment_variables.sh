#!/usr/bin/env zsh

# Establishes values for environment variables shared by both GenoMac-system and GenoMac-user 

# Is is assumed that the following has already been defined and exports:
#
# In the case of GenoMac-user:
#   GENOMAC_USER_LOCAL_DIRECTORY="$HOME/.genomac-user"

############### GENOMAC_ALERT_LOG
# Creates and names a temporary file to accumulate warning/failure messages for
#   later regurgitation at the end of a main script.
# Only create if not already defined (e.g. nested/nested sourcing)
if [[ -z "${GENOMAC_ALERT_LOG-}" ]]; then
  local tmpdir="${TMPDIR:-/tmp}"
  GENOMAC_ALERT_LOG="$(mktemp "${tmpdir}/genomac_alerts.XXXXXX")"
fi

# Repository specifiers
GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT="https://github.com/jimratliff"
GENOMAC_COMMON_GITHUB_SCP_URL_ROOT="git@github.com:jimratliff"
GENOMAC_SHARED_REPO_NAME="GenoMac-shared"
GENOMAC_SYSTEM_REPO_NAME="GenoMac-system"
GENOMAC_USER_REPO_NAME="GenoMac-user"

# Local directories
# GENOMAC_SYSTEM_LOCAL_DIRECTORY (set by GenoMac-system’s 0_initialize_me_first.sh, if run)
set_env_var_if_not_set "GENOMAC_SYSTEM_LOCAL_DIRECTORY" "$HOME/.genomac-system"
# GENOMAC_USER_LOCAL_DIRECTORY (set by GenoMac-user’s 0_initialize_me_first.sh, if run)
set_env_var_if_not_set "GENOMAC_USER_LOCAL_DIRECTORY" "$HOME/.genomac-user"

############### Related to cloning GenoMac-user
# Note: These variables must be available to GenoMac-system because that repo has a script
#       that facilitates cloning GenoMac-user

# WARNING: TODO: Below comment MAKES NO SENSE: "Assumed already defined/exported by GenoMac-user"
#                because it can’t be assumed that GenoMac-user has run, since this -shared repo
#                also works with GenoMac-system
# Specify local directory into which the GenoMac-user repository will be cloned
# GMU_LOCAL_DIRECTORY="$HOME/.genomac-user" # Assumed already defined/exported by GenoMac-user
# Specify URL for cloning the public GenoMac-user repository using HTTPS
GENOMAC_USER_REPO_URL="https://github.com/jimratliff/GenoMac-user.git"

GENOMAC_NAMESPACE="com.virtualperfection.genomac"

# Specify a variable that, when expanded, is a newline character
# I can use $NEWLINE inside arguments to my `report()` series functions without changing how 
# I quote strings.
NEWLINE=$'\n'

# Specify the location of the user’s `Dropbox` directory
# Although currently (1/2/2026) used only by GenoMac-user, it may well be soon used by
#   GenoMac-system as a place from which to obtain resources for user creation (such as
#   profile avatars). For this reason, I’m including this environment variable in GenoMac-shared.
LOCAL_DROPBOX_DIRECTORY="$HOME/Library/CloudStorage/Dropbox"



############### Location of submodule within each GenoMac-system and GenoMac-user repo
# NOTE: GenoMac-system (and presumably, after refactoring, so will GenoMac-user) exports a corresponding
#       environment variable (expressed from the perspective of the parent repo): 
#       GMS_HELPERS_DIR (external/genomac-shared/scripts)

this_scripts_directory=${0:A:h}
GENOMAC_SHARED_ROOT="${this_scripts_directory:h}"
GENOMAC_SHARED_RESOURCE_DIRECTORY="${GENOMAC_SHARED_ROOT}/resources"
GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY="${GENOMAC_SHARED_RESOURCE_DIRECTORY}/docs_to_display_to_user"

############### Custom alert sound
# (These environment variables are located in GenoMac-shared because (a) GenoMac-system *installs*
# the custom alert sound but (b) it is GenoMac-user that *consumes* the alert sound, so both the
# -system and -user repos need to know the installation location.)
SYSTEM_ALERT_SOUNDS_DIRECTORY="/Library/Audio/Sounds/Alerts"
CUSTOM_ALERT_SOUND_FILENAME="Uh_oh.aiff"
PATH_TO_INSTALLED_CUSTOM_ALERT_SOUND_FILE="${SYSTEM_ALERT_SOUNDS_DIRECTORY}/${CUSTOM_ALERT_SOUND_FILENAME}"

############### State-related

GENOMAC_STATE_FILE_EXTENSION="state"
GENOMAC_STATE_PERSISTENCE_PERMANENT="PERM"
GENOMAC_STATE_PERSISTENCE_SESSION="SESH"

# Despite each being seemingly specific to either GenoMac-system or GenoMac-user,
#   these two environment variables are defined in GenoMac-shared because:
#   - GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY might be used by GenoMac-user, because GenoMac-user *can*
#     care about system-level state
#   - GENOMAC_USER_LOCAL_STATE_DIRECTORY appears in helpers-state.sh » _state_directory_for_scope()
#     (although that reference should never be encountered in the normal operation of GenoMac-user)

# Specify local directory in which machine-level state can be stored
GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY="/etc/${GENOMAC_NAMESPACE}/state"
# Specify local directory that will retain user-level state information, e.g., ~/.genomac-user-state
GENOMAC_USER_LOCAL_STATE_DIRECTORY="${GMU_LOCAL_DIRECTORY}-state"

############### Bundle IDs

# Bundle IDs for apps
BUNDLE_ID_1PASSWORD="com.1password.1password"
BUNDLE_ID_ALAN_APP="studio.retina.Alan"
BUNDLE_ID_ALFRED="com.runningwithcrayons.Alfred"
BUNDLE_ID_APP_STORE="com.apple.AppStore"
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
# Not all of these are currently used, but this is a convenient place to memorialize ones
# that might be useful in the future
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
export_and_report GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT
export_and_report GENOMAC_COMMON_GITHUB_SCP_URL_ROOT
export_and_report GENOMAC_NAMESPACE
export_and_report GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY
export_and_report GENOMAC_SHARED_REPO_NAME
export_and_report GENOMAC_SHARED_RESOURCE_DIRECTORY
export_and_report GENOMAC_SHARED_ROOT
export_and_report GENOMAC_STATE_FILE_EXTENSION
export_and_report GENOMAC_STATE_PERSISTENCE_PERMANENT
export_and_report GENOMAC_STATE_PERSISTENCE_SESSION
export_and_report GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY
export_and_report GENOMAC_SYSTEM_REPO_NAME
export_and_report GENOMAC_USER_LOCAL_STATE_DIRECTORY
export_and_report GENOMAC_USER_REPO_NAME
export_and_report GENOMAC_USER_REPO_URL
export_and_report LOCAL_DROPBOX_DIRECTORY
export_and_report NEWLINE
export_and_report PATH_TO_INSTALLED_CUSTOM_ALERT_SOUND_FILE
export_and_report SYSTEM_ALERT_SOUNDS_DIRECTORY

export_and_report BUNDLE_ID_1PASSWORD
export_and_report BUNDLE_ID_ALAN_APP
export_and_report BUNDLE_ID_ALFRED
export_and_report BUNDLE_ID_APP_STORE
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
export_and_report DEFAULTS_DOMAINS_ITERM2
export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO
export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_EDITOR
export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_ENGINE

export_and_report PRIVACY_SECURITY_PANEL_URL_ACCESSIBILITY
export_and_report PRIVACY_SECURITY_PANEL_URL_FULL_DISK
export_and_report PRIVACY_SECURITY_PANEL_URL_MAIN
export_and_report PRIVACY_SECURITY_PANEL_URL_SCREEN_RECORDING
export_and_report PRIVACY_SECURITY_PANEL_URL_STUB
