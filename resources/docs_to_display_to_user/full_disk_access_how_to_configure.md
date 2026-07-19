# How to configure Full Disk Access for the currently running terminal program

## Why this document has opened for you to see it
A script has tested whether the currently running terminal app can access a restricted location.
The terminal app failed that test, meaning that the terminal app does *not* have Full Disk Access (FDA).

It is important that the terminal app have FDA. This is your opportunity to make that happen. (Apple doesn’t 
allow GenoMac-system to do this automatically. You need to take a step *manually*.)

## Look for an opened Settings panel: Privacy & Security » Full Disk Access
- ❑ Find the already opened Settings panel: Privacy & Security » Full Disk Access. 

Look for it behind other windows if necessary.

## Flip the switch from OFF to ON for the currently running terminal app
That Settings panel should have a list of apps, that now includes the currently running terminal app.

- ❑ Flip the “switch” for the currently running terminal app from OFF to ON.
- ❑ Close the Privacy & Security » Full Disk Access window.

> [!NOTE]
> You’ll be told that Full Disk Access won’t take effect until after the terminal quits and relaunches. If you choose immediately to quit and relaunch,
> you’ll quit the terminal and the current run of Hypervisor. After relaunching the terminal, just re-start the Hypervisor with either (a) `make run-hypervisor` (if the first time running GenoMac-system) or (b) `just run-hypervisor`.

## Return to terminal and acknowledge
- ❑ Type `done` to acknowledge that you’ve completed these manual steps.

## Be tidy: Close this document
- ❑ Close this document
