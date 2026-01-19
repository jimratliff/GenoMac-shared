# Context

This repo is intended to be added as a submodule by each of (a) [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and (b) [GenoMac-user](https://github.com/jimratliff/GenoMac-user).

# Assumed directory structure
```
 ~/.genomac-user/ (or ~/.genomac-system)
   external/
     genomac-shared/
       assign_common_environment_variables.sh
       helpers-apps.h
       …
       helpers.sh
   scripts/
     0_initialize_me.sh        # You are HERE!
     an_entry_point_script.sh  # The script of interest, will source 0_initialize_me.sh
     prefs_scripts/
```

# The `scripts` directory

This `scripts` directory contains multiple script files which define helper functions.

The particular `helpers.sh` file is distinguished as the master, in the sense that it 
is responsible for sourcing all of the other subsidiary helper files.
