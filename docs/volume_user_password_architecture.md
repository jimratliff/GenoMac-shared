# The volume, user, and password architecture of Project GenoMac

> [!TIP]
> **Related**
> - [User attributes](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/user_classes_and_attributes.md), GenoMac-shared/docs
> - [Specifying users to spawn](https://github.com/jimratliff/GenoMac-system/edit/main/scripts/spawn/0_README.md), GenoMac-system/scripts/spawn

> [!NOTE]
> **Table of contents**
> - [High-level overview](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/volume_user_password_architecture.md#high-level-overview)
> - [The process for a resident user to boot the Mac and log into its account](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/volume_user_password_architecture.md#the-process-for-a-resident-user-to-boot-the-mac-and-log-into-its-account)
> - [Formal details](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/volume_user_password_architecture.md#formal-details)

## High-level overview
We focus on a particular Mac.[^multiple_macs] Each Mac has multiple volumes.[^container_structure] There is (a) the startup volume (protected by File Vault) and (b) other, independently encrypted (non-startup and non–File Vault) volumes. Each volume has a unique passphrase.

[^multiple_macs]: The use case that motivates Project GenoMac does include multiple Macs in the following context: Each Mac is approximately a replica of the other Macs, including the set of users that have accounts on each Mac. The idea is not that each Mac is used by a separate person than each other Mac but rather the same person operates all the Macs. Although each Mac has multiple “users” in the macOS sense, all of those users are typically the same human.

[^container_structure]: For the most part, if not entirely, Project GenoMac doesn’t concern itself with *containers* but only *volumes*. It matters what volumes are mounted. Once mounted, the volume’s name identifies that volume, without regard to the container on which it resides.

There are two major groups of users:
- superintendant-class users: These users exists only to help manage the Mac itself and facilitate its use by “resident users.” The home directories of the superintendant-class users reside on the startup volume and don’t contain highly sensitive information.[^no_sensitive_info] These users all have Secure Tokens for the File Vault–protected startup volume and hence can mount the startup volume.
- resident users: These are the important users who do important things. Each resident user has a home directory that resides on an independently encrypted volume other than the startup volume.

[^no_sensitive_info]: Here, no “highly sensitive information” means, for example, no client-confidential or personal financial information. The sensitive information that *is* on the startup volume is limited to passwords or passphrases, but even those are stored in independently encrypted password-management vaults (themselves within the File Vault–protected startup volume).

More granular than the above two groups, Project GenoMac defines multiple user-classes.
- A user-class includes all users, and only those users, that share both (a) a common user password and (b) a common volume for the users home directories.[^user-class-can’t-span-volumes]
- The superintendent class is a user class. All superintendent-class users have their home directories on the startup volume.
- The group of resident users can span multiple other (non–superintendent) user classes.

A user can have *attributes*, which can either (a) be inherited by the user from its user class or (b) be assigned specifically to the user. See [User attributes](https://github.com/jimratliff/GenoMac-shared/blob/main/docs/user_classes_and_attributes.md).

[^user-class-can’t-span-volumes]: The current structure doesn’t permit home directories of some users of a given user-class to be on a different volume than the home directories of other users of that user class.

Each resident user needs to know *two* sets of credentials: (a) their own, of course, but also (b) the credentials for one of the superintendent-class users (in practice, simply the password that is common to all superintendent-class users)—in order to be able to boot the Mac into the superintendent-class user’s account, from which to mount the volume where the resident user’s home directory resides.

## The process for a resident user to boot the Mac and log into its account
- Boot the Mac
- Log in as any of the superintendent-class users. This mounts the startup volume.
- A dialog box will be presented for each other not previously mounted volume, offering to take the passphrase for that volume and mount it.
- Enter the passphrase for the volume on which this resident user has their home directory. (Note that, by design, this passphrase is the same as the account password for this resident user.) Decline the dialog boxes for all other volumes.
- Log out of the superintendent-class user’s account, returning to the login window.
- Log into the resident user’s account (using the same passphrase as was used to mount this non-startup volume).

## Formal details
### Volumes
- Let V be the set of volumes.
- V = {v<sup>†</sup>, v<sub>1</sub>, v<sub>2</sub>, …}, where v<sup>†</sup> is the startup volume,[^why_startup_is_different] and each v<sub>i</sub> is a distinct non–startup volume.
- Each volume v∈V has a unique passphrase v.p.[^unique_password_for_volume]
- For each *non-startup* volume v∈V\\{v<sup>†</sup>}, v is encrypted (*not* using File Vault) using passphrase v.p.
- The *startup* volume v<sup>†</sup> is encrypted using File Vault.[^file_vault_mounted_by]
### Users
  - Let U be the set of users[^PREEXISTING_USERS]
  - User classes
    - Let U<sub>S</sub> be the superintendent class.
    - Let U<sup>§</sup> be the set of user classes such that U<sup>§</sup>={U<sub>S</sub>, U<sub>1</sub>, U<sub>2</sub>, … , U<sub>n</sub>} partitions U.
    - Each user class U<sub>i</sub> is assigned a unique volume U<sub>i</sub>.v.[^unique_volume]
      - In particular, the superintendent user class U<sub>S</sub> is assigned the startup volume v<sup>†</sup>, i.e., U<sub>S</sub>.v = v<sup>†</sup>.
    - The user’s volume determines the path to the user’s home directory. Suppose the user’s short name is 'some_user':
      - If the user’s user class is 'superintendent',[^other_reason_startup] the user’s home directory is `/Users/some_user`
      - If the user’s user class isn’t 'superintendent', the user’s home directory is `/Volumes/some_volume/Users/some_user`, where "some_volume" is the volume assigned to the user’s user class.
    - Each user class U<sub>i</sub> is assigned a unique passphrase[^unique_password_for_user_class] U<sub>i</sub>.p via inheritance from the user class’s volume
      - ∀U<sub>i</sub>∈U<sup>§</sup>, U<sub>i</sub>.p = (U<sub>i</sub>.v).p
  - Each user u is assigned (a) a volume u.v and (b) a passphrase u.p by inheritance from the user’s user class
    - ∀U<sub>i</sub>∈U<sup>§</sup>, ∀u∈U<sub>i</sub>
      - u.v = U<sub>i</sub>.v
        - The volume u.v is the volume that contains the user’s home directory
      - u.p = U<sub>i</sub>.p
        - The passphrase u.p serves both as (a) the passphrase by which the user can decrypt/mount the volume u.v that contains the user’s home directory and (b) the password by which the user logs into the user’s account.
       
[^PREEXISTING_USERS]: The focus here is on users that are managed, and frequently created, by Project GenoMac. However, it is assumed that USER_VANILLA exists prior to the creation of USER_CONFIGURER. Thus, USER_VANILLA is neither created nor managed by Project GenoMac. Nevertheless, USER_VANILLA belongs to the superintendent user class by virtue of residing on the startup volume.
 
[^unique_password_for_volume]: ∀v,v′∈V, (v ≠ v′) ⇒ (v.p ≠ v′.p.)

[^file_vault_mounted_by]: The startup volume will be mounted when any user with a Secure Token for that volume logs in. The startup volume *does* have a passphrase, but no human user knows it. Instead, any user with a Secure Token, by logging into that user’s account, internally decrypts that passphrase, which is then used to mount the startup volume.

[^other_reason_startup]: Or if the user’s volume is "::startup_volume::" even if the user’s user class isn’t "superintendent" (though I haven’t thought of a use case for this).

[^unique_volume]: ∀U<sub>i</sub>,U<sub>j</sub>∈U<sup>§</sup>, (U<sub>i</sub> ≠ U<sub>j</sub>) ⇒ (U<sub>i</sub>.v ≠ U<sub>j</sub>.v).

[^unique_password_for_user_class]: ∀U<sub>i</sub>,U<sub>j</sub>∈U<sup>§</sup>, (U<sub>i</sub> ≠ U<sub>j</sub>) ⇒ (U<sub>i</sub>.p ≠ U<sub>j</sub>.p).

[^why_startup_is_different]: The startup volume is referenced distinctly from other volumes in the sense that the startup volume is not referenced by name but rather by the environment variable `STARTUP_VOLUME_SIGNIFIER="::startup_volume::"`. This distinction in how a startup volume is referenced vis-à-vis how another volume is referenced arises because the path to a home directory on the startup volume is `/Users/some_user`, whereas the path to a home directory on another volume is `/Volumes/some_volume/Users/some_user`. Thus, the path to a user home directory on the startup volume doesn’t explicitly reference the volume name of the startup volume.
