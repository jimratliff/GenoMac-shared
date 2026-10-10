# Hypervisor idioms

## “Run if not done”
A frequently used Hypervisor idiom is “run if not done,” implemented by either `run_if_system_has_not_done` (for Hypervisor-system) or `run_if_user_has_not_done` (Hypervisor-user). The syntax for these two functions is identical. They differ only in that assumed state space is system-scoped versus user-scoped, respectively.

Each takes three arguments:
- a state, assumed to be true/set if the intended action has already been performed
- a function name (which must not require an argument), which will be run if the given state if false/unset
- a string, representing the message that will be printed if the given state is true to tell the user that the task to perform will be skipped because it’s already been performed.

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

## Interactive walk throughs
