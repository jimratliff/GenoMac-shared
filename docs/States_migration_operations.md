# The two types of operations in Project GenoMac and their corresponding families of states

(This is part of the documentation within [GenoMac-shared](https://github.com/jimratliff/GenoMac-shared) that relates to both the [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user) repositories.)

## Status: Incomplete, WIP (2/22/2026)
The ultimate goal of this section is to explain why the migration methodology is necessary at all:
- Maintenance steps are self-migrating: Revise the code, the revised repo is pulled, and the next run replaces
  the former settings with the new settings.
  - these correspond to SESH states
- Bootstrap-only settings, on the other hand, are not self-migrating because by default they are not
  not designed to be routinely revisited. To revisit a bootstrap-only setting, we typically need to
  retract a PERM state that recorded that the operation had already been performed.
- Thus, the migration mechanism is aimed at PERM states—and then usually at deleting them—and their
  associated bootstrapping steps.


## Operations can be bifurcated as performed either (a) typically one time only or (b) every time the Hypervisor is run
Project GenoMac operations can be bifurcated as performed either (a) the first time Hypervisor is run in the environment[^environment] and then only by exceptional request (which I’ll refer by the shorthand “typically one time only”) or (b) every time the Hypervisor is run.

[^environment]: An environment is a particular user home directory. Unaddressed nuances arise because a Mac can have multiple startup volumes. So GenoMac-system doesn’t merely “set up a Mac” but rather sets up a particular startup volume on a specific Mac.

Consider three types of operations: (a) those inherently desirably performed only once, (b) those inherently desirably performed regularly/often, and (c)

Some operations are inherently desirably performed only once. For example:
- GenoMac-system
  - installing macOS onto a particular volume
  - creating a particular user account on a particular macOS installation
  - cloning a particular repository into a particular local directory
  - installing a particular into `/Applications` of a particular startup volume
- GenoMac-user
  - Configuring 1Password’s SSH Agent
  - Signing into Dropbox and configuring to sync a particular local `Dropbox` directory
  - Creating additional Mission Control Spaces

## Project GenoMac operations are either (a) bootstrap-only or (b) bootstrap *and* maintenance
The settings effected by Project GenoMac can usefully be thought of as bifurcated into:
- bootstrap-only operations, which are run typically only once per environment
  - These operations are run typically only once per environment because of some combination of:
    - the operation isn’t idempotent: Repetition would mutate state undesirably
    - the operation, even if idempotent, is too expensive to run arbitrarily repeatedly.
      - e.g., a step that can’t be purely scripted but instead requires a costly-to-our-human interactive operation.
    - the operation is meant to provide a baseline upon which the user can freely expand. Repetition of this 
      operation would undesirably overwrite any such expansion by the user
      - e.g., specifying a base set of persistent apps to occupy the Dock
- maintenance steps, run repeatedly to enforce a set of settings
  - The first time such a step is run, it acts as a bootstrap step by establishing a starting-point departure from the status quo.
  - Subsequent runs of a maintenance step enforces a return to the specified state with respect to the particular setting.
 
Although “bootstrap-only” steps *typically* (or perhaps more accurately *ideally*) are performed only once per environment,
it is possible that the desired setting for a bootstrap-only operation changes at some point after the operation was
performed on one or more active environments.

