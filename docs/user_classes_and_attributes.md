# User classes and attributes

> [!TIP]
> **Related**
> - [The volume, user, and password architecture of Project GenoMac](https://github.com/jimratliff/GenoMac-shared/edit/main/docs/volume_user_password_architecture.md), GenoMac-shared/docs
> - [About spawning new users for this Mac](https://github.com/jimratliff/GenoMac-system/edit/main/scripts/spawn/0_README.md), GenoMac-system/scripts/spawn

## User attributes
An attribute can be atomic or it can imply a set of other attributes.

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
| "              | dropbox           | USER_ATTRIBUTE_DROPBOX |
| personal       | dropbox           | USER_ATTRIBUTE_DROPBOX |
| work           | dropbox           | USER_ATTRIBUTE_DROPBOX |
| "              | sync-com          | USER_ATTRIBUTE_SYNC_COM |
| "              | microsoft-word    | USER_ATTRIBUTE_MICROSOFT_WORD |
| auxiliary      | dropbox           | USER_ATTRIBUTE_DROPBOX |
| "              | sync-com          | USER_ATTRIBUTE_SYNC_COM |

