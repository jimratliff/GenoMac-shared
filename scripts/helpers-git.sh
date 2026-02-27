#!/usr/bin/env zsh

############### Helpers: Git

# Relies upon:
#   helpers-reporting.sh
#
#   Environment variables:
#     GENOMAC_SYSTEM_LOCAL_DIRECTORY
#     GENOMAC_SYSTEM_REPO_NAME
#     GENOMAC_USER_LOCAL_DIRECTORY
#     GENOMAC_USER_REPO_NAME

function local_clone_was_updated_from_remote() {
  # Checks whether the local clone at the local directory in $1 is
  # pointing at the same commit as its remote.
  # If the two commits are different, pulls the changes from the remote.
  # Exits with 0 if the local and remote of the repo were different.
  # Exits with 1 if the local and remote were the same.
  # $1: local directory (e.g., "${HOME}/.genomac-system")

  report_start_phase_standard

  local local_dir="$1"
  
  local local_commit_hash
  local remote_commit_hash

  git -C "${local_dir}" fetch origin main
  local_commit_hash=$(git -C "${local_dir}" rev-parse HEAD)
  remote_commit_hash=$(git -C "${local_dir}" rev-parse origin/main)

  report_action_taken "Testing remote of clone at ${local_dir} for changes"
  if [[ "$local_commit_hash" != "$remote_commit_hash" ]]; then
    report_action_taken "Update available. Pulling update."
    git -C "${local_dir}" pull origin main --recurse-submodules
    report_end_phase_standard
    return 0
  else
    report "The local clone was up to date"
    report_end_phase_standard
    return 1
  fi
}

function configure_split_remote_URLs_for_GenoMac_system() {
  report_start_phase_standard
  configure_split_remote_URLs_for_public_GitHub_repo_if_cloned "${GENOMAC_SYSTEM_LOCAL_DIRECTORY}" "${GENOMAC_SYSTEM_REPO_NAME}"
  report_end_phase_standard
}

function configure_split_remote_URLs_for_GenoMac_user() {
  report_start_phase_standard
  configure_split_remote_URLs_for_public_GitHub_repo_if_cloned "${GENOMAC_USER_LOCAL_DIRECTORY}" "${GENOMAC_USER_REPO_NAME}"
  report_end_phase_standard
}

function configure_split_remote_URLs_for_public_GitHub_repo_if_cloned() {
  # Locally configures clone of public GitHub repo to (a) fetch without authentication 
  # using HTTPS but (b) push using SSH.
  #
  # $1: local directory into which the repo is cloned
  # $2: name of the repository (e.g., 'repo_name' in 'https://github.com/some_dev/repo_name'
  #
  # Addresses GitHub policy disallowing CLI authentication using HTTPS but inconveniently
  # and pointlessly requiring authentication for fetch using SSH of a public repo.
  #
  # NOTE: These commands work by editing the  path_to_repo/.git/config file
  #
  # Usage:
  #   configure_split_remote_URLs_for_public_GitHub_repo_if_cloned "~/.genomac-system" "GenoMac-system"
  #   configure_split_remote_URLs_for_public_GitHub_repo_if_cloned "~/.genomac-user" "GenoMac-user"
  #   configure_split_remote_URLs_for_public_GitHub_repo_if_cloned "~/.genomac-shared" "GenoMac-shared"
  
  report_start_phase_standard

  local local_repo_dir="$1"
  local github_repo_name="$2"

  report_action_taken "Configure split remote for local clone of ${github_repo_name} to fetch with HTTPS but push with SSH, if local clone exists at ${local_repo_dir}."

  if [[ -d "${local_repo_dir}/.git" ]]; then
    report_adjust_setting "Configure ${github_repo_name} to fetch via HTTPS"
    git -C "$local_repo_dir" remote set-url origin "${GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT}/${github_repo_name}.git" ; success_or_not
    report_adjust_setting "Configure ${github_repo_name} to push via SSH"
    git -C "$local_repo_dir" remote set-url --push origin "${GENOMAC_COMMON_GITHUB_SCP_URL_ROOT}/${github_repo_name}.git" ; success_or_not
    report_adjust_setting "Use merge rather than rebase. This is more compatible with having a submodule."
    git config pull.rebase false
  else
    report_action_taken "Skipping split-remote configuration of ${github_repo_name}: not cloned at ${local_repo_dir}"
  fi
  
  report_end_phase_standard
}
