# Limitations on the lengths of a user’s shortname (and volume name if not the startup volume) arising from 1Password SSH Agent

There is a limitation (a) on the length of a user’s shortname and (b) on the length of the name of the volume on which the user’s home directory resides (if the user’s home directory is not on the startup volume). 

This limitation arises from a very particular limitations that arises in order to configure the 1Password SSH Agent to authenticate with GitHub.

Because (a) most users in Project GenoMac will want at least the option to configure this 1Password SSH Agent and (b) the associated restriction is not very onerous, the policy decision has been made that *all* Project GenoMac users must have shortnames and volume names that satisfy this constraint.[^WHY_ALL_USERS_AS_A_POLICY]

[^WHY_ALL_USERS_AS_A_POLICY]: It simplifies the coding and logic to have a uniform policy across *all* users. Since the restriction on lengths of these names isn’t very onerous, the cost of the policy on those few users who don’t want the option to configure the 1Password SSH Agent is too small to warrant the costs of working around them.

- If a user’s home directory resides on the startup volume, that user’s shortname must be no longer than 34 characters.
- If a user’s home directory resides on a volume other than the startup volume, there are only 22 characters that can be distributed between the user’s shortname and the user’s volume name.
