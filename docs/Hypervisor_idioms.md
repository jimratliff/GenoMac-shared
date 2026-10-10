# Hypervisor idioms

## “Run if not done”
A frequently used Hypervisor idiom is “run if not done,” implemented by either `run_if_system_has_not_done` (for Hypervisor-system) or `run_if_user_has_not_done` (Hypervisor-user). The syntax for these two functions is identical. They differ only in that the assumed state space is system-scoped versus user-scoped, respectively.

Each takes three arguments (plus an optional switch):
- a state
	- assumed to be true/set if the intended action has already been performed
 	- set to true if/when the function is fully and successfully executed, so that next time through the function won’t be repeated
- a function name (which must not require an argument[^VARIANT_WITH_ARGUMENTS]), which will be run if the given state is false/unset
- a string, representing the message that will be printed if the given state is true to tell the user that the task to perform will be skipped because it’s already been performed.
- `--force-logout` (optional) If present, calls hypervisor_force_logout after setting state.

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

[^VARIANT_WITH_ARGUMENTS]: A variant `run_func_and_args_if_user_has_not_done` does allow the specified function to take an argument. See `GenoMac-shared/scripts/helpers-hypervisor.sh`. This function was created for a particular purpose that is now deprecated.

> [!NOTE]
> The above description captures the operation of `run_if_system_has_not_done` and `run_if_user_has_not_done` in their simplest form. There is, however, a more-nuanced wrinkle: If a function called anywhere beneath the specified function receives “punt” (i.e., `$INTERACTIVE_TASK_DEFER_WORD`, for example, through `launch_app_and_prompt_user_to_act`), the supplied state is *not* set and a requested forced logout is not performed. This causes the task to be offered again the next time Hypervisor runs.[^PUNT_IMPLEMENTATION]

[^PUNT_IMPLEMENTATION]: See `_run_func_and_args_based_on_state` in `GenoMac-shared/scripts/helpers-hypervisor.sh`.

## Interactive walk throughs
