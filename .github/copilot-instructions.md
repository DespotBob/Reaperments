# Copilot instructions

This repository holds custom scripts and plugins for the **REAPER** DAW, written mainly as **JSFX** (REAPER's built-in effect/instrument language). Everything is GPLv3+ unless a file header says otherwise.

## Repository layout

- [Instruments/](../Instruments) — JSFX virtual instruments (MIDI in, audio out). One `.jsfx` file per instrument; bundled assets (samples, includes) are named after the instrument.
- [Sequencers/](../Sequencers) — JSFX MIDI sequencers/generators (MIDI in/out). Same one-file-per-plugin convention.
- Current content: [Instruments/DrNine.jsfx](../Instruments/DrNine.jsfx), a TR-909 style drum synth (port of 9W9 by athousanddetails).

Put new plugins in the folder matching their role, not in the repo root.

## Build, test, lint

There is no build, lint, test or packaging tooling. The author's local REAPER loads the `.jsfx` files directly from this repo, so edits take effect when the plugin is reloaded on a track (JSFX recompiles on load). Compile errors appear in the plugin window. Assets listed under `requires:` must exist under REAPER's `Data/` folder.

## JSFX conventions

- **Header**: `Version:`, `desc:`, `tags:`, `author:`, `changelog:`, `about:`, `requires:`. Bump `Version:` and add a `changelog:` entry for user-visible changes.
- **Sections**: `@init`, `@slider`, `@block`, `@sample`, `@serialize`, `@gfx`. Functions must be defined before use; use `===`/`!==` for exact comparisons; there is no `return` (last expression is the value); declare `local()`/`instance()`/`global()` deliberately.
- **Sliders** are referenced by number everywhere. Adding or reordering one means updating its declaration and every place that indexes it (parameter mapping, UI, automation, enum/name tables). Use a `-` name prefix for sliders hidden from the default list and a consistent `Group Param` naming scheme.
- **Memory**: one flat global array. Use a bump allocator and index per-object state arrays consistently.
- **Sample rate**: derive constants from `srate` (not 44.1 kHz literals) and reallocate buffers on rate change.
- **MIDI**: pass unrelated events through with `midisend`; avoid stuck notes when mode/transport changes; honour sample offsets in `@block`.
- **State**: persist with `@serialize`; with `ext_noinit = 1`, `@init` is not re-run on transport start, so don't rely on it for resets.
- **UI**: custom `@gfx` UIs scale from a fixed design size, support retina (`gfx_ext_retina`), and route edits through `slider_automate` so they are automatable.
- **Preprocessor**: `<? ... ?>` blocks run at compile time (e.g. emitting `out_pin:` lines or per-slider code); keep them valid for every config option.

## DrNine specifics ([DrNine.jsfx](../Instruments/DrNine.jsfx))

- `@init` holds all DSP as functions over flat memory blocks (`alloc(n)`); voices are raw arrays with numeric indices (e.g. `bd[0]` tune, `bd[7]` level, `bd[8]` distortion type). Reverb/delay buffers use a second arena at `__memtop()/2`, reallocated by `rate_change()`.
- `apply_params()` maps every slider (mostly 0–127) to engine fields; smoothed params use `sm_set(k, addr, value)` with a unique `k`, and `sm_tick` loops over a fixed count (62) that must stay in sync.
- Voice index 0..10 = BD, SD, LT, MT, HT, RS, HC, OH, CH, RD, CY (OH/CH are swapped in `col_trig`; open/closed hats choke each other in `hit_voice`).
- MIDI: `note_voice` handles the GM and "Chromatic from C1" maps; `@block` queues hits in `evq` with sample offsets and `@sample` fires them. The built-in pattern sequencer (`seq_*`, `seqm`) is saved in `@serialize`.
- Adding a slider also requires `is_enum()`, `sl_name()` and the `automate()` bound (113). Per-voice distortion enum is `{Diode,Clip,SAT,BFZ,PDIST,Fold,Crush}`; the master adds `Off` first, shifting indices by one.
- In 11-output mode pan, master distortion and compressor are bypassed; hi-hats share an output and output 11 is the FX return.
- Samples `DrNine/DrNine{HiHat,Ride,Crash}.flac` must be in REAPER's `Data/` (or `Data/Dependencies/`).
