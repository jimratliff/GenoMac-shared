# Dev issues common to both GenoMac-system and GenoMac-user

(This is part of the documentation within [GenoMac-shared](https://github.com/jimratliff/GenoMac-shared) that relates to both the [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user) repositories.)

## Repository stuff

### Configure the GitHub remote to use SSH for pushing from local to GitHub
This repo is public so that it can be easily cloned at the beginning of setting up a user (way before 1Password and its SSH agent get set up). But, ultimately, the configuring user will want to make changes to the repo, and this requires being able to authenticate with GitHub.

Since GitHub doesn’t authenticate in the CLI via HTTPS, the repo needs to be configured so that it can be modified locally and pushed to GitHub, which requires SSH. Although the repo could be configured to require SSH for both fetch and push, that would require authentication even to fetch, which is a needless hassle.

Thus, we instead configure separate URLs for fetch and push:
```
cd ~/.genomac-user

# Set the fetch URL to HTTPS (no auth needed for public repo)
git remote set-url origin https://github.com/jimratliff/GenoMac-user.git

# Set the push URL to SSH (uses 1Password SSH agent)
git remote set-url --push origin git@github.com:jimratliff/GenoMac-user.git
```

### Incorporating the GenoMac-shared repo as a submodule
#### To add GenoMac-shared as a submodule of GenoMac-user
```
cd ~/.genomac-user
git submodule add https://github.com/jimratliff/GenoMac-shared.git external/genomac-shared
git commit -m "Add genomac-shared submodule"
git push origin main
```

#### For the consumer
For the consumer of GenoMac-user (and indirectly of GenoMac-shared), updating the local clone of GenoMac-user is done via:
```
cd ~/.genomac-user
git pull --recurse-submodules origin main
```
which can also be performed by `make refresh-repo`.
#### For the developer of GenoMac-user and GenoMac-shared
When a change is made to GenoMac-shared, and therefore when there is a new commit to GenoMac-shared, that new commit will not automatically be reflected in the submodule of GenoMac-user.

To ensure that the latest commit of GenoMac-shared is reflected in the submodule of GenoMac-user, the following process is performed:
```
cd ~/.genomac-user
# Updates parent repo and checks out the *pinned* submodule commits
git pull --recurse-submodules origin main
# Fetches the submodule's *latest* commit from its remote (not just what's pinned)
git submodule update --remote
# Stages the new submodule commit reference
git add external/genomac-shared
# Commits only if there's actually a change
git diff --cached --quiet external/genomac-shared || git commit -m "Update genomac-shared submodule"
# Pushes the updated submodule reference
git push origin main
```
which can also be performed by `make dev-update-repo-and-submodule`.

## Idioms
### Reporting
#### The `report_…` functions write to `stderr` not `stdout`
All reporting to the user should use the `report_…` family of functions at `GenoMac-shared/scripts/helpers-reporting.sh`. These output to `stderr`, not `stdout`. This allows functions to use printing to `stdout` as their method to return values to the caller without being clobbered by other reporting.
#### `report_warning` and `report_fail` output is also regurgitated at the end of Hypervisor run
Because the terminal output from each Hypervisor is lengthy, it’d be easy for the user to miss important warnings issued in the midst of that output. For this reason, `report_warning` and `report_fail` output also is sent, in plain-text form, to an alert log.[^ALERT_LOG_ENV] This log is regurgitated at the end of Hypervisor run,[^ALERT_LOG_DUMPED_AT_END] to make it obviously visible to the user.

[^ALERT_LOG_ENV]: The location of the alert log is specified by the environment variable `GENOMAC_ALERT_LOG="$(mktemp "${tmpdir}/genomac_alerts.XXXXXX")"`.

[^ALERT_LOG_DUMPED_AT_END]: This dump is commanded by `hypervisor_force_logout()`, which runs at the end of both the GenoMac-system and GenoMac-user Hypervisor processes.
