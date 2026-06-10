# User classes and attributes

## User attributes
An attribute can be atomic or it can imply a set of other attributes.

- mac-admin
- developer
- dropbox
- sync-com
- emailer
- microsoft-word
- youtube-watcher
- chessplayer
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
