#!/usr/bin/env zsh

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

############### GENOMAC_ALERT_LOG
# Specify name of temporary file to accumulate warning/failure messages for
#   later regurgitation at the end of a main script.
# Only create if not already defined (e.g. nested/nested sourcing)
if [[ -z "${GENOMAC_ALERT_LOG-}" ]]; then
  local tmpdir="${TMPDIR:-/tmp}"
  GENOMAC_ALERT_LOG="$(mktemp "${tmpdir}/genomac_alerts.XXXXXX")"
fi

############### State-related

GENOMAC_STATE_FILE_EXTENSION="state"

# Specify local directory in which machine-level state can be stored
# The following environment variable, despite its name being specific to -system, is used
# by BOTH GenoMac-system and GenoMac-user
GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY="/etc/genomac/state"

############### Export and report
report_action_taken "Exporting environment variables common to both GenoMac-system and GenoMac-user"

function export_and_report() {
  local var_name="$1"
  report "export $var_name: '${(P)var_name}'"
  export "$var_name"
}

export_and_report GENOMAC_ALERT_LOG
export_and_report GENOMAC_STATE_FILE_EXTENSION
export_and_report GENOMAC_SYSTEM_LOCAL_STATE_DIRECTORY
export_and_report HOMEBREW_PREFIX
