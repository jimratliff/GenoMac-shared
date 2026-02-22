# The two types of operations in Project GenoMac and their corresponding families of states

## Some terminology: environment
Let “environment” refer to a combination of (a) a particular startup volume (necessarily on a particular Mac)
and (b) a particular user defined on that startup volume. In the case of GenoMac-system, only one user matters: USER_CONFIGURER. So there is one environment per
startup volume.

## Project GenoMac is somewhat, but not fully, declarative



## Project GenoMac operations are either (a) bootstrap-only or (b) maintenance
The settings effected by Project GenoMac can usefully be thought of as bifurcated into:
- bootstrap-only operations, which are run only once per environment
  - These operations are run only once per environment because of some combination of:
    - the operation isn’t idempotent: Repetition would mutate state undesirably
    - the operation, even if idempotent, is too expensive to run arbitrarily repeatedly. E.g., a step that
      can’t be purely scripted but instead requires a costly-to-our-human interactive operation.
    - the operation is meant to provide a baseline upon which the user can freely expand. Repetition of this 
      operation would undesirably overwrite any such expansion by the user
- maintenance steps, run repeatedly to enforce a set of settings
  - The first time such a step is run, it acts as a bootstrap step by establishing a starting-point departure from the status quo.
