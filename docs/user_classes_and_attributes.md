# User classes and attributes

## User attributes
An attribute can be atomic or it can imply a set of other attributes.

| Attribute name | Environment variable | Comment |
|---|---|---|
| mac-admin         | USER_ATTRIBUTE_MAC_ADMIN |         Comment |
| genomac-developer | USER_ATTRIBUTE_GENOMAC_DEVELOPER |         Comment |
| developer         | USER_ATTRIBUTE_DEVELOPER |         Comment |
| dropbox           | USER_ATTRIBUTE_DROPBOX |         Comment |
| sync-com          | USER_ATTRIBUTE_SYNC_COM |         Comment |
| emailer           | USER_ATTRIBUTE_EMAILER |         Comment |
| microsoft-word    | USER_ATTRIBUTE_MICROSOFT_WORD |         Comment |
| youtube-watcher   | USER_ATTRIBUTE_YOUTUBE_WATCHER |         Comment |
| chessplayer       | USER_ATTRIBUTE_CHESSPLAYER |         Comment |
| commit_on_github  | USER_ATTRIBUTE_COMMIT_ON_GITHUB |         Comment |


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
