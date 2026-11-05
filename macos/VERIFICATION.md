# Version 1.1 verification

Completed on the available Apple silicon Mac:

- Compiled screen saver and companion app for arm64 and x86_64, targeting macOS 14 or later.
- Loaded the final screen saver bundle through NSBundle and verified the principal ScreenSaverView class.
- Started, advanced, rendered, and stopped the native animation; visually inspected its PNG output.
- Asserted all eight slider defaults against the screenshot and confirmed CRT is off.
- Constructed the Options sheet with an explicit content view controller.
- Exercised all eight sliders at their maximum values and every menu choice.
- Attached the Options window as an actual AppKit sheet and dismissed it using Cancel.
- Verified the same Options window survives creation of another screen saver view.
- Verified Cancel discards edits, Save persists changes and reloads them, and Restore Defaults restores screenshot values. Preference tests use a unique test domain, never the user's real preferences.
- Generated a configured `.saver` using the companion's export implementation, verified its signature, and loaded it in a separate process to confirm its embedded settings take effect.
- Validated both architecture slices, bundle metadata, and ad-hoc signatures for both the screen saver and companion app.
- Confirmed the HTML has no external dependencies and its default values match the screenshot.

Source/verify.sh reproduces native checks without installing a screen saver. Temporary test preferences are cleared afterward.

A direct companion-app launch test could not complete in this restricted build environment: macOS aborted application registration before the settings UI was created. A normal LaunchServices launch attempt was also refused with a “missing executable” error even though the executable exists, is executable, and passes signature and architecture checks. Full companion launch therefore remains unverified; its shared native controls, embedded template, export code, binary architectures, and signature were checked separately. The optional `PLASMA_LAB_VERIFY_APP_UI=1 ./verify.sh` adds a direct app-launch test on a normal desktop session.

Remaining limits: actual System Settings Options-button routing on the user's macOS 27.0.1, the installation/replacement prompt, idle activation and dismissal, multi-display and lock-screen behavior, Intel hardware execution, and sustained frame rate have not been verified. The user's report confirms that the earlier screen saver itself ran, while Options did not open. The companion is an independent configuration/export route; it does not claim to repair macOS's host.

Neither bundle is Developer ID signed or notarized. ZIP packaging excludes extended attributes; signature checks use clean copies to avoid transient Finder metadata attached by the synced Documents folder.
