#!/usr/bin/env zsh

# Assumes that jq has been installed.

populate_associative_array_from_json_object() {
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

	local json_input="$1"
	local jq_path="$2"
	local target_array_name="$3"
	local key
	local value

	typeset -n target_array="$target_array_name"

	target_array=()

	while IFS=$'\t' read -r key value; do
		target_array["$key"]="$value"
	done < <(
			jq -r "
					${jq_path}
					| to_entries[]
					| [.key, .value]
					| @tsv
			" <<<"$json_input"
	) || {
		report_fail "Failed to populate associative array '$target_array_name' from JSON path '$jq_path'."
		return 1
	}

	report_end_phase_standard
}
