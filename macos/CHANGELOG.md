# Changes

## 1.2 — Options live preview

- Replaced the embedded ScreenSaverView UI subview with an ordinary AppKit image view driven by explicit offscreen rendering.
- Redraw the visible preview immediately after sliders, palettes, presets, CRT, reset, or randomization change.
- Animate during slider tracking using the run loop's common modes.
- Use the selected 15/30/60 fps setting for the editor preview timer.
- Render at the window's backing resolution for Retina displays.
- Keep draft preview settings separate from saved screen saver preferences.

The fix applies to the native Options sheet and the companion settings app. Screenshot-matched defaults and configuration export behavior are retained.
