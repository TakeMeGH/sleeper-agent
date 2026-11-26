---
name: itch-deploy
description: "Builds the Godot Web export and uploads it to itch.io (takemegh/clashroom) with butler. Use when asked to build and upload, deploy, push or publish the game to itch."
argument-hint: "[--no-build] [--yes]"
user-invocable: true
allowed-tools: Read, Write, Bash, AskUserQuestion
---

# Itch Deploy

Exports the `Web` preset headlessly and pushes `build/web` to
**https://takemegh.itch.io/clashroom** on the `html5` channel.

## Constants

| Name | Value |
|---|---|
| Godot (console) | `E:/GodotEngine/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe` |
| Export preset | `Web` (from `export_presets.cfg`) |
| Output dir | `build/web` (gitignored) |
| butler | `D:/Download/butler-windows-amd64/butler.exe`, else `butler` on PATH |
| Target | `takemegh/clashroom:html5` |

If the Godot path is missing, read `engine.path` in `project.yaml` and use the
`_console.exe` beside it. If neither butler location works, stop and tell the
person to install butler from https://itchio.itch.io/butler. **Never download
butler yourself.**

## Arguments

- `--no-build` — skip step 2 and upload the existing `build/web`.
- `--yes` — skip the confirmation in step 4.

## Steps

### 1. Preflight

```bash
BUTLER="/d/Download/butler-windows-amd64/butler.exe"; [ -x "$BUTLER" ] || BUTLER="$(command -v butler)"
"$BUTLER" version
timeout 30 "$BUTLER" status takemegh/clashroom
```

If `status` prints the ASCII-art login banner or times out, butler is not
logged in. Stop and ask the person to run this themselves (never handle their
credentials):

```powershell
& "D:\Download\butler-windows-amd64\butler.exe" login
```

"No channel found" is fine. It just means nothing has been uploaded yet.

### 2. Build (skip with `--no-build`)

```bash
mkdir -p build/web && touch build/.gdignore
"E:/GodotEngine/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" \
  --headless --path . --export-release "Web" build/web/index.html > build/export.log 2>&1
echo exit=$?; grep -n ERROR build/export.log | head; ls -la build/web
```

Do not `rm -rf build/web`: the permission rules deny it. The export
overwrites every output file, so leftovers are only stale `.import` files,
which the push ignores. Confirm freshness from the timestamps instead.

`build/.gdignore` stops the editor importing the exported PNGs (otherwise
`.import` files end up in the build). The export takes about 15 seconds. Run it
with a 600000 ms timeout.

### 3. Verify the build

Each of these must exist and be non-empty: `build/web/index.html`,
`index.js`, `index.wasm`, `index.pck`. If any is missing, or the export log
has `ERROR`, stop and show the log. Do not upload a broken build.

Report the file sizes (`ls -la build/web`).

### 4. Confirm

Version label: `$(date +%Y.%m.%d)-$(git rev-parse --short HEAD)`, with
`-dirty` appended if `git status --porcelain` is non-empty.

Unless `--yes` was passed, ask: *"Upload build/web to takemegh/clashroom:html5
as version <label>? This replaces the live build on the itch page."* Wait for a
clear yes. Uploading publishes to a public page.

### 5. Push

```bash
"$BUTLER" push build/web takemegh/clashroom:html5 --userversion "<label>" --ignore "*.import"
"$BUTLER" status takemegh/clashroom
```

Show the person the status output. Right after a first push, status can still
say "No channel found" while itch processes the build. Trust the push's
`√ Added ... fresh data` / `Build is now processing` lines and say status was
not yet confirmed, rather than reporting a failure or a success.

### 6. Report

- Build line, stated explicitly either way: `Build: fresh export` or
  `Build: SKIPPED (--no-build) — uploaded existing build/web, index.pck last
  modified <mtime>`. A skipped build must never read like a fresh one.
- If the push failed or was declined, say `Upload: NOT DONE — <reason>`, not a
  bare status dump.
- Version pushed, and the page: https://takemegh.itch.io/clashroom
- **First upload only** (status showed no channel before the push): tell the
  person to open the project's Edit page on itch once, set *Kind of project*
  to **HTML**, tick **"This file will be played in the browser"** on the
  html5 upload, set the viewport to 1280x720 (or the game's size), and save.
  Threads are off in the export, so SharedArrayBuffer support is not needed.
- itch takes a minute or two to process the build before it is playable.
