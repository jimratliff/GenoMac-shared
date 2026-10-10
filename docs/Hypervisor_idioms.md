# Hypervisor idioms

- [“Run if not done”](#run-if-not-done)
- [Conditionally run only if this user wants it](#conditionally-run-only-if-this-user-wants-it)
- [Interactive walk throughs](#interactive-walk-throughs)

## “Run if not done”
A frequently used Hypervisor idiom is “run if not done,” implemented by either `run_if_system_has_not_done` (for Hypervisor-system) or `run_if_user_has_not_done` (Hypervisor-user). The syntax for these two functions is identical. They differ only in that the assumed state space is system-scoped versus user-scoped, respectively.

Each takes three arguments (plus an optional switch):
- a state
	- assumed to be true/set if the intended action has already been performed
 	- set to true if/when the function is fully and successfully executed, so that next time through the function won’t be repeated[^UNLESS]
- a function name (which must not require an argument[^VARIANT_WITH_ARGUMENTS]), which will be run if the given state is false/unset
- a string, representing the message that will be printed if the given state is true to tell the user that the task to perform will be skipped because it’s already been performed.
- `--force-logout` (optional) If present, calls hypervisor_force_logout after setting state

For example:
```
function conditionally_ask_and_set_verbosity_preference() {
  # Asks and sets user’s verbose-output preference, if not already asked this session.
  report_start_phase_standard
  run_if_user_has_not_done \
    "$SESH_Q_ASKED_VERBOSITY" \
    ask_and_set_verbosity_preference \
    "Skipping asking about verbosity, because this has already been answered this session."
  report_end_phase_standard
}
```

[^UNLESS]: *Unless* a function beneath it records `interactive_task_outcome` as `$INTERACTIVE_TASK_DEFER_WORD`, for example, through `launch_app_and_prompt_user_to_act`. When deferred, neither the state nor a requested forced logout is performed. This causes the task to be offered again the next time Hypervisor runs. See `_run_func_and_args_based_on_state` in `GenoMac-shared/scripts/helpers-hypervisor.sh`. Function `_run_func_and_args_based_on_state` defines a `local` variable `interactive_task_outcome` which is visible to functions called by (directly/indirectly) `_run_func_and_args_based_on_state`, including `func_to_run`. When `func_to_run` returns control to `_run_func_and_args_based_on_state`, `_run_func_and_args_based_on_state` checks whether `$interactive_task_outcome` is either `$INTERACTIVE_TASK_COMPLETION_WORD` or `"$INTERACTIVE_TASK_DEFER_WORD"`. If `$INTERACTIVE_TASK_COMPLETION_WORD`, sets the state to indicate completion; if `"$INTERACTIVE_TASK_DEFER_WORD"`, (a) does *not* set that state and instead (b) sets a state to record that a task has been deferred. (See `set_state_to_record_that_a_task_has_been_deferred` in `GenoMac-shared/scripts/helpers-hypervisor.sh`.)

[^VARIANT_WITH_ARGUMENTS]: A variant `run_func_and_args_if_user_has_not_done` does allow the specified function to take an argument. See `GenoMac-shared/scripts/helpers-hypervisor.sh`. This function was created for a particular purpose that is now deprecated.

## Conditionally run only if this user wants it

## Interactive walk throughs
Another common Hypervisor idiom arises when the task to be completed requires some manual activity by the configuring user. The Hypervisor can lead the configuring user through this interactive process using the function `launch_app_and_prompt_user_to_act`.

### Capabilities and usage of `launch_app_and_prompt_user_to_act`
The `launch_app_and_prompt_user_to_act` function is very flexible. It allows Hypervisor to perform just about any combination of multiple operations to facilitate the configuring user performing the interactive task. These operations are:
- launching an app (by its bundle ID)
	- or not launching any app (specify `--no-app`
- open a path (e.g., .prefPane, URL, folder, file)
- display a document using Quick Look

- Positional arguments
	- Without `--no-app`
 		- bundle_id
    - prompt_text
  - With `--no-app`
    - prompt_text
   
- Options (all optional, any position)
  - `no-app`                 Skip launching an app by bundle_id
  - `--open <path>`          Path to open (e.g., .prefPane, URL, folder, file)
  - `--show-doc <filepath>`  Display file via Quick Look

**Examples:**
```
launch_app_and_prompt_user_to_act "com.example.some_app" "Please do the thing"
launch_app_and_prompt_user_to_act --show-doc "/path/to/doc.md" "com.example.some_app" "Please do the thing"
launch_app_and_prompt_user_to_act "com.example.some_app" "Please do the thing" --show-doc "/path/to/doc.md"
launch_app_and_prompt_user_to_act --no-app "Please do the thing"
launch_app_and_prompt_user_to_act --no-app --open ~/Library/PreferencePanes/Witch.prefPane "Configure Witch settings"
launch_app_and_prompt_user_to_act --no-app --open /path/to/folder "Review the files in this folder"
```

### Wrapping `launch_app_and_prompt_user_to_act` in a “run if not done” function
The “run if not done” functions (`run_if_system_has_not_done` and `run_if_user_has_not_done`) take a function-to-run, which doesn’t however accept arguments.

`launch_app_and_prompt_user_to_act` requires arguments.

So, to pair `launch_app_and_prompt_user_to_act` with a run-if-not-done function, we first encapsulate `launch_app_and_prompt_user_to_act` within a parameter-less function.

In the example below `launch_app_and_prompt_user_to_act` is encapsulated within the function `interactive_configure_Notion`, which is then passed to `run_if_user_has_not_done`:

```
function conditionally_interactive_configure_Notion() {
  report_start_phase_standard
  
  if test_genomac_user_state "$SESH_NOTION_USER_WANTS_IT"; then
    run_if_user_has_not_done "$PERM_NOTION_HAS_BEEN_CONFIGURED" \
      interactive_configure_Notion \
      "Skipping configuring Notion, because it’s already been configured."
  fi
  
  report_end_phase_standard
}

function interactive_configure_Notion() {
  report_start_phase_standard

  report "Time to configure Notion! I’ll launch it, and open a window with instructions for next steps"
	
  launch_app_and_prompt_user_to_act \
    --show-doc "${GMU_DOCS_TO_DISPLAY}/Notion_how_to_configure.md" \
    "$BUNDLE_ID_NOTION" \
    "Follow the instructions in the Quick Look window to log into and configure Notion"
  
  report_end_phase_standard
}
```
