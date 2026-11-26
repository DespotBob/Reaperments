---
name: reaper-integration-tests
description: Run the DrNine REAPER integration tests efficiently and safely, and report their actual results.
---

# REAPER integration tests

Use the real REAPER instance and the test scripts in `Tests\`; do not substitute
a sequencer model or static checks for these tests. Read `Tests\README.md` for
the current tests and prerequisites. Run only the tests relevant to the change
unless the user requests the full suite.

## Efficient workflow

1. Discover the existing REAPER window. Preserve existing project tabs and
   unsaved work. Create a new project tab with `Ctrl+Alt+N` and verify it is
   empty and unsaved. Disable its metronome if enabled.
2. Press `?` to open the Actions list. Filter for
   `ReaScript: Run ReaScript` and run **ReaScript: Run ReaScript (EEL2, Lua,
   or python)...**. The file picker can open scripts directly from `Tests\`.
3. Select the relevant Lua script and keep its project tab active. Read the
   ReaScript console's `PASS` or `FAIL` message. Pattern selection takes about
   11 seconds; the loop-on bar test takes about 3 seconds. Allow for playback
   before checking instead of repeatedly polling.
4. Run each additional test in a separate new, empty, unsaved project tab.
   The tests use a shared MIDI capture buffer, so run them sequentially.
   They leave test tracks and items in their tabs for inspection.
5. Report each actual result, including failures. Do not close or discard
   unsaved projects without the required approval. Restore any metronome
   setting changed outside the disposable test tabs.

For computer-use automation, bind each newly opened Actions, file picker, and
console window from the current window inventory; use observed accessibility
elements instead of cached indices. The Actions list can be slow to populate:
filter it before inspecting its rows, and reuse the file picker's remembered
`Tests` directory. If effects fail to load, follow the rescan guidance in
`Tests\README.md`.
