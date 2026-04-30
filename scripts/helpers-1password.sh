#!/usr/bin/env zsh

############### Helpers: 1Password

# Relies upon:
#   helpers-reporting.sh

function read_1password_item_password() {
  # Read the standard password field from a 1Password item.
  #
  # Arguments:
  #   $1 = 1Password vault name
  #   $2 = 1Password item name

  local op_vault="$1"
  local op_item="$2"

  read_1password_item_field "$op_vault" "$op_item" "password"
}

function read_1password_item_notes_plain() {
  # Read the plain-text notes field from a 1Password item.
  #
  # Arguments:
  #   $1 = 1Password vault name
  #   $2 = 1Password item name

  local op_vault="$1"
  local op_item="$2"

  read_1password_item_field "$op_vault" "$op_item" "notesPlain"
}

function read_1password_item_field() {
  # Read a field from a 1Password item.
  #
  # Arguments:
  #   $1 = 1Password vault name
  #   $2 = 1Password item name
  #   $3 = 1Password field name, e.g. password, notesPlain
  #
  # Echoes the field value to stdout.
  #
  # Usage:
  #   secret=$(read_1password_item_field "$vault" "$item" "password") || return 1
  #
  # Important:
  #   This function must print only the secret value to stdout.
  #   Any error/reporting output must go to stderr via report_fail.

  local op_vault="$1"
  local op_item="$2"
  local op_field="$3"
  local op_value=""

  if [[ -z "$op_vault" ]]; then
    report_fail "Missing 1Password vault name."
    return 1
  fi

  if [[ -z "$op_item" ]]; then
    report_fail "Missing 1Password item name."
    return 1
  fi

  if [[ -z "$op_field" ]]; then
    report_fail "Missing 1Password field name."
    return 1
  fi

  if ! op_value="$(op read "op://${op_vault}/${op_item}/${op_field}")"; then
    report_fail "Failed to read 1Password field '${op_field}' from item '${op_item}' in vault '${op_vault}'."
    return 1
  fi

  if [[ -z "$op_value" ]]; then
    report_fail "1Password field '${op_field}' from item '${op_item}' in vault '${op_vault}' is empty."
    return 1
  fi

  print -r -- "$op_value"
}
