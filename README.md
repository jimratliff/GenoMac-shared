# GenoMac-shared
A repository of helper commands and environment-variable assignments for [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user).

This repository is intended to be used as a submodule by [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user), which act as container repositories. (There is an additional, private repo, too: [GenoMac-private](https://github.com/jimratliff/GenoMac-private). Its purpose is TBD.)

In each of these container repositories, this submodule is intended to be mapped to the `external/genomac-shared` directory.

## Two separate steps: adding the submodule vs. initializing it in a local clone
There are two distinct steps involved in using GenoMac-shared as a submodule.
### One time only, and it’s already been performed: add GenoMac-shared as a submodule to GenoMac-system and GenoMac-user

The following instructions explain how the submodule was originally added to each of the two container repos. This does *not* have to be performed again.

The purpose of this step is to modify the container repository itself so that it records GenoMac-shared as a submodule. This creates or updates the container repository’s .gitmodules file and records the submodule path and URL in the container repository’s history.

This does not have to be performed again unless the submodule is being newly added, moved, removed, or re-added.

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
git submodule add https://github.com/jimratliff/GenoMac-shared.git "external/genomac-shared"
git commit -m "Add genomac-shared submodule"
git push origin main
```

### Per-local-clone step: initialize and populate the submodule

This step must be handled for each fresh local clone of a container repository that already has `GenoMac-shared` recorded as a submodule.

The purpose of this step is to populate the local working tree’s `external/genomac-shared` directory with the submodule contents.

This does **not** add the submodule to the container repository. It merely initializes and checks out the submodule that the container repository already records.

The preferred first-line method is to clone the container repository using `--recurse-submodules`. This causes Git to clone the container repository and also initialize and populate its recorded submodules as part of the initial clone.

For example:

    git clone --recurse-submodules https://github.com/jimratliff/GenoMac-system.git "$HOME/.genomac-system"
    git clone --recurse-submodules https://github.com/jimratliff/GenoMac-user.git "$HOME/.genomac-user"

If the container repository has already been cloned without `--recurse-submodules`, use `submodule update --init --recursive` as a backstop to initialize and populate the submodule afterward.

For a given local clone of `GenoMac-system` or `GenoMac-user`, execute:

    git -C "$local_repo_dir" submodule update --init --recursive

For example:

    git -C "$HOME/.genomac-system" submodule update --init --recursive
    git -C "$HOME/.genomac-user" submodule update --init --recursive

The automated GenoMac development-clone setup uses the first-line method: it clones each container repository using `git clone --recurse-submodules`.

## Each time this GenoMac-shared repository is modified on GitHub, update both container repositories
Whenever GenoMac-shared is modified on GitHub (whether (a) modified directly on GitHub or (b) a local repo is modified and pushed to GitHub), each container repository must be updated so that its reference to GenoMac-shared will be updated to the newly current commit:
```
# Pick one of the following two `cd` commands, then execute the remainder in order
cd ~/.genomac-system
# cd ~/.genomac-user

git pull --recurse-submodules origin main       # ensure local container is current
git submodule update --remote                   # fetch latest from submodule's remote
git add external/genomac-shared                 # stage the new commit reference
git commit -m "Update genomac-shared submodule"
git push origin main
```
This process is codified in a one-liner.
(a) For GenoMac-system
```
make dev-update-repo-and-submodule
```
or, if `just` has already been installed (i.e., Homebrew has installed apps at least once):
```
just dev-update-repo-and-submodule
```
(b) for GenoMac-user
```
just dev-update-repo-and-submodule
```
