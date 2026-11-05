# Plasma Lab for macOS — version 1.1

Native Amiga-style plasma screen saver, now with screenshot-matched defaults and a companion Mac settings app for systems where the built-in Options button does not open.

## Replace your current version

1. Quit System Settings.
2. Double-click **Plasma Lab.saver** from this download and approve replacing the previous installation. Choose your own user account if offered.
3. Reopen System Settings and select Plasma Lab. On newer macOS releases, the screen saver picker is under Wallpaper; on other releases it has its own Screen Saver section.
4. If the old appearance remains, select another screen saver and then select Plasma Lab again. If macOS keeps a cached old copy, restart the Mac.

If double-clicking does not offer installation, use Finder → Go → Go to Folder → `~/Library/Screen Savers/` and replace **Plasma Lab.saver** there while System Settings is closed. Avoid leaving duplicates installed for both your user and all users.

## Your screenshot is the default

- Block width and height: **25 × 25 reference pixels**.
- Grid density: **100%**.
- Pixel gap: **0%**.
- Wave speed: **0.50×**.
- Wave scale: **0.75×**.
- Turbulence: **50%**.
- Palette: **Amiga dreams**.
- Color drift: **35%**.
- CRT scanlines and vignette: **off**.
- Frame rate: **30 fps** (not specified in the screenshot).

The included HTML app also uses these defaults, with mouse/touch interaction off as pictured. Restore Defaults uses these values. The four named presets remain available as separate looks.

Version 1 preferences are intentionally superseded so reinstalling the new default saver applies your requested appearance. Settings saved in the revised native Options sheet are associated with their installed profile.

## Change settings on macOS 27.0.1

The native Options sheet now has a retained controller, an explicit content view controller, and main-thread creation. However, System Settings may still fail to present third-party screen saver Options on some macOS releases.

Use the included **Plasma Lab Settings.app** to bypass that button:

1. Open **Plasma Lab Settings.app**. You can keep it in Applications or run it from the extracted download.
2. Adjust the native sliders, palette, presets, frame rate, and CRT toggle. The preview updates immediately.
3. Click **Save & Install…**.
4. Save the configured **Plasma Lab.saver** in Downloads or another temporary location outside the installed Screen Savers folder. If Finder already has an exported copy there, approve replacement.
5. The app embeds your settings, applies a new local ad-hoc signature, and asks macOS to open the screen saver installer. Approve replacing the installed saver.
6. Select Plasma Lab again in System Settings. If an old instance is cached, switch to another saver and back, or restart the Mac.

The companion remembers its last exported settings. Changes take effect through installation of the exported saver; clicking sliders alone does not alter the installed copy. Each exported saver carries its own configuration, so this workflow does not depend on access to the screen saver host's separate preferences container. Exporting and signing do not require Xcode.

The companion's **Cancel** button closes it without exporting. **Restore Defaults** changes the editor back to your screenshot values; use Save & Install to apply them. If the built-in Options sheet opens, its **Save** button saves directly for that installed profile and **Cancel** discards edits.

Keep the settings app and its internal files together; do not move the nested template out of the `.app` package.

## macOS security

Both the screen saver and companion app are locally ad-hoc signed, not Developer ID signed or Apple notarized. Downloaded copies may be blocked. If macOS offers **Open Anyway** under Privacy & Security, use it only if you trust this download. Managed Macs may disallow third-party apps or screen savers.

No security settings, quarantine attributes, or other apps' containers are changed by this project. Source and rebuild scripts are included. No installer or System Settings changes were performed on your behalf during development.

## Controls and rendering

Eight native sliders control block width/height, density, gap, speed, scale, turbulence, and color drift. Six palettes and four presets are available, alongside Surprise Me, Restore Defaults, and 15/30/60 fps choices.

Block sizes use a 1280-unit reference width so the preview and large displays show consistent compositions. Very dense grids are limited to approximately 36,000 blocks to control rendering cost. Frame rate depends on the Mac and display configuration.

macOS handles starting, fullscreen display, dismissal, and locking. Mouse interaction, manual pause, and PNG export remain features of the included HTML app. Set idle delay and password behavior separately in System Settings → Lock Screen.

## Compatibility, source, and removal

Both bundles contain arm64 and x86_64 binaries targeting **macOS 14 or later**. This is a traditional `.saver` plug-in, not a dynamic wallpaper or aerial-video extension. The user reported that version 1 animates successfully on macOS 27.0.1; the revised System Settings Options presentation has not been confirmed there.

With Apple's Xcode Command Line Tools installed, open Terminal in `Source` and run:

```sh
./build.sh
./verify.sh
```

The build script compiles the screen saver and companion launcher for both architectures and signs each bundle in a temporary staging folder. Verification uses isolated test preferences and temporary exports; it does not install a saver or change your active settings.

To remove Plasma Lab, remove its `.saver` from `~/Library/Screen Savers/` (or `/Library/Screen Savers/` for an all-users installation) and remove the companion app. Reopen System Settings afterward.

See `VERIFICATION.md` for the checks performed and remaining limits.

## References

- Apple's [ScreenSaverView API](https://developer.apple.com/documentation/screensaver/screensaverview) and [configureSheet API](https://developer.apple.com/documentation/screensaver/screensaverview/configuresheet).
- [Apple developer forum discussion](https://developer.apple.com/forums/thread/787444) documenting screen saver host issues and reports of Options buttons failing to open. This supports treating the host as a possible cause; it does not establish the exact cause on this user's Mac.
