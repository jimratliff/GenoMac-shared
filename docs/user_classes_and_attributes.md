# User classes and attributes

## User attributes
An attribute can be atomic or it can imply a set of other attributes.

| Attribute name | Environment variable | Comment |
|---|---|---|
| chessplayer       | USER_ATTRIBUTE_CHESSPLAYER |       Comment |
| developer         | USER_ATTRIBUTE_DEVELOPER |         USER_DEV, USER_SAASER                |
| dropbox           | USER_ATTRIBUTE_DROPBOX |           All users.[^DROPBOX]                 |
| emailer           | USER_ATTRIBUTE_EMAILER |           USER_JIM, USER_EMPLOYMENT, possibly USER_SASSER |
| genomac-developer | USER_ATTRIBUTE_GENOMAC_DEVELOPER | USER_MAC and/or USER_CONFIGURER ⇒ 'developer'[^GENOMAC-DEVELOPER]|
| mac-admin         | USER_ATTRIBUTE_MAC_ADMIN |         USER_MAC & USER_CONFIGURER[^MAC-ADMIN] |
| microsoft-word    | USER_ATTRIBUTE_MICROSOFT_WORD |    USER_EMPLOYMENT                        |
| raindrop-io       | USER_ATTRIBUTE_RAINDROP_IO |                                              |
| sync-com          | USER_ATTRIBUTE_SYNC_COM |          USER_ME, USER_EMPLOYMENT               |
| youtube-watcher   | USER_ATTRIBUTE_YOUTUBE_WATCHER |   Primarily to specify use of “Enhancer for YouTube™” extension |

[^GENOMAC-DEVELOPER]: A user with this attribute may be (a) USER_CONFIGURER (who *executes* GenoMac-system exclusively) or (b) USER_MAC, or both. Such a user will have *two* local copies of each of GenoMac-system and GenoMac-user: (a) one set at `~/.genomac-system` and `~/.genomac-user` and (b) a development set at `~/repositories/genomac-system` and `~/repositories/genomac-user`. This second set of copies are where active development of these repos takes place. This attribute should always imply as well the 'developer' attribute.
[^DROPBOX]: Dropbox is central to many aspects of GenoMac-user configurations, thus essentially every user needs to install and use Dropbox.
[^MAC-ADMIN]: This attribute belongs to a user that is devoted to maintaining, enhancing, etc., the Macs and their environment, in a broader way that USER_CONFIGURER does.


#
The following are deprecated and implied by `developer`
- commit_on_github
- authenticate_github_via_1password
#
DEFAULT USER ATTRIBUTES BASED ON USER CLASS
- superintendent
  - macadmin
  - developer ⇒
    - github_committer
    - authenticate_github_via_1password
  - dropbox
- personal
  - dropbox
- work
  - dropbox
  - sync_com
  - microsoft_word
- auxiliary
  - dropbox
  - sync_com
