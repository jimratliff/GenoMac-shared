#!/usr/bin/env zsh

############### Helpers: Git

# Relies upon:
#   helpers-reporting.sh
#
#   Environment variables:
#     GENOMAC_SYSTEM_LOCAL_DIRECTORY
#	    GENOMAC_SYSTEM_REPO_NAME
#	    GENOMAC_USER_LOCAL_DIRECTORY
#     GENOMAC_USER_REPO_NAME

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
  else
    report_action_taken "Skipping split-remote configuration of ${github_repo_name}: not cloned at ${local_repo_dir}"
  fi
  
  report_end_phase_standard
}
