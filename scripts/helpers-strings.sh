#!/usr/bin/env zsh

############### Helpers: Strings

function sanitize_filename() {
  echo "$1" | tr -cd '[:alnum:]._-'
}

function content_between_delimiters(){
  # Prints the substring of string_to_parse that lies between left_delimiter
  # and right_delimiter.
  #
  # Arguments:
  #   $1: string_to_parse
  #   $2: left_delimiter
  #   $3: right_delimiter
  #
  # Returns:
  #   0 if both delimiters are found in the expected order
  #   1 otherwise

  local string_to_parse="${1:?missing/empty string_to_parse}"
  local left_delimiter="${2:?missing/empty left_delimiter}"
  local right_delimiter="${3:?missing/empty right_delimiter}"

  local after_left

  if [[ "$string_to_parse" != *"$left_delimiter"* ]]; then
    report_fail "The string to parse doesn’t contain the left delimiter “${left_delimiter}”.${NEWLINE}String to parse: ${string_to_parse}"
    return 1
  fi

  after_left="${string_to_parse#*"$left_delimiter"}"

  if [[ "$after_left" != *"$right_delimiter"* ]]; then
    report_fail "The string to parse doesn’t contain the right delimiter “${right_delimiter}”.${NEWLINE}String to parse: ${string_to_parse}"
    return 1
  fi

  print -r -- "${after_left%%"$right_delimiter"*}"
}
