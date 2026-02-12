#!/usr/bin/env zsh

# Establishes values for environment variables shared by both GenoMac-system and GenoMac-user 

# Relies upon:
#   helpers-misc.sh
#   - set_env_var_if_not_set()

############### GENOMAC_ALERT_LOG
# Creates and names a temporary file to accumulate warning/failure messages for
#   later regurgitation at the end of a main script.
# Only create if not already defined (e.g. nested/nested sourcing)
if [[ -z "${GENOMAC_ALERT_LOG-}" ]]; then
  local tmpdir="${TMPDIR:-/tmp}"
  GENOMAC_ALERT_LOG="$(mktemp "${tmpdir}/genomac_alerts.XXXXXX")"
  # E.g., '/var/folders/3k/rjdqbxcn3s5dw3ktj883__br0000gp/T//genomac_alerts.W1DICe'
fi

############### Repository specifiers
GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT="https://github.com/jimratliff"
GENOMAC_COMMON_GITHUB_SCP_URL_ROOT="git@github.com:jimratliff"
GENOMAC_SHARED_REPO_NAME="GenoMac-shared"
GENOMAC_SYSTEM_REPO_NAME="GenoMac-system"
GENOMAC_USER_REPO_NAME="GenoMac-user"
GENOMAC_USER_HTTP_REPO_URL="${GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT}/${GENOMAC_USER_REPO_NAME}.git"

############### Location of submodule within each GenoMac-system and GenoMac-user repo
# Get path of THIS script, even when sourced
# Explanation:
# %x — zsh prompt escape meaning "path of the script being sourced"
# ${(%):-%x} — trick to evaluate a prompt escape outside a prompt (the (%) flag)
# ${...:A} — resolve to absolute path
# So ${${(%):-%x}:A} means "the absolute path of the file currently being sourced."
this_script_path="${${(%):-%x}:A}"                  
this_scripts_directory=${this_script_path:h}
GENOMAC_SHARED_ROOT="${this_scripts_directory:h}" # ~/.genomac-system/external/genomac-shared
GENOMAC_SHARED_RESOURCE_DIRECTORY="${GENOMAC_SHARED_ROOT}/resources" # ~/.genomac-system/external/genomac-shared/resources
GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY="${GENOMAC_SHARED_RESOURCE_DIRECTORY}/docs_to_display_to_user" # ~/.genomac-system/external/genomac-shared/resources/docs_to_display_to_user

############### Local directories
# NOTE: These are located in GenoMac-shared because (a) each is the basis for the name of
#       its repo’s state-management directory and (b) each repo can have a reason to
#       read/write state in the other repo’s state directory.
GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system"
GENOMAC_USER_LOCAL_DIRECTORY="$HOME/.genomac-user"

# Resolve once (don’t recompute if already set by the environment)
HOMEBREW_PREFIX="$(get_homebrew_prefix)"

# Custom alert sound
# (These environment variables are located in GenoMac-shared because (a) GenoMac-system *installs*
# the custom alert sound but (b) it is GenoMac-user that *consumes* the alert sound, so both the
# -system and -user repos need to know the installation location.)
SYSTEM_ALERT_SOUNDS_DIRECTORY="/Library/Audio/Sounds/Alerts"
CUSTOM_ALERT_SOUND_FILENAME="Uh_oh.aiff"
PATH_TO_INSTALLED_CUSTOM_ALERT_SOUND_FILE="${SYSTEM_ALERT_SOUNDS_DIRECTORY}/${CUSTOM_ALERT_SOUND_FILENAME}" # /Library/Audio/Sounds/Alerts/Uh_oh.aiff

# User’s Dropbox directory
# Specify the location of the user’s `Dropbox` directory
# Although currently (1/2/2026) used only by GenoMac-user, it may well be soon used by
#   GenoMac-system as a place from which to obtain resources for user creation (such as
#   profile avatars). For this reason, I’m including this environment variable in GenoMac-shared.
LOCAL_DROPBOX_DIRECTORY="$HOME/Library/CloudStorage/Dropbox"

###

# GENOMAC_NAMESPACE is used whenever a script needs to create a file or folder
# in an area available to others
GENOMAC_NAMESPACE="com.virtualperfection.genomac"

############### Hypervisor related
HYPERVISOR_MAKE_COMMAND_STRING="make run-hypervisor"
HYPERVISOR_HOW_TO_RESTART_STRING="To restart, re-execute ${HYPERVISOR_MAKE_COMMAND_STRING} and we’ll pick up where we left off."
###

# Specify a variable that, when expanded, is a newline character
# I can use $NEWLINE inside arguments to my `report()` series functions without changing how 
# I quote strings.
NEWLINE=$'\n'

############### State-related

GENOMAC_STATE_FILE_EXTENSION="state"
GENOMAC_STATE_PERSISTENCE_PERMANENT="PERM"
GENOMAC_STATE_PERSISTENCE_SESSION="SESH"

GENOMAC_SCOPE_SYSTEM="system"
GENOMAC_SCOPE_USER="user"

# Despite each being seemingly specific to either GenoMac-system or GenoMac-user,
#   these two environment variables are defined in GenoMac-shared because:
#   - GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY might be used by GenoMac-user, because GenoMac-user *can*
#     care about system-level state
#   - GENOMAC_USER_LOCAL_STATE_DIRECTORY appears in helpers-state.sh » _state_directory_for_scope()
#     (although that reference should never be encountered in the normal operation of GenoMac-user)

# Specify local directory in which machine-level state can be stored
GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY="/etc/${GENOMAC_NAMESPACE}/state"  # /etc/com.virtualperfection.genomac/state
# Specify local directory that will retain user-level state information, e.g., ~/.genomac-user-state
GENOMAC_USER_LOCAL_STATE_DIRECTORY="${GENOMAC_USER_LOCAL_DIRECTORY}-state" # ~/.genomac-user-state

# User-domain state that must be accessible by system
PERM_THIS_USER_IS_A_USER_CONFIGGER="PERM_this_user_is_a_user_configger"

############### Bundle IDs

# Bundle IDs for apps
BUNDLE_ID_1PASSWORD="com.1password.1password"
BUNDLE_ID_ALAN_APP="studio.retina.Alan"
BUNDLE_ID_ALFRED="com.runningwithcrayons.Alfred"
BUNDLE_ID_APP_STORE="com.apple.AppStore"
BUNDLE_ID_BBEDIT="com.barebones.bbedit"
BUNDLE_ID_BETTERTOUCHTOOL="com.hegenberg.BetterTouchTool"
BUNDLE_ID_BRAVE="com.brave.Browser"
BUNDLE_ID_CLAUDE="com.anthropic.claudefordesktop"
BUNDLE_ID_DISKUTILITY="com.apple.DiskUtility"
BUNDLE_ID_DROPBOX="com.getdropbox.dropbox"
BUNDLE_ID_ELMEDIA_PLAYER_MAS="com.Eltima.ElmediaPlayer.MAS"
BUNDLE_ID_FIREFOX="org.mozilla.firefox"
BUNDLE_ID_GLANCE="com.chamburr.Glance"
BUNDLE_ID_GOOGLE_CHROME="com.google.chrome"
BUNDLE_ID_HELIUM="net.imput.helium"
BUNDLE_ID_ITERM2="com.googlecode.iterm2"
BUNDLE_ID_KEYBOARDMAESTRO_EDITOR="com.stairways.keyboardmaestro.editor"
BUNDLE_ID_KEYBOARDMAESTRO_ENGINE="com.stairways.keyboardmaestro.engine"
BUNDLE_ID_MICROSOFT_WORD="com.microsoft.Word"
BUNDLE_ID_ORION="com.kagi.kagimacOS"
BUNDLE_ID_PLAIN_TEXT_EDITOR="com.sindresorhus.Plain-Text-Editor"
BUNDLE_ID_PREVIEW="com.apple.Preview"
BUNDLE_ID_SAFARI="com.apple.safari"
BUNDLE_ID_TERMINAL="com.apple.Terminal"
BUNDLE_ID_TEXTEDIT="com.apple.TextEdit"
BUNDLE_ID_TEXTEXPANDER="com.smileonmymac.textexpander"
BUNDLE_ID_WATERFOX="net.waterfox.waterfox"

############### Domain for defaults write commands
DEFAULTS_DOMAINS_ALFRED="com.runningwithcrayons.Alfred-Preferences"
DEFAULTS_DOMAINS_KEYBOARD_MAESTRO="com.stairways.keyboardmaestro"
DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_EDITOR="com.stairways.keyboardmaestro.editor"
DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_ENGINE="com.stairways.keyboardmaestro.engine"
DEFAULTS_DOMAINS_HELIUM="net.imput.helium"
DEFAULTS_DOMAINS_ITERM2="com.googlecode.iterm2"
DEFAULTS_DOMAINS_ORION="com.kagi.kagimacOS"
DEFAULTS_DOMAINS_SAFARI="com.apple.Safari"
DEFAULTS_DOMAINS_SYMBOLICHOTKEYS="com.apple.symbolichotkeys"
DEFAULTS_DOMAINS_WATERFOX="net.waterfox.waterfox"

############### Privacy & Security panel URLs
# Not all of these are currently used, but this is a convenient place to memorialize ones
# that might be useful in the future
SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_STUB="x-apple.systempreferences:com.apple.preference.security"
SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_MAIN="${SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_STUB}?Privacy"
SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_FULL_DISK="${SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_STUB}?Privacy_AllFiles"
SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_ACCESSIBILITY="${SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_STUB}?Privacy_Accessibility"
SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_SCREEN_RECORDING="${SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_STUB}?Privacy_ScreenCapture"
SYSTEM_SETTINGS_WALLPAPER_PANEL_URL="x-apple.systempreferences:com.apple.Wallpaper-Settings.extension"

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
export_and_report GENOMAC_SCOPE_SYSTEM
export_and_report GENOMAC_SCOPE_USER
export_and_report GENOMAC_STATE_FILE_EXTENSION
export_and_report GENOMAC_STATE_PERSISTENCE_PERMANENT
export_and_report GENOMAC_STATE_PERSISTENCE_SESSION
export_and_report GENOMAC_SYSTEM_LOCAL_DIRECTORY
export_and_report GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY
export_and_report GENOMAC_SYSTEM_REPO_NAME
export_and_report GENOMAC_USER_HTTP_REPO_URL
export_and_report GENOMAC_USER_LOCAL_DIRECTORY
export_and_report GENOMAC_USER_LOCAL_STATE_DIRECTORY
export_and_report GENOMAC_USER_REPO_NAME
export_and_report HOMEBREW_PREFIX
export_and_report HYPERVISOR_HOW_TO_RESTART_STRING
export_and_report HYPERVISOR_MAKE_COMMAND_STRING
export_and_report LOCAL_DROPBOX_DIRECTORY
export_and_report NEWLINE
export_and_report PATH_TO_INSTALLED_CUSTOM_ALERT_SOUND_FILE
export_and_report PERM_THIS_USER_IS_A_USER_CONFIGGER
export_and_report SYSTEM_ALERT_SOUNDS_DIRECTORY

export_and_report BUNDLE_ID_1PASSWORD
export_and_report BUNDLE_ID_ALAN_APP
export_and_report BUNDLE_ID_ALFRED
export_and_report BUNDLE_ID_APP_STORE
export_and_report BUNDLE_ID_BBEDIT
export_and_report BUNDLE_ID_BETTERTOUCHTOOL
export_and_report BUNDLE_ID_BRAVE
export_and_report BUNDLE_ID_CLAUDE
export_and_report BUNDLE_ID_DISKUTILITY
export_and_report BUNDLE_ID_DROPBOX
export_and_report BUNDLE_ID_ELMEDIA_PLAYER_MAS
export_and_report BUNDLE_ID_FIREFOX
export_and_report BUNDLE_ID_GLANCE
export_and_report BUNDLE_ID_GOOGLE_CHROME
export_and_report BUNDLE_ID_HELIUM
export_and_report BUNDLE_ID_ITERM2
export_and_report BUNDLE_ID_KEYBOARDMAESTRO_EDITOR
export_and_report BUNDLE_ID_KEYBOARDMAESTRO_ENGINE
export_and_report BUNDLE_ID_MICROSOFT_WORD
export_and_report BUNDLE_ID_PLAIN_TEXT_EDITOR
export_and_report BUNDLE_ID_ORION
export_and_report BUNDLE_ID_PREVIEW
export_and_report BUNDLE_ID_SAFARI
export_and_report BUNDLE_ID_TERMINAL
export_and_report BUNDLE_ID_TEXTEDIT
export_and_report BUNDLE_ID_TEXTEXPANDER
export_and_report BUNDLE_ID_WATERFOX

export_and_report DEFAULTS_DOMAINS_ALFRED
export_and_report DEFAULTS_DOMAINS_HELIUM
export_and_report DEFAULTS_DOMAINS_ITERM2
export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO
export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_EDITOR
export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_ENGINE
export_and_report DEFAULTS_DOMAINS_ORION
export_and_report DEFAULTS_DOMAINS_SAFARI
export_and_report DEFAULTS_DOMAINS_SYMBOLICHOTKEYS
export_and_report DEFAULTS_DOMAINS_WATERFOX

export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_ACCESSIBILITY
export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_FULL_DISK
export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_MAIN
export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_SCREEN_RECORDING
export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_STUB
export_and_report SYSTEM_SETTINGS_WALLPAPER_PANEL_URL
