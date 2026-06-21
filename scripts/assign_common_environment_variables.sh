#!/usr/bin/env zsh

# Establishes values for environment variables shared by both GenoMac-system and GenoMac-user 

# Relies upon:
#   helpers-misc.sh
#   - set_env_var_if_not_set()

# Specify location of PlistBuddy
PLISTBUDDY_PATH='/usr/libexec/PlistBuddy'

############### GENOMAC_ALERT_LOG
# Creates, if necessary, and names a temporary file to accumulate warning/failure messages for
#   later regurgitation at the end of a main script.
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
GENOMAC_PRIVATE_REPO_NAME="GenoMac-private"

# GENOMAC_USER_HTTP_REPO_URL is used by GenoMac-system when it clones GenoMac-user for USER_CONFIGURER
GENOMAC_USER_HTTP_REPO_URL="${GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT}/${GENOMAC_USER_REPO_NAME}.git"

############### Compute location of GenoMac-shared submodule within each GenoMac-system and GenoMac-user repo
# Get path of THIS script, even when sourced
# Explanation:
# %x — zsh prompt escape meaning "path of the script being sourced"
# ${(%):-%x} — trick to evaluate a prompt escape outside a prompt (the (%) flag)
# ${...:A} — resolve to absolute path
# So ${${(%):-%x}:A} means "the absolute path of the file currently being sourced."
this_script_path="${${(%):-%x}:A}"                  
this_scripts_directory=${this_script_path:h}
# In the following, "xxxx" is either (a) "user" or (b) "system" depending on which of the two repos you’re in.
GENOMAC_SHARED_ROOT="${this_scripts_directory:h}" # ~/.genomac-xxxx/external/genomac-shared
GENOMAC_SHARED_RESOURCE_DIRECTORY="${GENOMAC_SHARED_ROOT}/resources" # ~/.genomac-xxxx/external/genomac-shared/resources
GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY="${GENOMAC_SHARED_RESOURCE_DIRECTORY}/docs_to_display_to_user" # ~/.genomac-xxxx/external/genomac-shared/resources/docs_to_display_to_user

############### Local directories
# NOTE: These environment variables are located in GenoMac-shared because (a) each is the basis for the name of
#       its repo’s state-management directory and (b) each repo can have a reason to read/write state in the
#       other repo’s state directory.
GENOMAC_SYSTEM_LOCAL_DIRECTORY="$HOME/.genomac-system"
GENOMAC_USER_LOCAL_DIRECTORY="$HOME/.genomac-user"

# Resolve once (don’t recompute if already set by the environment)
HOMEBREW_PREFIX="$(get_homebrew_prefix)"

# Local directory for development clones of Project GenoMac repos
# NOTE: Although GenoMac-system and GenoMac-user are *executed* from clones at ~/.genomac-system and ~/.genomac-user,
#       respectively, for flexibility in development (e.g., checking out new branches), the development clones
#       should be separate.
USER_LOCAL_REPOSITORY_DIRECTORY="$HOME/Repositories
GENOMAC_DEVELOPMENT_DIRECTORY="${USER_LOCAL_REPOSITORY_DIRECTORY}/Project_GenoMac"


# Local directory for custom alert sound
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

# Specify the local directory in which preferences and other files shared across users are stored
# These may contain secrets, so this directory is NOT within a repo
# E.g., this would be within each user’s Dropbox directory.
GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY="${LOCAL_DROPBOX_DIRECTORY}/Preferences_common"

###

# GENOMAC_NAMESPACE is used whenever a script needs to create a file or folder
# in an area available to others
GENOMAC_NAMESPACE="com.virtualperfection.genomac"

############### Hypervisor related
HYPERVISOR_MAKE_COMMAND_STRING="just run-hypervisor"
HYPERVISOR_HOW_TO_RESTART_STRING="To restart, re-execute ${HYPERVISOR_MAKE_COMMAND_STRING} and we’ll pick up where we left off."
###

############### State-related

GENOMAC_STATE_FILE_EXTENSION="state"
GENOMAC_STATE_PERSISTENCE_PERMANENT="PERM"
GENOMAC_STATE_PERSISTENCE_SESSION="SESH"

# The Hypervisor of each of GenoMac-system and GenoMac-user sets the state SESH_SESSION_HAS_STARTED
# at the beginning of the session so that the Welcome banner can distinguish between its initial
# run at the start of a session and a subsequent run after an encouraged logout.
SESH_SESSION_HAS_STARTED="SESH_Session_has_started"

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
# PERM_THIS_USER_IS_A_USER_CONFIGGER="PERM_this_user_is_a_user_configger"

# Delimiters to separate fields in state strings
GENOMAC_STATE_STRING_DELIMITER_A="∞§¶"
GENOMAC_STATE_STRING_DELIMITER_B="¶§∞"
GENOMAC_STATE_STRING_DELIMITER_C="§∞¶"
GENOMAC_STATE_STRING_DELIMITER_X="¶∞§"

# User created and configured states
GENOMAC_STATE_USER_EXISTS_PREFIX="USER_EXISTS"
GENOMAC_STATE_USER_IS_PENDING_INITIAL_CONFIGURATION_PREFIX="USER_AWAITS_INITIAL_CONFIG"

# User-attribute state
GENOMAC_STATE_USER_ATTRIBUTE_PREFIX="USER_ATTRIBUTE"
# GENOMAC_STATE_USER_CLASS_PREFIX="USER_CLASS"
# GENOMAC_STATE_USER_HAS_AN_ATTRIBUTE_PREFIX="USER_HAS_ATTRIBUTE'

USER_ATTRIBUTE_TOUCH_ID_PREFIX="touchid${GENOMAC_STATE_STRING_DELIMITER_X}"
USER_ATTRIBUTE_CHESSPLAYER="chessplayer"
USER_ATTRIBUTE_DEVELOPER="developer"
USER_ATTRIBUTE_DROPBOX="dropbox"
USER_ATTRIBUTE_EMAILER="emailer"
USER_ATTRIBUTE_GENOMAC_DEVELOPER="genomac-developer"
USER_ATTRIBUTE_IS_USER_CONFIGURER="IS_USER_CONFIGURER"
USER_ATTRIBUTE_MAC_ADMIN="mac-admin"
USER_ATTRIBUTE_MICROSOFT_WORD="microsoft-word"
USER_ATTRIBUTE_OBSIDIAN_USER="obsidian-user"
USER_ATTRIBUTE_RAINDROP_IO="raindrop-io"
USER_ATTRIBUTE_SYNC_COM="sync-com"
USER_ATTRIBUTE_TOUCH_ID_ROOT="touchid"
USER_ATTRIBUTE_TOUCH_ID_PREFIX="${USER_ATTRIBUTE_TOUCH_ID_ROOT}${GENOMAC_STATE_STRING_DELIMITER_X}"
USER_ATTRIBUTE_YOUTUBE_WATCHER="youtube-watcher"
# USER_ATTRIBUTE_AUTHENTICATE_GITHUB_VIA_1PASSWORD="authenticate_github_via_1password"
# USER_ATTRIBUTE_COMMIT_ON_GITHUB="commit_on_github"

# GENOMAC_STATE_USER_CONFIGURER_DEFAULT_ATTRIBUTES should NOT be exported,
# because the environment cannot carry arrays.
typeset -ga GENOMAC_STATE_USER_CONFIGURER_DEFAULT_ATTRIBUTES
GENOMAC_STATE_USER_CONFIGURER_DEFAULT_ATTRIBUTES=(
  "$USER_ATTRIBUTE_MAC_ADMIN" \
  "$USER_ATTRIBUTE_DROPBOX" \
  "$USER_ATTRIBUTE_GENOMAC_DEVELOPER"
  )

# Migration related
MIGRATION_STATE_PREFIX="MIGRATION_ID_"

############### Miscellaneous
# Specify a variable that, when expanded, is a newline character
# I can use $NEWLINE inside arguments to my `report()` series functions without changing how 
# I quote strings.
NEWLINE=$'\n'

############### Reporting
SESH_VERBOSITY_USER_WANTS_IT="SESH_verbosity_user_wants_it"
# GENOMAC_VERBOSE="true"

# The following are defined in each of GenoMac-system and GenoMac-user
# GM_LOGS_DIRECTORY: either "$HOME/.genomac-user-logs" or "$HOME/.genomac-system-logs"
# GM_LOG_FILE: a time-stamped file in GM_LOGS_DIRECTORY

############### Bundle IDs

# Bundle IDs for apps
BUNDLE_ID_1PASSWORD="com.1password.1password"
BUNDLE_ID_ACTIVITY_MONITOR="com.apple.ActivityMonitor"
BUNDLE_ID_ALAN_APP="studio.retina.Alan"
BUNDLE_ID_ALFRED="com.runningwithcrayons.Alfred"
BUNDLE_ID_APP_STORE="com.apple.AppStore"
BUNDLE_ID_BBEDIT="com.barebones.bbedit"
BUNDLE_ID_BETTERTOUCHTOOL="com.hegenberg.BetterTouchTool"
BUNDLE_ID_BRAVE="com.brave.Browser"
BUNDLE_ID_CALENDAR="com.apple.iCal"
BUNDLE_ID_CLAUDE="com.anthropic.claudefordesktop"
BUNDLE_ID_CONTACTS="com.apple.AddressBook"
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
BUNDLE_ID_NOTES="com.apple.Notes"
BUNDLE_ID_OBSIDIAN="md.obsidian"
BUNDLE_ID_ORION="com.kagi.kagimacOS"
BUNDLE_ID_PLAIN_TEXT_EDITOR="com.sindresorhus.Plain-Text-Editor"
BUNDLE_ID_PREVIEW="com.apple.Preview"
BUNDLE_ID_QUICKTIMEPLAYER="com.apple.QuickTimePlayerX"
BUNDLE_ID_REMINDERS="com.apple.reminders"
BUNDLE_ID_SAFARI="com.apple.safari"
BUNDLE_ID_STICKIES="com.apple.Stickies"
BUNDLE_ID_SYNC_COM="com.sync.desktop"
BUNDLE_ID_SYSTEM_SETTINGS="com.apple.systempreferences"
BUNDLE_ID_TERMINAL="com.apple.Terminal"
BUNDLE_ID_TEXTEDIT="com.apple.TextEdit"
BUNDLE_ID_TEXTEXPANDER="com.smileonmymac.textexpander"
BUNDLE_ID_TV="com.apple.TV"
BUNDLE_ID_WATERFOX="net.waterfox.waterfox"

############### Domain for defaults write commands
DEFAULTS_DOMAINS_ALFRED="com.runningwithcrayons.Alfred-Preferences"
DEFAULTS_DOMAINS_KEYBOARD_MAESTRO="com.stairways.keyboardmaestro"
DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_EDITOR="com.stairways.keyboardmaestro.editor"
DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_ENGINE="com.stairways.keyboardmaestro.engine"
DEFAULTS_DOMAINS_HELIUM="net.imput.helium"
DEFAULTS_DOMAINS_ITERM2="com.googlecode.iterm2"
DEFAULTS_DOMAINS_ORION="com.kagi.kagimacOS"
DEFAULTS_DOMAINS_PREVIEW="com.apple.Preview"
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
SYSTEM_SETTINGS_TOUCH_ID_AND_PASSWORD_URL="x-apple.systempreferences:com.apple.Touch-ID-Settings"
SYSTEM_SETTINGS_WALLPAPER_PANEL_URL="x-apple.systempreferences:com.apple.Wallpaper-Settings.extension"

############### Export and report
echo "Exporting environment variables common to both GenoMac-system and GenoMac-user"

function export_and_report() {
  local var_name="$1"
  echo "export $var_name: '${(P)var_name}'"
  export "$var_name"
}

# export_and_report CUSTOM_ALERT_SOUND_FILENAME
# export_and_report GENOMAC_ALERT_LOG
# export_and_report GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT
# export_and_report GENOMAC_COMMON_GITHUB_SCP_URL_ROOT
# export_and_report GENOMAC_DEVELOPMENT_DIRECTORY
# export_and_report GENOMAC_NAMESPACE
# export_and_report GENOMAC_PRIVATE_REPO_NAME
# export_and_report export_and_report GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY
# export_and_report GENOMAC_SHARED_REPO_NAME
# export_and_report GENOMAC_SHARED_RESOURCE_DIRECTORY
# export_and_report GENOMAC_SHARED_ROOT
# export_and_report GENOMAC_SCOPE_SYSTEM
# export_and_report GENOMAC_SCOPE_USER
# export_and_report GENOMAC_STATE_FILE_EXTENSION
# export_and_report GENOMAC_STATE_PERSISTENCE_PERMANENT
# export_and_report GENOMAC_STATE_PERSISTENCE_SESSION
# export_and_report GENOMAC_STATE_STRING_DELIMITER_A
# export_and_report GENOMAC_STATE_STRING_DELIMITER_B
# export_and_report GENOMAC_STATE_STRING_DELIMITER_C
# export_and_report GENOMAC_STATE_STRING_DELIMITER_X
# export_and_report GENOMAC_STATE_USER_ATTRIBUTE_PREFIX
# export_and_report GENOMAC_STATE_USER_CLASS_PREFIX
# export_and_report GENOMAC_STATE_USER_EXISTS_PREFIX
# export_and_report GENOMAC_STATE_USER_HAS_AN_ATTRIBUTE_PREFIX
# export_and_report GENOMAC_STATE_USER_IS_PENDING_INITIAL_CONFIGURATION_PREFIX
# export_and_report GENOMAC_SYSTEM_LOCAL_DIRECTORY
# export_and_report GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY
# export_and_report GENOMAC_SYSTEM_REPO_NAME
# export_and_report GENOMAC_USER_HTTP_REPO_URL
# export_and_report GENOMAC_USER_LOCAL_DIRECTORY
# export_and_report GENOMAC_USER_LOCAL_STATE_DIRECTORY
# export_and_report GENOMAC_USER_REPO_NAME
# export_and_report GENOMAC_USER_SHARED_PREFERENCES_DIRECTORY
# export_and_report GENOMAC_VERBOSE
# export_and_report HOMEBREW_PREFIX
# export_and_report HYPERVISOR_HOW_TO_RESTART_STRING
# export_and_report HYPERVISOR_MAKE_COMMAND_STRING
# export_and_report LOCAL_DROPBOX_DIRECTORY
# export_and_report MIGRATION_STATE_PREFIX
# export_and_report NEWLINE
# export_and_report PATH_TO_INSTALLED_CUSTOM_ALERT_SOUND_FILE
# export_and_report PERM_THIS_USER_IS_A_USER_CONFIGGER
# export_and_report PLISTBUDDY_PATH
# export_and_report SESH_SESSION_HAS_STARTED
# export_and_report SESH_VERBOSITY_USER_WANTS_IT
# export_and_report SYSTEM_ALERT_SOUNDS_DIRECTORY
# export_and_report USER_LOCAL_REPOSITORY_DIRECTORY
# 
# export_and_report BUNDLE_ID_1PASSWORD
# export_and_report BUNDLE_ID_ACTIVITY_MONITOR
# export_and_report BUNDLE_ID_ALAN_APP
# export_and_report BUNDLE_ID_ALFRED
# export_and_report BUNDLE_ID_APP_STORE
# export_and_report BUNDLE_ID_BBEDIT
# export_and_report BUNDLE_ID_BETTERTOUCHTOOL
# export_and_report BUNDLE_ID_BRAVE
# export_and_report BUNDLE_ID_CALENDAR
# export_and_report BUNDLE_ID_CLAUDE
# export_and_report BUNDLE_ID_CONTACTS
# export_and_report BUNDLE_ID_DISKUTILITY
# export_and_report BUNDLE_ID_DROPBOX
# export_and_report BUNDLE_ID_ELMEDIA_PLAYER_MAS
# export_and_report BUNDLE_ID_FIREFOX
# export_and_report BUNDLE_ID_GLANCE
# export_and_report BUNDLE_ID_GOOGLE_CHROME
# export_and_report BUNDLE_ID_HELIUM
# export_and_report BUNDLE_ID_ITERM2
# export_and_report BUNDLE_ID_KEYBOARDMAESTRO_EDITOR
# export_and_report BUNDLE_ID_KEYBOARDMAESTRO_ENGINE
# export_and_report BUNDLE_ID_MICROSOFT_WORD
# export_and_report BUNDLE_ID_NOTES
# export_and_report BUNDLE_ID_OBSIDIAN
# export_and_report BUNDLE_ID_ORION
# export_and_report BUNDLE_ID_PLAIN_TEXT_EDITOR
# export_and_report BUNDLE_ID_PREVIEW
# export_and_report BUNDLE_ID_QUICKTIMEPLAYER
# export_and_report BUNDLE_ID_REMINDERS
# export_and_report BUNDLE_ID_SAFARI
# export_and_report BUNDLE_ID_STICKIES
# export_and_report BUNDLE_ID_SYNC_COM
# export_and_report BUNDLE_ID_SYSTEM_SETTINGS
# export_and_report BUNDLE_ID_TERMINAL
# export_and_report BUNDLE_ID_TEXTEDIT
# export_and_report BUNDLE_ID_TEXTEXPANDER
# export_and_report BUNDLE_ID_TV
# export_and_report BUNDLE_ID_WATERFOX
# 
# 
# export_and_report DEFAULTS_DOMAINS_ALFRED
# export_and_report DEFAULTS_DOMAINS_HELIUM
# export_and_report DEFAULTS_DOMAINS_ITERM2
# export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO
# export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_EDITOR
# export_and_report DEFAULTS_DOMAINS_KEYBOARD_MAESTRO_ENGINE
# export_and_report DEFAULTS_DOMAINS_ORION
# export_and_report DEFAULTS_DOMAINS_PREVIEW
# export_and_report DEFAULTS_DOMAINS_SAFARI
# export_and_report DEFAULTS_DOMAINS_SYMBOLICHOTKEYS
# export_and_report DEFAULTS_DOMAINS_WATERFOX
# 
# export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_ACCESSIBILITY
# export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_FULL_DISK
# export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_MAIN
# export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_SCREEN_RECORDING
# export_and_report SYSTEM_SETTINGS_PRIVACY_SECURITY_PANEL_URL_STUB
# export_and_report SYSTEM_SETTINGS_TOUCH_ID_AND_PASSWORD_URL
# export_and_report SYSTEM_SETTINGS_WALLPAPER_PANEL_URL
# 
# export_and_report USER_ATTRIBUTE_TOUCH_ID_PREFIX
# export_and_report USER_ATTRIBUTE_CHESSPLAYER
# export_and_report USER_ATTRIBUTE_DEVELOPER
# export_and_report USER_ATTRIBUTE_DROPBOX
# export_and_report USER_ATTRIBUTE_EMAILER
# export_and_report USER_ATTRIBUTE_GENOMAC_DEVELOPER
# export_and_report USER_ATTRIBUTE_IS_USER_CONFIGURER
# export_and_report USER_ATTRIBUTE_MAC_ADMIN
# export_and_report USER_ATTRIBUTE_MICROSOFT_WORD
# export_and_report USER_ATTRIBUTE_OBSIDIAN_USER
# export_and_report USER_ATTRIBUTE_RAINDROP_IO
# export_and_report USER_ATTRIBUTE_SYNC_COM
# export_and_report USER_ATTRIBUTE_TOUCH_ID_PREFIX
# export_and_report USER_ATTRIBUTE_TOUCH_ID_ROOT
# export_and_report USER_ATTRIBUTE_YOUTUBE_WATCHER
export_and_report USER_ATTRIBUTE_YOUTUBE_WATCHER
