# User attributes

> [!TIP]
> **Related**
> - [The volume, user, and password architecture of Project GenoMac](https://github.com/jimratliff/GenoMac-shared/edit/main/docs/volume_user_password_architecture.md), GenoMac-shared/docs
> - [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/edit/main/scripts/spawn/0_README.md), GenoMac-system/scripts/spawn

A user attribute can be referenced by GenoMac-user’s Hypervisor to customize the configuration of that user.[^customize_per_attributes]

[^customize_per_attributes]: This customization occurs via `GenoMac-user/scripts/settings/user_attribute_scripts.sh`.

A user can (a) inherit from its user class any default attributes associated with that user class[^inherit_attribute_from_user_class] or (b) be assigned attributes directly.[^assign_user_attributes_directly]

[^inherit_attribute_from_user_class]: The mapping from user class → default user attributes is specified in the `user_attributes_from_user_class` JSON property. See [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/blob/main/scripts/spawn/0_README.md#about-spawning-new-users-for-this-mac).
[^assign_user_attributes_directly]: Attributes assigned directly to a user are supplied via the `users_to_create` JSON property, which is an array of user objects. Specifically, the user attributes assigned to a user are specified in the `attributes` property of that user’s object. See [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/blob/main/scripts/spawn/0_README.md#about-spawning-new-users-for-this-mac).

A user’s attributes are assigned when that user’s account is created. The USER_CONFIGURER account is a special case.[^USER_CONFIGURER_ATTRIBUTES_A_SPECIAL_CASE]

[^USER_CONFIGURER_ATTRIBUTES_A_SPECIAL_CASE]: USER_CONFIGURER is the account that first executes the Hypervisor of GenoMac-system and, thus, it must exist before GenoMac-system is even cloned locally. Thus, USER_CONFIGURER is not created by GenoMac-system and thus cannot have its attributes assigned during the user-creation process. Instead, GenoMac-system’s Hypervisor assigns default attributes to USER_CONFIGURER prior to USER_CONFIGURER running GenoMac-*user*’s Hypervisor to configure USER_CONFIGURER’s own user account. GenoMac-system’s Hypervisor implements these default attribute assignments via `conditionally_set_default_attributes_for_USER_CONFIGURER`, which assigns the attributes stored in the array environment variable `GENOMAC_STATE_USER_CONFIGURER_DEFAULT_ATTRIBUTES`, which is defined in `GenoMac-shared/scripts/assign_common_environment_variables.sh`. To be clear, GenoMac-system’s Hypervisor can’t access 1Password’s specifications of user attributes at this point precisely because USER_CONFIGURER’s account hasn’t been configured and thus USER_CONFIGURER’s 1Password hasn’t been configured.

An attribute can be atomic or it can imply a set of other attributes.

## Currently defined user attributes
The below table lists currently defined user attributes, both by name and by the environment variable that defines its name.

Attribute names aren’t limited to these. No error is raised (although a warning is issued[^UNRECOGNIZED_ATTRIBUTE_WARNING]) if a user is assigned an unrecognized attribute. The unrecognized attribute is ignored.

[^UNRECOGNIZED_ATTRIBUTE_WARNING]: The unrecognized-attribute warning is produced by GenoMac-user’s Hypervisor’s function `set_user_preferences_for_attribute`.

| Attribute name | Environment variable | Comment |
|---|---|---|
| chessplayer       | USER_ATTRIBUTE_CHESSPLAYER         | USER_CHESS, USER_SAASER[^CHESSPLAYER] |
| developer         | USER_ATTRIBUTE_DEVELOPER           | USER_DEV, USER_SAASER[^DEVELOPER] |
| dropbox           | USER_ATTRIBUTE_DROPBOX             | All users.[^DROPBOX] |
| emailer           | USER_ATTRIBUTE_EMAILER             | USER_ME, USER_EMPLOYMENT, possibly USER_SASSER[^EMAILER] |
| genomac-developer | USER_ATTRIBUTE_GENOMAC_DEVELOPER   | USER_MAC and/or USER_CONFIGURER ⇒ 'developer'[^GENOMAC-DEVELOPER]|
| IS_USER_CONFIGURER | USER_ATTRIBUTE_IS_USER_CONFIGURER | Automatically set by GenoMac-system[^IS-USER-CONFIGURER]|
| mac-admin         | USER_ATTRIBUTE_MAC_ADMIN           | USER_MAC & USER_CONFIGURER[^MAC-ADMIN] |
| microsoft-word    | USER_ATTRIBUTE_MICROSOFT_WORD      | USER_EMPLOYMENT |
| raindrop-io       | USER_ATTRIBUTE_RAINDROP_IO         | Raindrop.io browser extension and desktop app |
| sync-com          | USER_ATTRIBUTE_SYNC_COM            | USER_ME, USER_EMPLOYMENT |
| youtube-watcher   | USER_ATTRIBUTE_YOUTUBE_WATCHER     | Primarily to specify use of “Enhancer for YouTube™” extension |

[^CHESSPLAYER]:Signals that HIARCS Chess Explorer Pro and Chessvision.ai should be configured.
[^DEVELOPER]: Signals that (a) user’s name/email will be added to .gitconfig and (b) 1Password SSH Agent will be configured to authenticate at GitHub using 1Password.
[^DROPBOX]: Dropbox is central to many aspects of GenoMac-user configurations, thus essentially every user needs to install and use Dropbox.
[^EMAILER]: These are users for whom Apple’s Mail.app should be configured.
[^GENOMAC-DEVELOPER]: A user with this attribute may be (a) USER_CONFIGURER (who *executes* GenoMac-system exclusively) or (b) USER_MAC, or both. Such a user will have *two* local copies of each of GenoMac-system and GenoMac-user: (a) one set at `~/.genomac-system` and `~/.genomac-user` and (b) a development set at `~/Repositories/Project_GenoMac/genomac-system` and `~/Repositories/Project_GenoMac/genomac-user`, respectively. This second set of copies are where active development of these repos takes place. This attribute should always imply as well the 'developer' attribute.
[^IS-USER-CONFIGURER]: The Hypervisor of GenoMac-system assigns this attribute to the user currently executing that Hypervisor, because—by definition—that is USER_CONFIGURER.
[^MAC-ADMIN]: This attribute belongs to a user that is devoted to maintaining, enhancing, etc., the Macs and their environment, in a broader way that USER_CONFIGURER does.

## Default user attributes based on user class
Each user inherits any default user attributes held by the user’s user class.

| User class | Default user attributes | Environment variable |
|---|---|---|
| superintendent | mac-admin         | USER_ATTRIBUTE_MAC_ADMIN |
| personal       | dropbox           | USER_ATTRIBUTE_DROPBOX |
| work           | dropbox           | USER_ATTRIBUTE_DROPBOX |
| "              | sync-com          | USER_ATTRIBUTE_SYNC_COM |
| "              | emailer           | USER_ATTRIBUTE_EMAILER |
| "              | microsoft-word    | USER_ATTRIBUTE_MICROSOFT_WORD |
| auxiliary      | dropbox           | USER_ATTRIBUTE_DROPBOX |
| "              | sync-com          | USER_ATTRIBUTE_SYNC_COM |

