#!/usr/bin/env zsh

############### Helpers: Related to shell operations

# Relies upon:
#   helpers-reporting.sh

function export_and_report() {
  local var_name="$1"
  report_to_log "Export $var_name: '${(P)var_name}'"
  export "$var_name"
}

function keep_sudo_alive() {
  # Keeps the current sudo authorization active in the background for the lifetime of this shell.
  
  # Don't spawn another loop if one is already running
  if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
    if ! sudo -v; then
      report_warning "Unable to refresh sudo authorization"
    fi
    return 0
  fi

  if ! sudo -v; then
    report_warning "Unable to initialize sudo keepalive"
    return 0
  fi

  local parent_pid=$$

  while kill -0 "$parent_pid" 2>/dev/null; do
    if ! sudo -n -v; then
      report_warning "Warning: sudo keepalive lost its authorization"
      exit 1  # exits only the background job
    fi
    sleep 60
  done 2>/dev/null &

  SUDO_KEEPALIVE_PID=$!
}

function safe_source() {
  # Sources supplied file.
  # Usage:
  #  safe_source "${GMU_PREFS_SCRIPTS}/set_safari_settings.sh"
  
  # report_start_phase_standard
  local file="$1"
  report_to_log "Sourcing ${file}"
  source "$file"
  report_to_log "${SYMBOL_SUCCESS} Sourced ${file}"
  
  # report_end_phase_standard
}

function require_mandatory_parameters() {
  # Validate that each named variable has a nonblank value.
  #
  # Arguments are alternating pairs:
  #   <variable_name> <option_name>
  # The <option_name> is supplied so that the error message can name the option name when 
  # variable name is not defined.
  #
  # Example:
  #   require_mandatory_parameters \
  #     short_name      --short-name \
  #     uid             --uid \
  #     home            --home \
  #     admin_user_name --admin-user-name

  local variable_name option_name

  while (( $# > 0 )); do
    variable_name="$1"
    option_name="$2"
    shift 2

    if [[ -z "${(P)variable_name}" ]]; then
      report_fail "Missing mandatory parameter ${option_name}."
      return 1
    fi
  done
}

function required_value_for_option() {
  # Validate and echo the value following an option that requires an argument.
  #
  # Intended for hand-rolled option parsers. e.g.:
  #
  #   --container <apfs container reference>
  #   --volume    <volume name>
  #
  # This rejects both:
  #
  #   --container
  #   --container --volume "Some_Volume"
  #
  # Usage:
  #
  #   apfs_container=$(required_value_for_option "$1" "${2-}") || return 1
  #   shift 2
  #
  #   More explicitly:
  #       while (( $# > 0 )); do
  #         case "$1" in
  #           --container)
  #             apfs_container=$(required_value_for_option "$1" "${2-}") || return 1
  #             shift 2
  #             ;;
  #           --startup-container)
  #             use_startup_container=true
  #             shift
  #             ;;
  #           --volume-name)
  #             vol_name=$(required_value_for_option "$1" "${2-}") || return 1
  #             shift 2
  #             ;;
  #           *)
  #             report_fail "Unknown parameter: $1"
  #             return 1
  #             ;;
  #         esac
  #       done
  #
  #
  # The "${2-}" form is important under `set -u`: it safely expands to the empty
  # string if $2 is unset, rather than triggering an unbound-parameter error
  # before this helper can produce a friendly error message.
  #
  # Return status:
  #   0 = value is valid; value is echoed to stdout
  #   1 = value is missing, blank, or appears to be another long option

  local option_name="$1"
  local option_value="${2-}"

  if [[ -z "$option_value" ]]; then
    report_fail "Missing value for ${option_name}."
    return 1
  fi

  if [[ "$option_value" == --* ]]; then
    report_fail "Missing value for ${option_name}; got another option instead: ${option_value}"
    return 1
  fi

  print -r -- "$option_value"
}

function set_env_var_if_not_set() {
  # TODO: This is likely DEPRECATED because it is no longer used.
  #
  # Sets an environment variable to a default value if it’s not already defined.
  #
  # $1: the name of the environment variable
  # $2: the default value to set if the variable is not already defined
  #
  # Usage:
  #   set_env_var_if_not_set "GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT" "https://github.com/jimratliff"

  local var_name="$1"
  local default_value="$2"

  # NOTES regarding the below:
  # - The ${!var_name} is bash indirect expansion. It treats the value of var_name as the name of another variable and returns that variable’s value.
  # - The :- handles the set -u case, preventing an error if the variable is unset.

  if [[ -z "${!var_name:-}" ]]; then
    export "$var_name"="$default_value"
  fi
}

