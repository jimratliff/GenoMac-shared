############### Helpers related to asking for and receiving input from the executing user

# Relies upon:
#   helpers-reporting.sh (for only `define_colors_and_symbols()`)

function ask_question() {
  # Output supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION
  printf "%b%s%s%b\n" "$COLOR_QUESTION" "$SYMBOL_QUESTION" "$1" "$COLOR_RESET"
}

function get_nonblank_answer_to_question() {
  # Output supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION,
  # prompt user for response, iterating until user provides a nonblank response.
  #
  # Usage example: name=$(get_nonblank_answer_to_question "What should the diff be named?")
  local prompt="$1"
  local answer

  while true; do
    ask_question "$prompt" >&2 # Redirects question to stderr to keep it out of returned string
    read "answer?→ "
    [[ -n "${answer// }" ]] && break
  done

  echo "$answer"
}

function get_yes_no_answer_to_question() {
  # Output supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION,
  # prompt user for response, iterating until user provides either a yes or no equivalent.
  #
  # Usage example: 
  #     if get_yes_no_answer_to_question "Do you want to continue?"; then
  #       echo "✅ Proceeding"
  #     else
  #       echo "❌ Aborted"
  #     fi
  
  local prompt="$1"
  local response

  while true; do
    ask_question "$prompt (y/n)"
    read "response?→ "
    case "${response:l}" in  # `:l` lowercases in Zsh
      y|yes) echo "yes"; return 0 ;;
      n|no)  echo "no";  return 1 ;;
    esac
  done
}
function get_confirmed_answer_to_question() {
  # Output supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION,
  # prompt user for response, strip leading/trailing whitespace, ask user to confirm the trimmed value,
  # and iterate until user provides an affirmative confirmation.
  #
  # Usage example: folder=$(get_confirmed_answer_to_question "Where should I save the results?")
  local prompt="$1"
  local answer_raw answer confirm

  while true; do
    ask_question "$prompt"
    read "answer_raw?→ "
    
    # Strip leading/trailing whitespace
    answer=$(echo "$answer_raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    [[ -z "$answer" ]] && continue

    ask_question "You entered: '$answer'. Is this correct? (y/n)"
    read "confirm?→ "
    case "$confirm" in
      [Yy]*) break ;;
    esac
  done

  echo "$answer"
}

function open_privacy_panel_for_full_disk_permissions() {
  open "$PRIVACY_SECURITY_PANEL_URL_FULL_DISK"
}

function tell_Terminal_to_require_full_disk_access() {
  # Tells Terminal to execute a command that requires disk-access permissions it doesn't 
  # have. macOS will respond by adding Terminal to the list of apps under Privacy » Full Disk Access
  # (but with that permission unchecked). This makes it easier for the user to then enable that permission.
  osascript -e "tell application id \"$BUNDLE_ID_TERMINAL\" to do script \"ls ~/Library/Mail &>/dev/null; exit\""  &>/dev/null
}

function tell_iTerm_to_require_full_disk_access() {
  # Tells iTerm to execute a command that requires disk-access permissions it doesn't 
  # have. macOS will respond by adding iTerm to the list of apps under Privacy » Full Disk Access
  # (but with that permission unchecked). This makes it easier for the user to then enable that permission.
  osascript -e "tell application id \"$BUNDLE_ID_ITERM2\" to create window with default profile command \"ls ~/Library/Mail &>/dev/null; exit\"" &>/dev/null
}


