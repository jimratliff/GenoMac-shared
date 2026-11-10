#!/usr/bin/env zsh

############### Miscellaneous helpers.

function get_timestamp() {
  # Returns a timestamp like 2026_11_10_1326 (November 10, 2026, 1:36PM)
  local timestamp
  timestamp="$(date +%Y_%m_%d_%H%M)"
  print -r -- "$timestamp"
}
