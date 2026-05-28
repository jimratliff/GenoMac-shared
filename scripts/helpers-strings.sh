#!/usr/bin/env zsh

############### Helpers: Strings

function sanitize_filename() {
  echo "$1" | tr -cd '[:alnum:]._-'
}
