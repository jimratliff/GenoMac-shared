# GenoMac-shared
A repository of helper commands for [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user).

This repository is intended to be used as a submodule by [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user), which act as container repositories.

In each of these container repositories, this submodule is intended to be mapped to the `external/genomac-shared` directory.

## One time only: add GenoMac-shared as a submodule to GenoMac-system and GenoMac-user

In a local clone of each of the two container repositories, navigate to the root of that clone:
```
# For GenoMac-system as the container repository:
cd ~/.genomac-system
```
or
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
## Each time this GenoMac-shared repository is modified on GitHub, update both container repositories
Whenever GenoMac-shared is modified on GitHub (whether (a) modified directly on GitHub or (b) a local repo is modified and pushed to GitHub), each container repository must be updated so that its reference to GenoMac-shared will be updated to the newly current commit:
```
# Pick one
cd ~/.genomac-system
# cd ~/.genomac-user

git pull --recurse-submodules origin main       # ensure local container is current
git submodule update --remote                   # fetch latest from submodule's remote
git add external/genomac-shared                 # stage the new commit reference
git commit -m "Update genomac-shared submodule"
git push origin main
```
This process is codified in a one-liner:
```
make dev-update-repo-and-submodule
```
(Note: Currently, this `make` recipe has been added only to GenoMac-user, not yet GenoMac-system.)
