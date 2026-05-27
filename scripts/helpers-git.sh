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

function refresh_repo_from_remote_and_reexecute_hypervisor_if_updated() {
  # Test whether a related repo has already been checked for remote changes
  # during this session. If not, check the remote. If the local clone is updated,
  # mark the repo as checked and re-execute the current script (Hypervisor).
  #
  # Arguments:
  #   $1: test_state_function_name
  #   $2: set_state_function_name
  #   $3: state_string
  #   $4: repo_name
  #   $5: local_repo_directory
  #
  # Example (for GenoMac-user):
  #   refresh_repo_from_remote_and_reexecute_hypervisor_if_updated \
  #     test_genomac_user_state \
  #     set_genomac_user_state \
  #     "SESH_REPO_HAS_BEEN_TESTED_FOR_CHANGES" \
  #     "$GENOMAC_USER_REPO_NAME" \
  #     "$GENOMAC_USER_LOCAL_DIRECTORY"

  report_start_phase_standard

  local test_state_function_name="${1:?missing test_state_function_name}"
  local set_state_function_name="${2:?missing set_state_function_name}"
  local state_string="${3:?missing state_string}"
  local repo_name="${4:?missing repo_name}"
  local local_repo_directory="${5:?missing local_repo_directory}"

  if ! "$test_state_function_name" "$state_string"; then
    report_action_taken "Testing remote copy of ${repo_name} for changes"

    if local_clone_was_updated_from_remote "$local_repo_directory"; then
      # The local clone was found to be behind the remote; local clone was updated,
      # so re-execute the current script using the updated repo code.
      "$set_state_function_name" "$state_string"

      report_action_taken "Re-execute Hypervisor using updated repo code"
      report_end_phase_standard

      exec "$0"
    else
      "$set_state_function_name" "$state_string"
      report "Local clone of ${repo_name} was up to date"
    fi
  else
    report_action_taken "Skipping test for changes to repo, because this has already been tested this session."
  fi

  report_end_phase_standard
}

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
  report "Local hash: ${local_commit_hash}"
  report "Remote hash: ${remote_commit_hash}"
  echo "Branch: $(git -C "${local_dir}" rev-parse --abbrev-ref HEAD)"

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
