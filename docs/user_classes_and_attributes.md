# User attributes

> [!TIP]
> **Related**
> - [The volume, user, and password architecture of Project GenoMac](https://github.com/jimratliff/GenoMac-shared/edit/main/docs/volume_user_password_architecture.md), GenoMac-shared/docs
> - [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/edit/main/scripts/spawn/0_README.md), GenoMac-system/scripts/spawn

## Table of contents
- [The user attribute in general](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/user_classes_and_attributes.md#the-user-attribute-in-general)
- [Currently defined user attributes](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/user_classes_and_attributes.md#currently-defined-user-attributes)
- [Default user attributes based on user class](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/user_classes_and_attributes.md#default-user-attributes-based-on-user-class)
- [The encoding and path of user-attribute data](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/user_classes_and_attributes.md#the-encoding-and-path-of-user-attribute-data)

## The user attribute in general

A user attribute can be referenced by Hypervisor-User[^DISTINGUISHING_BETWEEN_HYPERVISORS] to customize the configuration of that user.[^customize_per_attributes]

[^DISTINGUISHING_BETWEEN_HYPERVISORS]: There are two distinct entities referred to as “Hypervisor.” Each of the GenoMac-system and GenoMac-user repositories has its own. In a context limited to one of those repos, its Hypervisor is referred to simply as “Hypervisor.” But in contexts that span both of these repos, we distinguish between the Hypervisors by “Hypervisor-System” and “Hypervisor-User,” respectively.

[^customize_per_attributes]: This customization occurs via `GenoMac-user/scripts/settings/user_attribute_scripts.sh`.

A user can (a) inherit from its user class any default attributes associated with that user class[^inherit_attribute_from_user_class] or (b) be assigned attributes directly.[^assign_user_attributes_directly]

[^inherit_attribute_from_user_class]: The mapping from user class → default user attributes is specified in the `user_attributes_from_user_class` JSON property. See [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/blob/main/scripts/spawn/0_README.md#about-spawning-new-users-for-this-mac).

[^assign_user_attributes_directly]: Attributes assigned directly to a user are supplied via the `users_to_create` JSON property, which is an array of user objects. Specifically, the user attributes assigned to a user are specified in the `attributes` property of that user’s object. See [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/blob/main/scripts/spawn/0_README.md#about-spawning-new-users-for-this-mac).

A user’s attributes are initially assigned when that user’s account is created. (The USER_CONFIGURER account is a special case, because that account exists before Hypervisor-System is ever run.[^USER_CONFIGURER_ATTRIBUTES_A_SPECIAL_CASE]) A user’s set of attributes can be changed, by addition or subtraction.[^CHANGING_USER_ATTRIBUTES_AFTER_CREATION]

[^USER_CONFIGURER_ATTRIBUTES_A_SPECIAL_CASE]: USER_CONFIGURER is the account that first executes the Hypervisor-System and, thus, it must exist before that user can clone GenoMac-system locally. Thus, USER_CONFIGURER is not created by GenoMac-system and thus cannot have its attributes assigned during the user-creation process. Instead, Hypervisor-System assigns default attributes to USER_CONFIGURER prior to USER_CONFIGURER running GenoMac-*user*’s -user to configure USER_CONFIGURER’s own user account. Hypervisor-System implements these default attribute assignments via `conditionally_set_default_attributes_for_USER_CONFIGURER`, which assigns the attributes stored in the array environment variable `GENOMAC_STATE_USER_CONFIGURER_DEFAULT_ATTRIBUTES`, which is defined in `GenoMac-shared/scripts/assign_common_environment_variables.sh`. To be clear, Hypervisor-System can’t access 1Password’s specifications of user attributes at this point precisely because USER_CONFIGURER’s account hasn’t been configured and thus USER_CONFIGURER’s 1Password hasn’t been configured.

[^CHANGING_USER_ATTRIBUTES_AFTER_CREATION]: The set of user attributes assigned to a user can be changed after the user’s user account is created by changing the `attributes` property of the user’s user object in the `users_to_create` JSON object. (See [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/blob/main/scripts/spawn/0_README.md), GenoMac-system/scripts/spawn/0_README.md.) Every time Hypervisor-System is run, `users_to_create` is rescanned and each user’s attributes are created from scratch as replacement system-scoped state files. Each time Hypervisor-User is run for a particular user, the system-scoped state files corresponding to user attributes of that user are read to reestablish, from scratch, the user-scoped state files corresponding to that user’s user attributes. **NOTE:** Although a particular attribute can be removed from that user’s set of user attributes, doing so will not necessarily reverse the action that was taken earlier as a result of that user attribute having been assigned to the user. Many of the settings associated with user attributes are not reversed when the attribute is removed.

An attribute can be of either of two types:
- merely binary: either present or absent or
- have an attached value and therefore can be (a) absent or (b) present with an encoded value.[^ENCODED_VALUE]

[^ENCODED_VALUE]: When an attribute allows for an encoded value, the relevant substring, even of merely the attribute name, is the attribute name conjoined to the value with the delimiter `GENOMAC_STATE_STRING_DELIMITER_X="¶∞§"`. For example, the `touchid` user attribute requires an accompanying string specifying the finger to use for Touch ID, which can encode as `'touchid¶∞§R2'`, when signifying the second finger on the right hand.

## Currently defined user attributes
The below table lists currently defined user attributes, both by name and by the environment variable that defines its name.[^BINARY_BY_DEFAULT]

[^BINARY_BY_DEFAULT]: Unless specifically noted, these are binary-valued attributes, i.e., each is either present or absent but has no other associated value.

Attribute names aren’t limited to these. No error is raised (although a warning is issued[^UNRECOGNIZED_ATTRIBUTE_WARNING]) if a user is assigned an unrecognized attribute. The unrecognized attribute is ignored.

[^UNRECOGNIZED_ATTRIBUTE_WARNING]: The unrecognized-attribute warning is produced by Hypervisor-User’s function `set_user_preferences_for_attribute`.

| Attribute name | Environment variable | Comment |
|---|---|---|
| chessplayer       | USER_ATTRIBUTE_CHESSPLAYER         | USER_CHESS, USER_SAASER[^CHESSPLAYER] |
| developer         | USER_ATTRIBUTE_DEVELOPER           | USER_DEV, USER_SAASER[^DEVELOPER] |
| dropbox           | USER_ATTRIBUTE_DROPBOX             | All users.[^DROPBOX] |
| emailer           | USER_ATTRIBUTE_EMAILER             | USER_ME, USER_EMPLOYMENT, possibly USER_SASSER[^EMAILER] |
| genomac-developer | USER_ATTRIBUTE_GENOMAC_DEVELOPER   | USER_MAC and/or USER_CONFIGURER; 'genomac-developer' ⇒ 'developer'[^GENOMAC-DEVELOPER]|
| IS_USER_CONFIGURER | USER_ATTRIBUTE_IS_USER_CONFIGURER | Automatically set by GenoMac-system[^IS-USER-CONFIGURER]|
| mac-admin         | USER_ATTRIBUTE_MAC_ADMIN           | USER_MAC & USER_CONFIGURER[^MAC-ADMIN] |
| microsoft-word    | USER_ATTRIBUTE_MICROSOFT_WORD      | USER_EMPLOYMENT |
| obsidian-user     | USER_ATTRIBUTE_OBSIDIAN_USER       |   |
| raindrop-io       | USER_ATTRIBUTE_RAINDROP_IO         | Raindrop.io browser extension and desktop app |
| sync-com          | USER_ATTRIBUTE_SYNC_COM            | USER_ME, USER_EMPLOYMENT |
| touchid           | USER_ATTRIBUTE_TOUCH_ID_ROOT       | Encoded with string, e.g., `'R2'`, specifying a particular finger for this user to use for Touch ID. The attribute name by itself is replaced with `'touchid¶∞§R2'`. |
| youtube-watcher   | USER_ATTRIBUTE_YOUTUBE_WATCHER     | Primarily to specify use of “Enhancer for YouTube™” extension |

[^CHESSPLAYER]:Signals that HIARCS Chess Explorer Pro and Chessvision.ai should be configured.
[^DEVELOPER]: Signals that (a) user’s name/email will be added to .gitconfig and (b) 1Password SSH Agent will be configured to authenticate at GitHub using 1Password.
[^DROPBOX]: Dropbox is central to many aspects of GenoMac-user configurations, thus essentially every user needs to install and use Dropbox.
[^EMAILER]: These are users for whom Apple’s Mail.app should be configured.
[^GENOMAC-DEVELOPER]: A user with this attribute may be (a) USER_CONFIGURER (who *executes* GenoMac-system exclusively) or (b) USER_MAC, or both. Such a user will have *two* local copies of each of GenoMac-system and GenoMac-user: (a) one set at `~/.genomac-system` and `~/.genomac-user` and (b) a development set at `~/Repositories/Project_GenoMac/genomac-system` and `~/Repositories/Project_GenoMac/genomac-user`, respectively. This second set of copies are where active development of these repos takes place. This attribute should always imply as well the 'developer' attribute.
[^IS-USER-CONFIGURER]: Hypervisor-System assigns this attribute to the user currently executing that Hypervisor, because—by definition—that is USER_CONFIGURER.
[^MAC-ADMIN]: This attribute belongs to a user that is devoted to maintaining, enhancing, etc., the Macs and their environment, in a broader way that USER_CONFIGURER does.

## Default user attributes based on user class
Each user inherits any default user attributes held by the user’s user class.

| User class | Default user attributes | Environment variable |
|---|---|---|
| superintendent   | mac-admin         | USER_ATTRIBUTE_MAC_ADMIN |
| personal         | dropbox           | USER_ATTRIBUTE_DROPBOX |
| work             | dropbox           | USER_ATTRIBUTE_DROPBOX |
| "                | sync-com          | USER_ATTRIBUTE_SYNC_COM |
| "                | emailer           | USER_ATTRIBUTE_EMAILER |
| "                | microsoft-word    | USER_ATTRIBUTE_MICROSOFT_WORD |
| other-user-class | dropbox           | USER_ATTRIBUTE_DROPBOX |
| "                | sync-com          | USER_ATTRIBUTE_SYNC_COM |

## The encoding and path of user-attribute data
The assignment of one or more attributes to a particular user is:
- Defined originally (a) in a user’s object within `users_to_create` JSON object[^IN_USERS_TO_CREATE_OBJECT] or (b) inherited from the user’s user class[^INHERIT_FROM_USER_CLASS]
- Encoded by Hypervisor-System in a `USER_ATTRIBUTE∞§¶shortname¶§∞attributename§∞¶` system-scoped state[^ENCODE_BY_HYPERVISOR_SYSTEM]
set_system_states_for_user_attributes "$user_spec_json" # scripts/spawn/spawn-state-helpers.sh
- For each user, Hypervisor-User transfers verbatim the system-scoped state to a `USER_ATTRIBUTE∞§¶shortname¶§∞attributename§∞¶` user-scoped state[^VERBATIM_TRANSFER]
- For each user, Hypervisor-User reviews the user attributes assigned to that user to guide configuration of that user’s account. This typically involves, for each attribute, setting one or more `SESH…` states that are implied by the attribute. Hypervisor-User then later refers to these `SESH…` states to decide which actions to take or not take.

When an attribute allows for an encoded value, the relevant substring, even of merely the attribute name, is the attribute name conjoined to the value with the delimiter `GENOMAC_STATE_STRING_DELIMITER_X="¶∞§"`. For example, the `touchid` user attribute requires an accompanying string specifying the finger to use for Touch ID, which can encode as `'touchid¶∞§R2'`, when signifying the second finger on the right hand.

[^IN_USERS_TO_CREATE_OBJECT]: Attributes assigned directly to a user are supplied via the `users_to_create` JSON property, which is an array of user objects. Specifically, the user attributes assigned to a user are specified in the `attributes` property of that user’s object. See [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/blob/main/scripts/spawn/0_README.md#about-spawning-new-users-for-this-mac).

[^INHERIT_FROM_USER_CLASS]: The mapping from user class → default user attributes is specified in the `user_attributes_from_user_class` JSON property. See [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/blob/main/scripts/spawn/0_README.md#about-spawning-new-users-for-this-mac).

[^ENCODE_BY_HYPERVISOR_SYSTEM]: Everytime Hypervisor-System runs, it reviews the list of users in the `users_to_create` JSON property. For each such user, Hypervisor-System determines the set of attributes that apply to that user (both assigned directly and inherited from that user’s user class). Hypervisor-System then writes a system-scoped state file of the form `USER_ATTRIBUTE∞§¶shortname¶§∞attributename§∞¶` that encodes both the user’s name and the attribute name. More formally, the state string is expressed in terms of enums defined by environment variables: `"${GENOMAC_STATE_USER_ATTRIBUTE_PREFIX}${GENOMAC_STATE_STRING_DELIMITER_A}${short_name}${GENOMAC_STATE_STRING_DELIMITER_B}"`.

[^VERBATIM_TRANSFER]: See Hypervisor-User’s call to `transfer_system_scoped_user_attribute_states_to_user_scoped`, which is defined in `GenoMac-user/scripts/settings/user_attribute_scripts.sh`.
