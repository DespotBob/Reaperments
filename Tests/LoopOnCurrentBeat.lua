-- Run only in a new, empty, unsaved project tab.
local r = reaper
local project, filename = r.EnumProjects(-1)
if filename ~= "" or r.CountTracks(project) ~= 0 or r.CountMediaItems(project) ~= 0
    or r.CountTempoTimeSigMarkers(project) ~= 0 or r.GetPlayStateEx(project) ~= 0 then
  r.ShowMessageBox("Open a new, empty, unsaved project tab before running this test.",
    "DrNine current-beat loop test", 0)
  return
end

local function fail(message)
  error(message, 0)
end

local function set_param(track, fx, index, name, value)
  local ok, actual_name = r.TrackFX_GetParamName(track, fx, index)
  if not ok or actual_name ~= name then
    fail(("Parameter %d: expected %s, got %s"):format(index + 1, name, actual_name or "missing"))
  end
  if not r.TrackFX_SetParam(track, fx, index, value) then fail("Could not set " .. name) end
  if math.abs(r.TrackFX_GetParam(track, fx, index) - value) > 0.0001 then
    fail("Unexpected value for " .. name)
  end
end

local function setup()
  if not r.SetTempoTimeSigMarker(project, -1, 0, -1, -1, 120, 4, 4, false) then
    fail("Could not set the test tempo")
  end
  if not r.SetMediaTrackInfo_Value(r.GetMasterTrack(project), "D_VOL", 0) then
    fail("Could not mute the test project's master output")
  end
  r.InsertTrackAtIndex(0, false)
  local track = r.GetTrack(project, 0)
  if not track then fail("Could not create the test track") end
  r.GetSetMediaTrackInfo_String(track, "P_NAME", "DrNine current-beat loop test", true)
  local drum = r.TrackFX_AddByName(track, "JS: Reaperments\\Instruments\\DrNine.jsfx", false, -1)
  local capture = r.TrackFX_AddByName(track, "JS: Reaperments\\Tests\\PatternSelectionCapture.jsfx", false, -1)
  if drum < 0 or capture ~= drum + 1 then fail("Could not load DrNine and its MIDI capture effect") end
  set_param(track, drum, 96, "Note Map", 0)
  set_param(track, drum, 97, "MIDI Channel", 0)
  set_param(track, drum, 98, "Pattern", 1)
  set_param(track, drum, 99, "Sequencer", 1)
  set_param(track, drum, 100, "Shuffle", 6)
  set_param(track, drum, 101, "Sequencer MIDI Out", 1)
  set_param(track, drum, 113, "Sequencer MIDI Output Channel", 9)
  set_param(track, drum, 114, "Sequencer Loop Off", 1)
  set_param(track, drum, 115, "Sequencer Loop On", 1)

  local item = r.CreateNewMIDIItemInProj(track, 0, 4, true)
  local take = item and r.GetActiveTake(item)
  if not take then fail("Could not create the MIDI test item") end
  if not r.MIDI_InsertNote(take, false, false, r.MIDI_GetPPQPosFromProjQN(take, 1.8125),
      r.MIDI_GetPPQPosFromProjQN(take, 2.75), 0, 72, 100, true) then
    fail("Could not insert a loop key")
  end
  r.MIDI_Sort(take)
  r.UpdateArrange()
  r.SetEditCurPos2(project, 0, false, false)
end

local function check_events()
  if r.gmem_read(1) ~= 1 then fail("MIDI capture effect did not initialize") end
  if r.gmem_read(2) ~= 0 then fail("MIDI capture buffer overflowed") end
  local count = math.floor(r.gmem_read(0))
  if count == 0 then fail("MIDI capture received no events") end
  local function note_at(beat, pitch, expected, description)
    local found = false
    for i = 0, count - 1 do
      local base = 4 + i * 4
      if math.abs(r.gmem_read(base) - beat) < 0.01 and r.gmem_read(base + 1) == 0x99
          and r.gmem_read(base + 2) == pitch and r.gmem_read(base + 3) > 0 then
        found = true
        break
      end
    end
    if found ~= expected then
      fail(("%s: note %d at beat %.3f was %s"):format(
        description, pitch, beat, found and "present" or "absent"))
    end
  end
  note_at(1.875, 42, true, "loop starts on the pending shuffled step")
  note_at(2.0, 42, false, "loop does not skip to the next straight step")
  note_at(2.125, 36, false, "loop does not restart at step 1")
  note_at(2.125, 42, true, "loop repeats the current shuffled step")
  note_at(2.375, 36, false, "loop keeps the current pattern position")
  note_at(2.375, 42, true, "loop continues repeating the shuffled step")
  r.ShowConsoleMsg(("PASS: DrNine current-beat loop (%d MIDI events)\n"):format(count))
end

r.gmem_attach("DrNinePatternSelectionTest")
for i = 0, 2 do r.gmem_write(i, 0) end
local ok, message = pcall(setup)
if not ok then
  r.ShowConsoleMsg("FAIL: " .. message .. "\n")
  return
end

local start = r.time_precise()
r.OnPlayButtonEx(project)
local function poll()
  if r.GetPlayPositionEx(project) >= 1.375 then
    r.OnStopButtonEx(project)
    local passed, result = pcall(check_events)
    if not passed then r.ShowConsoleMsg("FAIL: " .. result .. "\n") end
  elseif r.GetPlayStateEx(project) & 1 == 0 then
    r.ShowConsoleMsg("FAIL: Test playback stopped before completion\n")
  elseif r.time_precise() - start > 20 then
    r.OnStopButtonEx(project)
    r.ShowConsoleMsg("FAIL: Test playback timed out\n")
  else
    r.defer(poll)
  end
end
r.defer(poll)
