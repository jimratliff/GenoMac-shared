# Limitations on the lengths of a user’s shortname (and volume name if not the startup volume) arising from 1Password SSH Agent

There is a limitation (a) on the length of a user’s shortname and (b) on the length of the name of the volume on which the user’s home directory resides (if the user’s home directory is not on the startup volume). 

This limitation arises from a very particular limitations that arises in order to configure the 1Password SSH Agent to authenticate with GitHub.[^DETAILS_OF_LIMITATION]
- If a user’s home directory resides on the startup volume, that user’s shortname must be no longer than 34 characters.[^USER_ON_STARTUP_VOLUME]
- If a user’s home directory resides on a volume other than the startup volume, there are only 24 characters that can be distributed between the user’s shortname and the user’s volume name.[^USER_ON_OTHER_VOLUME]

[^DETAILS_OF_LIMITATION]: macOS Unix-domain socket pathnames are stored in the `sun_path` field of `struct sockaddr_un`. On macOS, `sockaddr_un.sun_path` is 104 bytes, including the terminating NUL byte. (For ordinary ASCII paths, bytes and characters are the same.) Therefore, the fully expanded pathname of a Unix-domain socket must fit within a 103-character field. 1Password creates its SSH-agent socket at `$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`, which is `$HOME` plus a 63-character suffix. Thus, `$HOME` is limited to 40 characters.

[^USER_ON_STARTUP_VOLUME]: When the user’s home directory is on the startup volume, the path to the user’s home directory is of the form `/Users/short-name`. Thus the user’s shortname is limited to 34 characters, which allows for the `/Users` and the 34-character shortname to come within the 40-character limit on `$HOME`.

[^USER_ON_OTHER_VOLUME]: When the user’s home directory is on a different volume, the path to the user’s home directory is of the form `/Volumes/volume-name/Users/short-name`. Without taking into account the user’s volume name or shortname, there are 16 characters of overhead in `/Volumes//Users/`, leaving 24 characters to be allocated among the shortname and volume name and still comply with the 40-character limit for `$HOME`.

Thus the user’s shortname is limited to 34 characters, which allows for the `/Users` and the 34-character shortname to come within the 40-character limit on `$HOME`.

Because (a) most users in Project GenoMac will want at least the option to configure this 1Password SSH Agent and (b) the associated restriction is not very onerous, the policy decision has been made that *all* Project GenoMac users must have shortnames and volume names that satisfy this constraint.[^WHY_ALL_USERS_AS_A_POLICY]

[^WHY_ALL_USERS_AS_A_POLICY]: It simplifies the coding and logic to have a uniform policy across *all* users. Since the restriction on lengths of these names isn’t very onerous, the cost of the policy on those few users who don’t want the option to configure the 1Password SSH Agent (imposed as a limitation about the lengths of their shortnames and volume name) is too small to warrant the development costs to permit these users to have longer names than the majority of other users.
