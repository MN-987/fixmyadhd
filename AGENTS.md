# AGENTS.md

Instructions for coding agents working in this repo.

## What this is

FixMyADHD is a small macOS sticky-note app. It is a Swift package, not an Xcode project. The window is an `NSPanel` that floats above other apps.

## Layout

- `Package.swift` — macOS 14 executable
- `Sources/FixMyADHD/main.swift` — app start, floating panel, collapse and expand
- `Sources/FixMyADHD/TaskStore.swift` — tasks, Later, Done, save and load
- `Sources/FixMyADHD/StickyNoteView.swift` — yellow card UI
- `Info.plist` — app bundle metadata
- `run.sh` — build, sign, and open `FixMyADHD.app`

## Build

```bash
./run.sh
```

Do not add an Xcode project unless the user asks. Full Xcode is not required.

## Data

Tasks, the Later list, finished tasks, the card position, and whether it is collapsed are stored in:

`~/Library/Application Support/FixMyADHD/tasks.json`

Never commit that file. Never print its contents. It is the user's private list. `.gitignore` already ignores `tasks.json`.

## Behavior to keep

- Check plays `/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/finder/move to trash.aif`, then moves the task into Done.
- The clock button next to plus adds the typed line to Later, not to the active list.
- Done is a list of finished tasks, not only a number.
- Minus collapses to a thin strip on the nearer screen edge (right half to the right edge, left half to the left edge). Clicking the strip restores the card.
- The panel stays visible when another app is active.

## Do not commit

- `.build/`
- `FixMyADHD.app`
- `tasks.json`
- `.DS_Store`
