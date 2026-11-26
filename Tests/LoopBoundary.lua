-- Run only in a new, empty, unsaved project tab.
local r = reaper
local project, filename = r.EnumProjects(-1)
if filename ~= "" or r.CountTracks(project) ~= 0 or r.CountMediaItems(project) ~= 0
    or r.CountTempoTimeSigMarkers(project) ~= 0 or r.GetPlayStateEx(project) ~= 0 then
  r.ShowMessageBox("Open a new, empty, unsaved project tab before running this test.",
    "DrNine loop boundary test", 0)
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
  r.SetCurrentBPM(project, 120, false)
  if not r.SetMediaTrackInfo_Value(r.GetMasterTrack(project), "D_VOL", 0) then
    fail("Could not mute the test project's master output")
  end
  r.InsertTrackAtIndex(0, false)
  local track = r.GetTrack(project, 0)
  if not track then fail("Could not create the test track") end
  r.GetSetMediaTrackInfo_String(track, "P_NAME", "DrNine loop boundary test", true)
  local drum = r.TrackFX_AddByName(track, "JS: Reaperments\\Instruments\\DrNine.jsfx", false, -1)
  local capture = r.TrackFX_AddByName(track, "JS: Reaperments\\Tests\\PatternSelectionCapture.jsfx", false, -1)
  if drum < 0 or capture ~= drum + 1 then fail("Could not load DrNine and its MIDI capture effect") end
  set_param(track, drum, 96, "Note Map", 0)
  set_param(track, drum, 97, "MIDI Channel", 0)
  set_param(track, drum, 98, "Pattern", 1)
  set_param(track, drum, 99, "Sequencer", 1)
  set_param(track, drum, 100, "Shuffle", 0)
  set_param(track, drum, 101, "Sequencer MIDI Out", 1)
  set_param(track, drum, 113, "Sequencer MIDI Output Channel", 9)
  set_param(track, drum, 114, "Sequencer Loop Off", 2)
  set_param(track, drum, 115, "Sequencer Loop On", 2)
  set_param(track, drum, 116, "Sequencer Loop Boundary", 0)

  local item = r.CreateNewMIDIItemInProj(track, 0, 6, true)
  local take = item and r.GetActiveTake(item)
  if not take then fail("Could not create the MIDI test item") end
  if not r.MIDI_InsertNote(take, false, false, r.MIDI_GetPPQPosFromProjQN(take, 3.875),
      r.MIDI_GetPPQPosFromProjQN(take, 4.75), 0, 77, 100, true) then
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
  local function note_at(beat, pitch, expected)
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
      fail(("note %d at beat %.2f was %s"):format(pitch, beat, found and "present" or "absent"))
    end
  end
  for _, beat in ipairs({4.0, 4.25, 4.5}) do
    note_at(beat, 36, false)
    note_at(beat, 42, true)
  end
  r.ShowConsoleMsg(("PASS: DrNine truncated loop boundary (%d MIDI events)\n"):format(count))
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
  if r.GetPlayPositionEx(project) >= 2.375 then
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
