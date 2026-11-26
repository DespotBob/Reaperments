# DrNine Drum Synthesizer

DrNine is a REAPER JSFX drum instrument. Its on-screen piano keyboard displays
incoming MIDI notes and can also be played with the mouse. Click and hold a key,
or drag across keys, to play notes at velocity 100. Releasing the mouse button
or dragging off the keyboard releases the current note. Mouse notes are sent
on the selected MIDI channel (channel 1 in Omni mode).

## Keyboard colors

The keyboard displays MIDI notes 35-99. Keys mapped to a drum are tinted by
voice, and the tint darkens while the note is held. Short drum and pattern
notes remain darkened briefly after note-on so quick notes are visible. Loop
keys return to their normal color when released. Unmapped keys use the neutral
piano colors. Black keys use darker versions of the same colors.

| Drum voice | Key color | General MIDI notes | Chromatic from C1 |
| --- | --- | --- | --- |
| Bass drum | Red | 35, 36 | 36 |
| Snare drum | Orange | 38, 40 | 37 |
| Low tom | Gold | 41, 45 | 38 |
| Mid tom | Yellow-green | 47, 48 | 39 |
| High tom | Green | 43, 50 | 40 |
| Rim shot | Teal | 37 | 41 |
| Hand clap | Violet | 39 | 42 |
| Open hi-hat | Pink | 46 | 44 |
| Closed hi-hat | Purple | 42 | 43 |
| Ride | Blue | 51 | 46 |
| Crash | Coral | 49 | 45 |

Change the **Note Map** control to switch between the two drum layouts. The
note numbers above are authoritative; octave labels can differ between DAWs.

## Sequencer pattern keys

MIDI notes 84-99 select patterns 1-16, respectively. These keys are all tinted
light blue to distinguish them from drum keys. Holding a pattern key selects
that pattern. When REAPER's transport is stopped, holding a pattern key also
starts a looping audition of that pattern; releasing all pattern keys stops
the audition. This works even if the **Sequencer** control is off. While the
transport is running, pattern keys only select the pattern, and the
**Sequencer** control determines whether it plays. A changed pattern takes
effect at the next pattern boundary. When all pattern keys are released,
selection returns to the pattern chosen by the **Pattern** control. Pattern
keys do not trigger drum voices.

On the **Behaviour** page, enable **FOLLOW KEYS** in the Sequencer section to show
the currently playing pattern on the Pattern page.

## Sequencer loop keys

The light-red white keys loop the current pattern:

| Key | MIDI note | Loop length |
| --- | --- | --- |
| C | 72 | 1 step |
| D | 74 | 2 steps |
| E | 76 | 1 Loop Boundary of steps |
| F | 77 | 2 Loop Boundaries of steps |
| G | 79 | 3 Loop Boundaries of steps |

These are sequencer **steps**, not quarter-note beats; their duration depends on
the pattern's **Scale** setting. Hold a key on a MIDI controller or with the
mouse to apply its loop. The active loop key is marked. If several loop keys
are held, the highest note takes priority. In Start of Sequence and Current
Beat modes, if the selected loop exceeds the pattern length, the pattern
repeats within the loop. These controls also work during pattern preview.
When the sequencer is off, or the transport is stopped, holding a loop key
plays the pattern by hand; releasing the key stops it.

Active Range Markes: This Column-colored markers above the accent row show the steps in the current playbackrange. They follow the active loop, including loops that wrap around the end of a pattern, and otherwise show the pattern's full length.

The **LOOP ON** selector controls where a held loop begins. **Start of
Sequence** (the default) loops from the start. **Current Beat** starts at the
next sequencer step. **Current Bar** groups pattern columns using the
**LOOP BOUNDARY** control on the Behaviour page (3-7 steps, default 4) and
starts the loop at the beginning of the group containing the current step.
For example, with a boundary of 4, columns 13-16 start at column 13. The
final group is shortened if it reaches the end of the pattern. A loop key
longer than its group plays its full length from the group start, up to the
end of the pattern. The boundary also sets the column shading colours. The
boundary counts sequencer
steps regardless of Scale or project time signature. Playback enters the loop
after its end; if already past the end, it enters at the next sequencer step.
Releasing the key before a pending loop starts cancels it. Boundary changes
apply the next time a loop is started.

The **LOOP OFF** selector in the Behaviour page's Sequencer section determines
what happens when all loop keys are released:

- **Continue** finishes the current loop, then continues with the next step.
- **Hard Restart** restarts at step 1 on the next step boundary.
- **Rejoin** (the default) resumes the uninterrupted sequence position at the
  next step boundary.

## MIDI input

The **MIDI Channel** control filters drum notes, pattern selection, and loop keys.
**Omni** accepts notes on all channels. In REAPER, route MIDI to the track
containing DrNine and enable record monitoring to play it live.

## Sequencer MIDI output

Turn on **MIDI OUT** in the Behaviour page's Sequencer section to send drum hits
as MIDI note-on and note-off events, using the selected note map. **OUTPUT CH**
selects the sequencer's MIDI output channel (1-16; default 10). Incoming MIDI
passes through unchanged whether MIDI OUT is on or off. To record the sequencer
output in REAPER, arm the track and select **Record: output (MIDI)**.

For the REAPER pattern-selection integration test, see
[Tests/README.md](../Tests/README.md).
