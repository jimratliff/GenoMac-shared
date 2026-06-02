# The scope of declarativeness in Project GenoMac

(This is part of the documentation within [GenoMac-shared](https://github.com/jimratliff/GenoMac-shared) that relates to both the [GenoMac-system](https://github.com/jimratliff/GenoMac-system) and [GenoMac-user](https://github.com/jimratliff/GenoMac-user) repositories.)

Project GenoMac *could*, but does *not*, attempt to specify all settings for a user or a macOS installation.

Instead, Project GenoMac acknowledges that there are default settings out of the box. Project GenoMac, for the most part,
identifies only settings whose default values are different from Project GenoMac’s *desired* values.[^EMPHASIZING_DEFAULTS]

Thus, repetition of maintenance steps is not guaranteed to restoring a system to the same state that was reached after the first full
run, because the user may have changed a default setting with which Project Genomac did not disagree and thus does not enforce.

[^EMPHASIZING_DEFAULTS]: In some cases, Project Genomac chooses to enforce a setting even when the enforced setting is
identical to the default setting. This is sometimes accompanied by “emphasizes the default.”
