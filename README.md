# FixMyADHD

A yellow sticky note that stays on your Mac screen.

Type a task. Check it off. Park a distraction for later. Collapse the card to a thin line when you need it out of the way.

## What it does

- Floats above other windows, on every desktop.
- Drag the top bar to move it.
- **Plus** adds a task. **Clock** parks what you just typed in Later.
- **Check** plays the Mac trash sound, removes the task, and adds 1 to Done.
- **Later** on a row parks that task. **To tasks** brings it back.
- **Done** opens the list of tasks you finished.
- **Minus** collapses the card to the nearest screen edge. Click the yellow line to open it again.

## Run it

macOS 14 or newer. Swift is enough. The full Xcode app is not required.

```bash
./run.sh
```

That builds `FixMyADHD.app` and opens it.

## Where tasks are saved

On this Mac only, in:

`~/Library/Application Support/FixMyADHD/tasks.json`

That file is personal. It is not part of this repo.

## License

MIT. See [LICENSE](LICENSE).
