#!/usr/bin/env zs

# Sources all of this repo’s helper scripts and common (cross-repo) environment variables.
# Intended to be called from 0_initialize_me_second.sh from either GenoMac-system or GenoMac-user.
# Relies on 0_initialize_me_first.sh having already defined source_with_report().

set -euo pipefail

# Prevent multiple sourcing
if [[ -n "${__already_loaded_genomac_shared_helpers_sh:-}" ]]; then return 0; fi
__already_loaded_genomac_shared_helpers_sh=1
export __already_loaded_genomac_shared_helpers_sh

# Resolve this script's directory (even if sourced)
# NOTE: There are two methods for specifying the location of GenoMac-shared code:
# - the method employed here, querying the location of this script
# - the GMS_HELPERS_DIR environment variable, which is exported by 0_initialize_me_second.sh
#   which gives the path to the scripts directory of the GenoMac-shared repository as
#   included as a submodule.
this_script_path="${0:A}"
this_script_dir="${this_script_path:h}"

# Source each subsidiary helper file, all assumed to reside in same directory as this file
source_with_report "${this_script_dir}/helpers-apps.sh"
source_with_report "${this_script_dir}/helpers-copying.sh"
source_with_report "${this_script_dir}/helpers-defaults.sh"
source_with_report "${this_script_dir}/helpers-git.sh"
source_with_report "${this_script_dir}/helpers-hypervisor.sh"
source_with_report "${this_script_dir}/helpers-interactive.sh"
source_with_report "${this_script_dir}/helpers-misc.sh"
source_with_report "${this_script_dir}/helpers-reporting.sh"
source_with_report "${this_script_dir}/helpers-state.sh"

# Source common environment variables
# Assumes that assign_common_environment_variables.sh resides in same directory as this file
source_with_report "${this_script_dir}/assign_common_environment_variables.sh"

function main() {
  # define_colors_and_symbols is defined in scripts/helpers-reporting.sh
  define_colors_and_symbols
}

main

