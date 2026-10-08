# Nightly auto save

Picartdo saves and uploads to GitHub every night at 11 PM.

* Runs from: `scripts/autosave.sh` (scheduled by macOS launchd, `com.picartdo.autosave`)
* History: `.autosave.log` in the project folder
* Run it now by hand: `launchctl kickstart gui/$(id -u)/com.picartdo.autosave`
* Turn it off: `launchctl bootout gui/$(id -u)/com.picartdo.autosave`
