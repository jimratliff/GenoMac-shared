# Bootstrap and maintenance operations in Project GenoMac and their corresponding families of states

(This is part of the documentation within [GenoMac-shared](https://github.com/jimratliff/GenoMac-shared) that relates to both the [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user) repositories.)

## Operations can be bifurcated as performed either (a) typically one time only or (b) every time the Hypervisor is run
Project GenoMac operations can be bifurcated as performed either (a) the first time Hypervisor is run in the environment[^environment] and then only by exceptional request (which I’ll refer by the shorthand “typically one time only” or “bootstrap only”) or (b) every time the Hypervisor is run.

[^environment]: An environment is a particular user home directory. Unaddressed nuances arise because a Mac can have multiple startup volumes. So GenoMac-system doesn’t merely “set up a Mac” but rather sets up a particular startup volume on a specific Mac.

### Operations performed typically one time only, i.e., aka bootstrap only
Some operations are inherently desirably performed typically only once. For example:
- GenoMac-system
  - installing macOS onto a particular volume
  - creating a particular user account on a particular macOS installation
  - cloning a particular repository into a particular local directory
  - installing a particular app into `/Applications` of a particular startup volume
- GenoMac-user
  - Configuring 1Password’s SSH Agent
  - Signing into Dropbox and configuring to sync a particular local `Dropbox` directory
  - Creating additional Mission Control Spaces
 
These operations are run typically only once per environment because of some combination of:
- the operation isn’t idempotent: Repetition would mutate state undesirably
- the operation, even if idempotent, is too expensive to run arbitrarily repeatedly.
  - e.g., a step that can’t be purely scripted but instead requires a costly-to-our-human interactive operation.
- the operation is meant to provide a baseline upon which the user can freely expand. Repetition of this operation would undesirably overwrite any such expansion by the user
  - e.g., specifying a base set of persistent apps to occupy the Dock.
 
These typically one time only, bootstrap-only operations are typically associated with states with a `PERM_` prefix, where the prefix signals “permanent.” When Hypervisor successfully executes the bootstrap-only step, Hypervisor will then set the corresponding `PERM_` state. Typically, once a `PERM_` state is set, it is set permanently, or least until some event warrants the targeted deletion (unsetting) of that state. If Hypervisor detects a `PERM_` state (i.e., the state is set), Hypervisor will skip over that step. If Hypervisor fails to find a particular `PERM_` state, Hypervisor takes that as indicating that the corresponding bootstrap step needs to be performed.

### Maintenance steps
Other operations are inherently desirably performed every time Hypervisor is run, typically to enforce a choice where the implemented choice may have strayed from the desirable value by either some sort of corruption or user action that was accidental or experimental.

The first time such a step is run, it acts as a bootstrap step by establishing a starting-point departure from the status quo.

Subsequent runs of a maintenance step enforce a return to the specified state with respect to the particular setting.

## Migrating to new desired configuration
Consider a particular installation that is currently up to date in the sense that its Hypervisor has been run. Now suppose that the configuration overlords have decreed that, going forward, the installation should have a different configuration. The difference between the old and new configuration is composed of a set of atomic differences.

### Changes in maintenance steps are self-migrating
A difference in configuration that corresponds to a maintenance step will be *self-migrating* in the sense that it’s sufficient merely to update Hypervisor to (a) change the value that an existing maintenance step sets or (b) add a new maintenance step to implement the newly desired setting. The next time Hypervisor is run, the new configuration will be updated with respect to those maintenance-step differences.

### Changes in bootstrap-only steps are sometimes self-migrating and other times not
When a difference in configuration that corresponds to a bootstrap step, whether that change is self migrating depends on whether the difference represents
- a new bootstrap-only setting
  - This difference, like a difference in a maintenance step, is self migrating: Update Hypervisor with then new bootstrap-only step. The next time the Hypervisor is run, the never-before-seen `PERM_` state associated with the new bootstrap step will not be found (the state will be unset). This will prompt Hypervisor to perform the new bootstrap-only step, bringing the configuration into compliance—with respect to this setting—with the latest configuration specified by the configuration overlords.
- a different value for an existing bootstrap setting
  - This difference is *not* self migrating. Because the bootstrap-only step had executed in the past, Hypervisor set the `PERM_` state associated with that bootstrap-only step. Thus, the next time Hypervisor is run, it will detect that that state is set and skip over performing the bootstrap-only step.
 
### Implementing migration of a change in an existing bootstrap-only step
Because a change of value for a pre-existing bootstrap-only specification is not self-migrating, migration requires both (a) updating the Hypervisor’s definition of the value imposed by this setting *and* (b) unsetting (deleting) the `PERM_` state associated with this bootstrap-only setting. Thus, the next time Hypervisor is run, the `PERM_` state will not be found and hence the bootstrap operation will be repeated, but with the latest value.

We want *all installations* to migrate to the newly defined configuration. So we want *each installation* to perform the migration (by executing the bootstrap-only operation with the latest value) *exactly once*.

To achieve that, we pair with each migration a unique *migration ID* that is recorded as a permanent state (e.g., "MIGRATION_ID_2026_10_09_1728") in the environment after the migration is successfully performed.

A migration is a call of either `migrate_system_states` (for Hypervisor-system) or `migrate_user_states` (for Hypervisor-user), where the arguments are (a) a migration-ID string and (b) the `--delete` option followed by a sequence of one or more `PERM_` states to be deleted.

This call is placed “permanently”[^MIGRATION_COMMANDS_SEMI_PERMANENT] in the `hypervisor` function before it calls `subdermis`. This ensures that the migration’s deletion of particular `PERM_` states occurs before `subdermis` executes.

[^MIGRATION_COMMANDS_SEMI_PERMANENT]: There is no harm in leaving these calls indefinitely, other than cluttering the code of the `hypervisor` function. However, a particular migration’s call can be removed once you know that every existing installation (as of the date on which the updated Hypervisor was released) has run that migration.

These two migration functions (`migrate_system_states` and `migrate_user_states`) operate by:
- Check whether the specified migration state (e.g., "MIGRATION_ID_2026_10_09_1728") is already set (i.e., exists as a state file). If so, there is noting further to do.
- If the migration-ID state does not exist, delete each of the `PERM_` states that accompany the migration command.
- After the deletion of states has successfully been performed, set the migration state so that, upon subsequent runs of Hypervisor, the migration will not be performed again.

