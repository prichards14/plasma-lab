# Plasma Lab — reusable project instructions

Use this brief as the basis for a new project. Build the working application described below, including a downloadable HTML file.

## Goal

Create a polished, standalone HTML/CSS/JavaScript single-page application recreating the plasma effects popular in 1990s Commodore Amiga demos. The effect is a grid of colored squares whose colors flow, change, and undulate through layered waves. Make it visually compelling and enjoyable to explore.

## Deliverable

- Deliver one downloadable, self-contained HTML file named `plasma-lab.html`.
- Embed all CSS and JavaScript. Use no external fonts, libraries, images, services, or build tools.
- It must work offline when opened directly in a modern browser.
- Include responsive styling for desktop and mobile.

## Visual direction

Call the app **Plasma Lab**. Use a polished, dark instrument-panel aesthetic with restrained lime accents, subtle borders, rounded panels, readable typography, and small monospaced labels.

Suggested copy:

- Brand: `PLASMA LAB / 001`
- Tagline: `Old school. New waves.`
- Eyebrow: `An ode to the demoscene`
- Main heading: `Pixels in a state of flow.`
- Subtitle: `Shape the waves. Find your frequency. Get a little lost.`
- Control panel heading: `Make some waves`
- Footer: `NO ASSETS. JUST MATH & A LITTLE MAGIC.`

Make the plasma display the main visual focus. On desktop, put the display on the left and a compact control panel on the right. On smaller screens, stack them. Place playback and export actions directly below the display, followed by preset buttons and a short tribute to the Amiga demoscene.

## Plasma rendering

Use a canvas with crisp, rectangular color blocks. Animate with `requestAnimationFrame` and time-based movement so speed is independent of frame rate.

Combine several sine-wave fields:

- Horizontal and vertical waves.
- A diagonal wave.
- Radial waves with slowly moving centers.
- Additional warped wave interference controlled by turbulence.

Map the resulting field into a smoothly interpolated, cyclic color palette. Precompute a palette lookup table for efficient rendering. Account for display aspect ratio so the wave geometry remains balanced.

Resize the canvas with its container. Avoid expensive per-block DOM operations. Pause time progression when playback is paused or the document is hidden, and prevent large time jumps on return.

## Controls

All controls must work immediately, with clear labels and live numeric readouts.

### Pixel geometry

- **Block width:** 3–48 px; default 25 px.
- **Block height:** 3–48 px; default 25 px.
- **Grid density:** 40–200%; default 100%. Higher density reduces effective block dimensions, increasing the number of blocks while preserving their aspect ratio.
- **Pixel gap:** 0–60%; default 0%. Show dark spacing between blocks.
- Display the current grid dimensions and total block count.

### Motion and interference

- **Wave speed:** 0–2.5×; default 0.50×.
- **Wave scale:** 0.3–2.5×; default 0.75×. Higher values show more wave repetitions across the display.
- **Turbulence:** 0–100%; default 50%. Controls additional wave interference.

### Color and atmosphere

Provide six cyclic palettes, with a visible gradient preview:

1. **Amiga dreams:** deep violet, blue, magenta, coral, peach, pale yellow, and turquoise.
2. **Molten sunset:** dark plum, burgundy, red, orange, gold, and cream.
3. **Electric ocean:** midnight blue, indigo, violet, cyan, and mint.
4. **Acid candy:** purple, hot pink, peach, yellow-green, mint, and teal.
5. **Phosphor green:** near-black green, teal, emerald, lime, and pale green.
6. **Moonlight:** navy, slate, silver, and cool pale tones.

- **Color drift:** 0–100%; default 35%. Controls palette cycling separately from wave motion.
- **CRT scanlines:** toggle, disabled by default. Add subtle scanlines and a dark vignette without intercepting pointer events.
- **Mouse / touch interaction:** toggle, disabled by default. Pointer movement introduces localized radial ripples with a smooth fade as the pointer leaves.

## Presets

Provide these quick-start presets. Selecting one updates all relevant controls and the palette. Indicate the selected preset; clear that indication after manual changes.

### 01 · Amiga dreams

- Width: 12 px
- Height: 12 px
- Density: 100%
- Gap: 4%
- Speed: 0.65×
- Wave scale: 1×
- Turbulence: 55%
- Color drift: 20%
- Palette: Amiga dreams

### 02 · Liquid heat

- Width: 8 px
- Height: 8 px
- Density: 100%
- Gap: 0%
- Speed: 0.40×
- Wave scale: 0.65×
- Turbulence: 70%
- Color drift: 12%
- Palette: Molten sunset

### 03 · Deep space

- Width: 6 px
- Height: 12 px
- Density: 110%
- Gap: 4%
- Speed: 0.35×
- Wave scale: 1.30×
- Turbulence: 38%
- Color drift: 15%
- Palette: Electric ocean

### 04 · Pixel party

- Width: 28 px
- Height: 28 px
- Density: 95%
- Gap: 18%
- Speed: 1.15×
- Wave scale: 1.50×
- Turbulence: 85%
- Color drift: 50%
- Palette: Acid candy

Also provide:

- **Surprise me:** randomizes valid control values and the palette.
- **Reset:** restores the screenshot defaults (25×25 blocks, 100% density, 0% gap, 0.50× speed, 0.75× scale, 50% turbulence, Amiga dreams palette, 35% color drift), resets animation time, and disables CRT and pointer interaction.

## Playback and export

- **Pause / Play:** freezes or resumes wave motion and color drift. Update the button label and the display status between `LIVE RENDER` and `FRAME HELD`.
- **Snapshot:** downloads a PNG of the current plasma display. Include the CRT treatment when enabled, but omit the control panel and status label. Use a timestamped filename and a brief status message.
- **Fullscreen:** expands the plasma display using the browser Fullscreen API. Handle unsupported or denied fullscreen gracefully with an in-app message.
- Show an approximate FPS readout.
- Keyboard shortcuts: **Space** toggles playback; **F** toggles fullscreen. Do not intercept shortcuts while a form control or button has focus, or when modifier keys are pressed.

## Accessibility and responsiveness

- Use semantic HTML, associated input labels, accessible button names, and visible keyboard focus indicators.
- Keep text readable and controls comfortable to use on small screens.
- Honor `prefers-reduced-motion` by starting paused when requested.
- Announce brief export or error messages through a status region.
- Keep decorative overlays from blocking interaction.

## Verification

Check JavaScript syntax and exercise initialization, rendering, every preset, every palette, pause/play, randomization, reset, slider extremes, and PNG export. Confirm there are no external asset dependencies.

When browser tools are available, also verify the appearance at desktop and mobile sizes, resizing, fullscreen, keyboard behavior, pointer interaction, and actual PNG download. Clearly state any verification limitations.

## Final handoff

Provide a direct download link to the completed HTML file, a short description of the included features, and concise instructions to open it in a browser. The user should not need to install anything.
