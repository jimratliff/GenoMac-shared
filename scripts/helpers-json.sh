#!/usr/bin/env zsh

# Assumes that jq has been installed.

function populate_associative_array_from_json_object_of_scalars() {
	# Populate a shell associative array from a JSON object selected by jq.
	#
	# Purpose:
	#   Given:
	#     (1) a JSON string,
	#     (2) a jq path that resolves to a JSON object,
	#     (3) the name of a target associative array,
	#   populate that associative array with the key/value pairs from the JSON object.
	#
	# Expected JSON shape at jq_path:
	#   The jq path must resolve to a JSON object whose entries are simple scalar values,
	#   e.g.
	#     {
	#       "personal": "personal_volume",
	#       "work": "work_volume"
	#     }
	#
	# Arguments:
	#   $1  json_input
	#       The full JSON document as a string.
	#
	#   $2  jq_path
	#       A jq expression identifying the object to read from within json_input,
	#       e.g. '.user_spawn_config.volume_key_from_user_class'
	#
	#   $3  target_array_name
	#       The name of the associative array to populate,
	#       e.g. 'volume_key_from_user_class'
  #
  #   The target array should already be declared as an associative array by the caller:
  #   local -A volume_name_from_user_class
	#
	# Behavior:
	#   - Clears any existing contents of the target associative array.
	#   - Re-populates it from the JSON object at jq_path.
	#   - Returns 0 on success, 1 on failure.
	#
	# Notes:
	#   - The target array is accessed by name via a zsh nameref (typeset -n).
	#   - The jq path should resolve to an object, not an array or scalar.
	#   - This function assumes jq is installed and available.

  report_start_phase_standard

  local json_input="${1:?MISSING json_input}"
  local jq_path="${2:?MISSING jq_path}"
  local target_array_name="${3:?MISSING target_array_name}"

  local key
  local value

  # Prevent code injection through eval below.
  if [[ ! "$target_array_name" == [A-Za-z_][A-Za-z0-9_]* ]]; then
    report_fail "Invalid associative array name: '$target_array_name'"
    return 1
  fi

  # Require that the caller already declared the target as an associative array.
  if [[ "${(tP)target_array_name}" != *association* ]]; then
    report_fail "Target '$target_array_name' is not an associative array."
    return 1
  fi

  # Clear the target associative array.
  eval "${target_array_name}=()"

  while IFS=$'\t' read -r key value; do
    eval "${target_array_name}[${(q)key}]=${(q)value}"
  done < <(
    jq -r "
      ${jq_path}
      | to_entries[]
      | [.key, (.value | tostring)]
      | @tsv
    " <<<"$json_input"
  ) || {
    report_fail "Failed to populate associative array '$target_array_name' from JSON path '$jq_path'."
    return 1
  }

  report_end_phase_standard
}

function populate_associative_array_from_json_object_of_string_arrays() {
  # Populates an existing Zsh associative array from a JSON object whose values are arrays of strings.
  #
  # Example JSON shape:
  #   {
  #     "work": ["dropbox", "sync_com"],
  #     "personal": ["dropbox"]
  #   }
  #
  # Stores each array value as compact JSON:
  #   target_array[work]='["dropbox","sync_com"]'
  #
  # Arguments:
  #   $1  json_input
  #   $2  jq_path
  #   $3  target_array_name
  #
  # The target array must already be declared as an associative array:
  #   typeset -gA user_attributes_from_user_class
  # or:
  #   local -A user_attributes_from_user_class

  report_start_phase_standard

  local json_input="${1:?missing json_input}"
  local jq_path="${2:?missing jq_path}"
  local target_array_name="${3:?missing target_array_name}"

  local key
  local value_json
  local entries_tsv

  # Prevent code injection through eval below.
  if [[ ! "$target_array_name" == [A-Za-z_][A-Za-z0-9_]* ]]; then
    report_fail "Invalid associative array name: '$target_array_name'"
    return 1
  fi

  # Require that the target already be declared as an associative array.
  if [[ "${(tP)target_array_name}" != *association* ]]; then
    report_fail "Target '$target_array_name' is not an associative array."
    return 1
  fi

  # Clear existing contents before repopulating.
  eval "${target_array_name}=()"

  entries_tsv="$(
    jq -r "
      ${jq_path}
      | to_entries[]
      | [
          .key,
          (
            .value
            | if type == \"array\" and all(.[]; type == \"string\") then
                tojson
              else
                error(\"Expected each value at ${jq_path} to be an array of strings\")
              end
          )
        ]
      | @tsv
    " <<<"$json_input"
  )" || {
    report_fail "Failed to read object of string arrays from JSON path '$jq_path'."
    return 1
  }

  while IFS=$'\t' read -r key value_json; do
    eval "${target_array_name}[${(q)key}]=${(q)value_json}"
  done <<<"$entries_tsv"

  report_end_phase_standard
}
