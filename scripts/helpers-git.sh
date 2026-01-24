#!/usr/bin/env zs

############### Helpers: Git

# Relies upon:
#   helpers-reporting.sh

function configure_split_remote_URLs_by_public_GitHub_repo_name() {
  # Locally configures public GitHub repo to fetch without authentication using HTTPS
  # but push using SSH.
  #
  # Addresses GitHub policy to not allow CLI authentication using HTTPS without
  # inconveniently and pointlessly requiring authentication for fetch of a public repo.
  #
  # Usage:
  #   cd ~/.genomac-system
  #   configure_split_remote_URLs_by_public_GitHub_repo_name "GenoMac-system"
  #
  #   cd ~/.genomac-user
  #   configure_split_remote_URLs_by_public_GitHub_repo_name "GenoMac-user"
  
  report_start_phase_standard

  local github_repo_name="$1"
  
  # Configure split remote URLs (HTTPS fetch / SSH push)
  report_action_taken "Configure local clone of ${github_repo_name} to fetch with HTTPS but push with SSH"
  report_adjust_setting "Configure ${github_repo_name} to fetch via HTTPS"
  git remote set-url origin https://github.com/jimratliff/"${github_repo_name}".git ; success_or_not
  report_adjust_setting "Configure ${github_repo_name} to push via SSH"
  git remote set-url --push origin git@github.com:jimratliff/"${github_repo_name}".git ; success_or_not
  
  report_end_phase_standard
}
