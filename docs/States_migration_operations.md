# The two types of operations in Project GenoMac and their corresponding families of states

## Some terminology: environment
Let “environment” refer to a combination of (a) a particular startup volume (necessarily on a particular Mac)
and (b) a particular user defined on that startup volume. In the case of GenoMac-system, only one user matters: USER_CONFIGURER. So there is one environment per
startup volume.




## Project GenoMac operations are either (a) bootstrap-only or (b) maintenance
The settings effected by Project GenoMac can usefully be thought of as bifurcated into:
- bootstrap-only operations, which are run typically only once per environment
  - These operations are run typically only once per environment because of some combination of:
    - the operation isn’t idempotent: Repetition would mutate state undesirably
    - the operation, even if idempotent, is too expensive to run arbitrarily repeatedly. E.g., a step that
      can’t be purely scripted but instead requires a costly-to-our-human interactive operation.
    - the operation is meant to provide a baseline upon which the user can freely expand. Repetition of this 
      operation would undesirably overwrite any such expansion by the user
      - e.g., specifying a base set of persistent apps to occupy the Dock
- maintenance steps, run repeatedly to enforce a set of settings
  - The first time such a step is run, it acts as a bootstrap step by establishing a starting-point departure from the status quo.
  - Subsequent runs of a maintenance step enforces a return to the specified state with respect to the particular setting.

## Project GenoMac is somewhat, but not fully, declarative about the resulting state of the system
Project GenoMac *could*, but does *not*, attempt to specify all settings for a user or a macOS installation.

Instead, Project GenoMac acknowledges that there are default settings out of the box. Project GenoMac, for the most part,
identifies only settings whose default values are different from Project GenoMac’s *desired* values.[^EMPHASIZING_DEFAULTS]

[^EMPHASIZING_DEFAULTS]: In some cases, Project Genomac chooses to enforce a setting even when the enforced setting is
                         identical to the default setting.

