# DrNine integration tests

## Pattern selection

Run this test in REAPER with the repository installed under
`REAPER\Effects\Reaperments`. It loads the real DrNine JSFX and a downstream
MIDI capture effect. The test uses DrNine's factory patterns.

1. Open a new, empty, unsaved project tab and disable the metronome.
2. In the Actions list, run **ReaScript: Run ReaScript (EEL2, Lua, or
   python)...**, and select `Tests\PatternSelection.lua`.
3. Keep the test tab active until the ReaScript console reports `PASS` or
   `FAIL`. Playback takes about 11 seconds.

The script refuses to run in a saved or non-empty project. It sets the test
project's tempo, mutes its master output, and leaves its track and MIDI item
in the unsaved tab for inspection. The capture effect also silences its audio.
Use another new, empty tab for each run. Restore the metronome afterward if
needed. If an effect cannot be loaded, rescan JS effects in REAPER and retry.

The MIDI item presses overlapping blue pattern keys while the transport plays.
The assertions check that selection waits for a pattern boundary, the highest
held key takes priority, releasing keys returns to the remaining held key or
the selected pattern, pattern 16 is empty, and the incoming keys pass through.
The checks observe actual MIDI emitted by DrNine rather than a sequencer model.

## Loop-on bar timing

Run `Tests\LoopOnBar.lua` in a new, empty, unsaved project tab using the same
procedure. It takes about 3 seconds. In 3/4 time, the test checks cancellation,
entry after the loop end, immediate entry when already past it, alignment to
the current four-step boundary, and limiting a longer loop key to that boundary.

## Truncated loop boundary

Run `Tests\LoopBoundary.lua` in a new, empty, unsaved project tab using the
same procedure. It selects a three-step boundary and checks that an eight-step
key loops only the final column of a 16-step pattern.

## Loop-on current-beat timing

Run `Tests\LoopOnCurrentBeat.lua` in a new, empty, unsaved project tab using the
same procedure. It presses a one-step loop key after the straight grid boundary
but before the shuffled step. The test checks that the loop begins at that step
and repeats the current pattern position instead of restarting at step 1.
