# GenoMac-shared
A repository of helper commands for [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user).

This repository is intended to be used as a submodule by [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user).

In both of these repositories, this submodule is intended to be mapped to the `external/genomac-shared` directory.

## One time only: add GenoMac-shared as a submodule to GenoMac-system and GenoMac-user

In a local clone of either of the two container repositories, navigate to the root of that clone:

```
# For GenoMac-system as the container repository:
cd ~/.genomac-system
```

```
# Alternatively, for GenoMac-user as the container repository
cd ~/.genomac-user
```

Then execute the following command to cause the current GenoMac-shared repository to become a submodule of the container repository in the directory `external/genomac-shared` of that local clone:
```
git submodule add https://github.com/jimratliff/genomac-shared.git "external/genomac-shared"
git commit -m "Add genomac-shared submodule"
git push origin main
```
