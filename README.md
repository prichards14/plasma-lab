# Plasma Lab

An offline-capable HTML/CSS/JavaScript plasma playground inspired by 1990s Commodore Amiga demos, plus a native macOS screen saver and settings editor.

## Web demo

Open `index.html` directly in a browser. No installation, build step, libraries, fonts, or network access is required.

The planned GitHub Pages address is **https://prichards14.github.io/plasma-lab/**. It becomes available after the repository is published, Pages is enabled, and the deployment succeeds.

Controls include block geometry, density, wave speed and scale, turbulence, palettes, color drift, CRT effects, pointer ripples, playback, fullscreen, presets, and PNG snapshots. Defaults match the selected reference: 25×25 blocks, 100% density, no gaps, 0.50× speed, 0.75× scale, 50% turbulence, Amiga dreams, 35% color drift, CRT off, and pointer interaction off.

## macOS screen saver

Download [Plasma Lab v1.1](downloads/Plasma-Lab-macOS-v1.1.zip). The archive includes the universal Apple silicon/Intel screen saver, companion settings app, and source.

See [installation and settings instructions](macos/README.md) and [verification limits](macos/VERIFICATION.md). The minimum target is macOS 14. The bundles are locally signed, not Apple-notarized. The companion's controls and export implementation are tested; full app launch and the System Settings Options button on macOS 27.0.1 remain unverified.

To rebuild with Apple's Xcode Command Line Tools:

```sh
cd macos/Source
./build.sh
./verify.sh
```

## GitHub Pages

The [Pages workflow](.github/workflows/pages.yml) publishes `index.html` and the downloadable ZIP whenever those files change on `main`. Configure the repository's Pages source as **GitHub Actions**.

For the first publication, run `./scripts/publish-github.sh` from a terminal with working GitHub access and an authenticated `gh` account authorized for `prichards14`. It creates the public repository, pushes the commit, enables Pages, and requests a deployment. If the repository or its Pages site already exists, it reuses them.

Check the deployment in the repository's **Actions** tab. A URL printed by the publishing script is the expected address; a successful deployment must be confirmed before treating it as live.

The [reusable project brief](docs/project-brief.md) documents the browser app requirements.
