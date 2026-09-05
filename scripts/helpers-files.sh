#!/usr/bin/env zsh

############### Helpers: Files
# Relies upon:
#   helpers-reporting.sh

function file_exists_and_is_readable() {
  # Tests supplied file for (a) existence and, if so, (b) whether it is a readable regular file.
  # Returns 0 if both exists and readable/regular.
  # Returns 1 if the file doesn’t exist (a non-error, normal outcome).
  # Exits immediately as an error if the file exists but isn’t readable/regular.
  
  report_start_phase_standard
  
  local filepath="${1:?missing file path}"

  if [[ ! -e "${filepath}" && ! -L "${filepath}" ]]; then
    report_to_log "No file exists at “${filepath}”."
    report_end_phase_standard
    return 1
  elif [[
    ! -f "${filepath}" ||
    ! -r "${filepath}"
  ]]; then
    report_fail "The object at “${filepath}” isn’t a readable regular file."
    exit 1
  else
    report_to_log "There is a readable regular file at “${filepath}”."
    report_end_phase_standard
    return 0
  fi
}

function convert_filesystem_path_to_file_url() {
  # Converts "~", "~/...", or an absolute filesystem path into an
  # encoded file URL. The path does not need to exist.
  #
  # Usage:
  #   file_url="$(convert_filesystem_path_to_file_url "~/Team Files")"
  #
  #   The output will be: 'file:///Users/tom/Team%20Files'
  
  report_start_phase_standard

  local filesystem_path="$1"
  local expanded_path

  case "$filesystem_path" in
    "~")
      expanded_path="$HOME"
      ;;

    "~/"*)
      expanded_path="$HOME/${filesystem_path#\~/}"
      ;;

    "~"*)
      report_fail "Unsupported filesystem path '$filesystem_path': ~user syntax is not supported."
      return 1
      ;;

    /*)
      expanded_path="$filesystem_path"
      ;;

    *)
      report_fail "Unsupported filesystem path '$filesystem_path': expected ~, ~/, or an absolute path."
      return 1
      ;;
  esac

  if [[ ! -e "$expanded_path" ]]; then
    report_warning "Converting a filesystem path that does not currently exist: $expanded_path"
  fi

  # Print result to standard out
  jq -nr --arg path "$expanded_path" '
    $path
    | @uri
    | gsub("%2F"; "/")
    | "file://" + .
  '
  report_end_phase_standard
}

function get_array_from_json_lines_file() {
  # Read successive JSON values from a JSON Lines file, returning each as a compact JSON
  # value in the zsh array reply.
  #
  # Conventionally, each value occupies one line in the input file. Blank lines are accepted.
  # The parser also accepts values separated by other JSON whitespace
  #
  # Usage:
  #   get_array_from_json_lines_file "$input_file"
  #   local -a tuples=("${reply[@]}")
  
  report_start_phase_standard

  local file_to_read="$1"
  local output

  reply=()

  output="$(jq -c '.' "$file_to_read")"

  if [[ -n "$output" ]]; then
    reply=("${(@f)output}")
  fi
  
  report_end_phase_standard
}
