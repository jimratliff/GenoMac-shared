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

function clone_public_genomac_repo_using_HTTPS() {
  # Clones a public GenoMac GitHub repo using HTTPS, including any submodules.
  #
  # $1: GitHub repo name, e.g. GenoMac-user
  # $2: local directory into which the repo should be cloned
  #
  # If the directory already contains the expected git repo, warns and returns normally.
  # If the directory exists but is not the expected git repo, fails.

  report_start_phase_standard

  local github_repo_name="${1:?MISSING/EMPTY github_repo_name}"
  local local_cloning_dir="${2:?MISSING/EMPTY local_cloning_dir}"

  local repo_url
  local existing_remote
  local existing_repo_name

  repo_url="${GENOMAC_COMMON_GITHUB_HTTPS_URL_ROOT}/${github_repo_name}.git"

  report_action_taken "Prepare development clone of ${github_repo_name} at: ${local_cloning_dir}"

  if [[ -d "$local_cloning_dir" ]]; then
    report_warning "Desired development clone directory already exists: ${local_cloning_dir}"
  elif [[ -e "$local_cloning_dir" ]]; then
    report_fail "Desired development clone path exists but is not a directory: ${local_cloning_dir}"
    report_end_phase_standard
    return 1
  fi

  if [[ -d "$local_cloning_dir/.git" ]]; then
    existing_remote="$(git -C "$local_cloning_dir" remote get-url origin 2>/dev/null)"
    existing_repo_name="$(basename "$existing_remote" .git)"

    if [[ "$existing_repo_name" == "$github_repo_name" ]]; then
      report "Repository ${github_repo_name} already cloned at: ${local_cloning_dir}" ; success_or_not
      report_end_phase_standard
      return 0
    fi

    report_fail "Directory contains a different repository: ${existing_repo_name} (expected: ${github_repo_name})"
    report_end_phase_standard
    return 1
  fi

  if [[ -d "$local_cloning_dir" && -n "$(ls -A "$local_cloning_dir" 2>/dev/null)" ]]; then
    report_fail "Directory exists but is not empty and is not a git repository: ${local_cloning_dir}"
    report_end_phase_standard
    return 1
  fi

  report_action_taken "Cloning repo, including any submodules: ${repo_url} into ${local_cloning_dir}"
  git clone --recurse-submodules "$repo_url" "$local_cloning_dir" ; success_or_not

  report_end_phase_standard
}

function initialize_genomac_shared_submodule_if_present() {
  # Initializes GenoMac-shared submodule inside a GenoMac repo, if that repo has submodules.
  #
  # $1: local repo directory

  report_start_phase_standard

  local local_repo_dir="${1:?MISSING/EMPTY local_repo_dir}"

  if [[ ! -d "$local_repo_dir/.git" ]]; then
    report_fail "Skipping submodule initialization: not a git repo at ${local_repo_dir}"
    report_end_phase_standard
    return 0
  fi

  if [[ ! -f "$local_repo_dir/.gitmodules" ]]; then
    report_action_taken "Skipping submodule initialization: no .gitmodules file in ${local_repo_dir}"
    report_end_phase_standard
    return 0
  fi

  report_action_taken "Initialize/update submodules in ${local_repo_dir}"
  git -C "$local_repo_dir" submodule update --init --recursive ; success_or_not

  report_end_phase_standard
}

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
    git -C "$local_repo_dir" config pull.rebase false ; success_or_not
  else
    report_action_taken "Skipping split-remote configuration of ${github_repo_name}: not cloned at ${local_repo_dir}"
  fi
  
  report_end_phase_standard
}
