# Window Edges

Build tooling requires Node.js 22.22.2 or newer.

TypeScript stays on 6.0, the latest series supported by Raycast's ESLint config.
A scoped npm override upgrades tooling dependencies on minimatch 10 to patched
minimatch 11 (GHSA-g3hv-75wg-m249); remove it when upstream dependencies migrate.

Four Tinycast commands move the focused window to the left, right, top, or bottom
edge of its current display, without resizing or changing the other axis. Edges
use the display's visible frame, so the Dock and menu bar stay accessible. For
windows spanning displays, the display with the largest overlap wins; offscreen
windows use the nearest display. Oversized windows retain their size.

On Apple Silicon macOS, with Node.js and Xcode Command Line Tools installed:

```sh
task dot:tinycast:window-edges
```

In Tinycast Settings > Extensions, enable extensions and add the printed `build`
folder. Search for “Move Window to Left Edge”, “Move Window to Right Edge”,
“Move Window to Top Edge”, or “Move Window to Bottom Edge”. Assign hotkeys in
Tinycast to use them directly. Rebuild and reimport after updating the extension.

Allow Tinycast in System Settings > Privacy & Security > Accessibility. If macOS
requests a separate grant for the bundled helper, allow that helper as well.
Fullscreen windows must leave fullscreen first. Applications that refuse window
movement report an error in the HUD. These commands run independently of
Tinycast's builtin placement history, gap preference, and Restore command.

The extension uses Tinycast's captured frontmost application and a bundled Swift
Accessibility helper. It writes only `AXPosition`, never `AXSize`. Successful
commands run silently, matching the builtin movements.

```sh
npm ci
npm run lint
npm test
npm run build
```

Geometry tests cover each edge, negative display coordinates, spanning and
offscreen windows, and oversized windows. They never access or move real windows.
For a manual check, run each command with a normal window and a fixed-size window,
then repeat on a secondary display positioned above or to the left of the primary.
Confirm the size and other axis stay unchanged, and hotkeys and palette invocation
both target the original application. Check denied Accessibility permission,
fullscreen, and an application with no focused window for actionable HUD errors.
