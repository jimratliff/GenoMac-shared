#!/usr/bin/env zsh

############### Helpers: Strings

function sanitize_filename() {
  echo "$1" | tr -cd '[:alnum:]._-'
}

function nonempty_content_between_delimiters(){
  # Prints the nonempty substring of string_to_parse that lies between
  # left_delimiter and right_delimiter.
  #
  # Arguments:
  #   $1: string_to_parse
  #   $2: left_delimiter
  #   $3: right_delimiter
  #
  # Returns:
  #   0 if both delimiters are found in the expected order and the
  #     inbetween content is nonempty.
  #   1 otherwise

  local string_to_parse="${1:?missing/empty string_to_parse}"
  local left_delimiter="${2:?missing/empty left_delimiter}"
  local right_delimiter="${3:?missing/empty right_delimiter}"

  local after_left
  local content

  if [[ "$string_to_parse" != *"$left_delimiter"* ]]; then
    report_fail "The string to parse doesn’t contain the left delimiter “${left_delimiter}”.${NEWLINE}String to parse: ${string_to_parse}"
    return 1
  fi

  after_left="${string_to_parse#*"$left_delimiter"}"

  if [[ "$after_left" != *"$right_delimiter"* ]]; then
    report_fail "The string to parse doesn’t contain the right delimiter “${right_delimiter}”.${NEWLINE}String to parse: ${string_to_parse}"
    return 1
  fi

  content="${after_left%%"$right_delimiter"*}"

  if [[ -z "$content" ]]; then
    report_fail "Empty content between the left delimiter “${left_delimiter}” and the right delimiter “${right_delimiter}”.${NEWLINE}String to parse: ${string_to_parse}"
    return 1
  fi

  print -r -- "$content"
}
