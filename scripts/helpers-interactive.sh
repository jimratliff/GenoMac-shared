#!/usr/bin/env zsh

############### Helpers related to asking for and receiving input from the executing user

# Relies upon:
#   helpers-reporting.sh (for only `define_colors_and_symbols()`)

function ask_question() {
  # Output to stderr supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION
  printf "%b%s%s%b\n" "$COLOR_QUESTION" "$SYMBOL_QUESTION" "$1" "$COLOR_RESET" >&2
}

function get_nonblank_answer_to_question() {
  # Output supplied line of text in distinctive color (COLOR_QUESTION), prefixed by SYMBOL_QUESTION,
  # prompt user for response, iterating until user provides a nonblank response.
  #
  # Usage example: name=$(get_nonblank_answer_to_question "What should the diff be named?")
  local prompt="$1"
  local answer

  while true; do
    ask_question "$prompt"
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
      y|yes) return 0 ;;
      n|no) return 1 ;;
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

function show_file_using_quicklook() {
  # Shows a file using Quick Look, where that file is supplied by a path string in the only argument
  #
  # Usage:
  #   show_file_using_quicklook "${GENOMAC_USER_LOCAL_DOCUMENTATION_DIRECTORY}/test.md"
  
  report_start_phase_standard

  # Test whether argument specifies a valid file
  [[ -f $1 ]] || { report_warn "Error: file not found: $1" >&2; exit 1; }

  # Displays the file to user using QuickLook
  report_action_taken "I am showing you a file: «$1»${NEWLINE}Don’t see it? Look behind other windows."
  /usr/bin/qlmanage -p "$1" >/dev/null 2>&1 &

  sleep 0.1
  osascript -e 'tell application "System Events" to set frontmost of process "qlmanage" to true' 2>/dev/null

  report_end_phase_standard
}

function launch_app_and_prompt_user_to_act() {
  # Launches an app, prompts user to take action, waits for acknowledgment, and quits app
  #
  # The acknowledgment must be a case-insensitive match to `done`
  #
# Arguments:
  #   Without --no-app:
  #     $1: bundle_id of the app to launch
  #     $2: prompt text to display to user
  #   With --no-app:
  #     $1: prompt text to display to user
  #
  #   --no-app: (optional, any position) skip launching an app
  #   --show-doc <filepath>: (optional, any position) path to a file to display via Quick Look
  #   --show-folder <folderpath>: (optional, any position) path to a folder to open in Finder
  #
  # Usage:
  #   launch_app_and_prompt_user_to_act "com.example.some_app" "Please do the thing"
  #   launch_app_and_prompt_user_to_act --show-doc "/path/to/doc.md" "com.example.some_app" "Please do the thing"
  #   launch_app_and_prompt_user_to_act "com.example.some_app" "Please do the thing" --show-doc "/path/to/doc.md"
  #   launch_app_and_prompt_user_to_act --show-folder "/path/to/folder" "com.example.some_app" "Please do the thing"
  #   launch_app_and_prompt_user_to_act "com.example.some_app" "Please do the thing" --show-folder "/path/to/folder"
  #   launch_app_and_prompt_user_to_act --no-app "Please do the thing"
  
  local doc_to_show=""
  local folder_to_show=""
  local no_app=false
  local positional=()
  
  # Parse arguments
  while (( $# > 0 )); do
    case "$1" in
      --no-app)
        no_app=true
        shift
        ;;
      --show-doc)
        doc_to_show="$2"
        shift 2
        ;;
      --show-folder)
        folder_to_show="$2"
        shift 2
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done
  
  local bundle_id=""
  local task_description=""
  
  if $no_app; then
    # With --no-app, expect only 1 positional argument (prompt)
    if (( ${#positional[@]} != 1 )); then
      report_fail "Error: with --no-app, expected 1 positional argument (prompt), got ${#positional[@]}"
      return 1
    fi
    task_description="${positional[1]}"
  else
    # Without --no-app, expect 2 positional arguments (bundle_id, prompt)
    if (( ${#positional[@]} != 2 )); then
      report_fail "Error: expected 2 positional arguments (bundle_id, prompt), got ${#positional[@]}"
      return 1
    fi
    bundle_id="${positional[1]}"
    task_description="${positional[2]}"
    
    # Launch app in foreground so user can interact with it
    report_action_taken "Launching app $bundle_id"
    open -b "$bundle_id" ; success_or_not
  fi
  
  local confirmation_word="done"
  
  # Show documentation using Quick Look if specified
  if [[ -n "$doc_to_show" ]]; then
    if [[ -n "$bundle_id" ]]; then
      sleep 2 # To give time for $bundle_id to fully open, so that the Quick Look window is on top
    fi
    show_file_using_quicklook "$doc_to_show"
  fi
  
  # Open folder in Finder if specified
  if [[ -n "$folder_to_show" ]]; then
    if [[ -n "$bundle_id" ]]; then
      sleep 2 # To give time for $bundle_id to fully open, so that the Finder window is on top
    fi
    open "$folder_to_show"
  fi
  
  # Prompt user to complete the task
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ACTION REQUIRED: $task_description"
  echo "  When complete, please type: $confirmation_word"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Wait for explicit user confirmation
  local user_response=""
  while [[ "${user_response:l}" != "$confirmation_word" ]]; do
    read -r "user_response?Type '$confirmation_word' to confirm task completion: "
  done
  
  if [[ -n "$bundle_id" ]]; then
    report_action_taken "User confirmed task completion for $bundle_id"
  else
    report_action_taken "User confirmed task completion"
  fi
  
  # quit_app_by_bundle_id_if_running "$bundle_id"
}

function interactive_ensure_terminal_has_fda() {
  # Run at the beginning of a terminal session to try to ensure that the currently running terminal
  # app has Full Disk Access (FDA) permission.
  #
  # If the terminal app does *not* have FDA, the Settings » Privacy & Security » Full Disk Access
  # panel is opened (this terminal app should already be pre-populated, but un-enabled, on the 
  # list of apps), so the user can simply flip the switch for this app.
  #
  # The reason this terminal app will be pre-populated on the FDA list: The current script tests
  # whether the current terminal app has FDA by attempting to query a restricted location.
  # If the app doesn’t have FDA, this query is sufficient for macOS to add this app to that list.
  # NOTE: This is *not* conditioned on a PERM state variable, because there are multiple possible
  #       terminal apps. Each would need to tracked separately, requiring the script to interrogate
  #       what terminal app was running for that shell session. Too complicated!

  report_start_phase_standard
  
  # Query a restricted location (a) to test FDA and (b) if not, add terminal app to list
  if ! ls ~/Library/Mail &>/dev/null; then
    # The currently running terminal app does *not* have FDA
    # macOS will add the terminal app to the list, but un-enabled
    report_warning "The currently running terminal app needs, but doesn’t have, Full Disk Access."

    # Tests whether this is an interactive session
    if [[ -t 0 ]]; then
    
      # The session is interactive
      report_action_taken "I will open (a) the Full Disk Access panel in System Settings and (b) a Quick Look window with instructions"
      open_privacy_panel_for_full_disk_permissions
      launch_app_and_prompt_user_to_act \
        --no-app \
        --show-doc "${GENOMAC_SHARED_DOCS_TO_DISPLAY_DIRECTORY}/full_disk_access_how_to_configure.md" \
        "Follow the instructions in the Quick Look window to grant the current terminal app Full Disk Access"

      report "Configuring user confirms they have given FDA to the running terminal application"
      report_end_phase_standard
      return 0
        
    else
      # The session is not interactive
      report_warning "Warning: Terminal lacks FDA and no interactive session to fix it"
      report_end_phase_standard
      return 1
    fi
  fi
  report "This terminal application already had Full Disk Access"
  report_end_phase_standard
}

