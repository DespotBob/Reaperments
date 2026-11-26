-- Run only in a new, empty, unsaved project tab.
local r = reaper
local project, filename = r.EnumProjects(-1)
if filename ~= "" or r.CountTracks(project) ~= 0 or r.CountMediaItems(project) ~= 0
    or r.CountTempoTimeSigMarkers(project) ~= 0 or r.GetPlayStateEx(project) ~= 0 then
  r.ShowMessageBox("Open a new, empty, unsaved project tab before running this test.",
    "DrNine pattern selection test", 0)
  return
end

local function fail(message)
  error(message, 0)
end

local function add_fx(track, name)
  local fx = r.TrackFX_AddByName(track, name, false, -1)
  if fx < 0 then fail("Could not load " .. name .. ". Rescan JS effects and try again.") end
  return fx
end

local function set_param(track, fx, index, name, value)
  local ok, actual_name = r.TrackFX_GetParamName(track, fx, index)
  if not ok or actual_name ~= name then
    fail(("Parameter %d: expected %s, got %s"):format(index + 1, name, actual_name or "missing"))
  end
  if not r.TrackFX_SetParam(track, fx, index, value) then fail("Could not set " .. name) end
  local actual = r.TrackFX_GetParam(track, fx, index)
  if math.abs(actual - value) > 0.0001 then fail("Unexpected value for " .. name) end
end

local function setup()
  r.SetCurrentBPM(project, 120, false)
  if not r.SetMediaTrackInfo_Value(r.GetMasterTrack(project), "D_VOL", 0) then
    fail("Could not mute the test project's master output")
  end
  r.InsertTrackAtIndex(0, false)
  local track = r.GetTrack(project, 0)
  if not track then fail("Could not create the test track") end
  r.GetSetMediaTrackInfo_String(track, "P_NAME", "DrNine pattern selection test", true)

  local drum = add_fx(track, "JS: Reaperments\\Instruments\\DrNine.jsfx")
  local capture = add_fx(track, "JS: Reaperments\\Tests\\PatternSelectionCapture.jsfx")
  if capture ~= drum + 1 then fail("MIDI capture is not after DrNine") end
  set_param(track, drum, 96, "Note Map", 0)
  set_param(track, drum, 97, "MIDI Channel", 0)
  set_param(track, drum, 98, "Pattern", 0)
  set_param(track, drum, 99, "Sequencer", 1)
  set_param(track, drum, 100, "Shuffle", 0)
  set_param(track, drum, 101, "Sequencer MIDI Out", 1)
  set_param(track, drum, 113, "Sequencer MIDI Output Channel", 9)

  local item = r.CreateNewMIDIItemInProj(track, 0, 22, true)
  local take = item and r.GetActiveTake(item)
  if not take then fail("Could not create the MIDI test item") end
  local function note(pitch, first, last)
    local start_ppq = r.MIDI_GetPPQPosFromProjQN(take, first)
    local end_ppq = r.MIDI_GetPPQPosFromProjQN(take, last)
    if not r.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, pitch, 100, true) then
      fail("Could not insert pattern key " .. pitch)
    end
  end
  note(85, 1.125, 9.125)
  note(86, 2.125, 5.125)
  note(99, 13.125, 17.125)
  r.MIDI_Sort(take)
  r.UpdateArrange()
  r.SetEditCurPos2(project, 0, false, false)
end

local function check_events()
  if r.gmem_read(1) ~= 1 then fail("MIDI capture effect did not initialize") end
  if r.gmem_read(2) ~= 0 then fail("MIDI capture buffer overflowed") end
  local count = math.floor(r.gmem_read(0))
  if count == 0 then fail("MIDI capture received no events") end
  local events = {}
  for i = 0, count - 1 do
    local base = 4 + i * 4
    events[#events + 1] = {
      beat = r.gmem_read(base),
      status = math.floor(r.gmem_read(base + 1)),
      note = math.floor(r.gmem_read(base + 2)),
      velocity = math.floor(r.gmem_read(base + 3)),
    }
  end
  local function matching(beat, status, note, on)
    for _, e in ipairs(events) do
      if math.abs(e.beat - beat) < 0.01 and e.status == status and e.note == note
          and (not on or e.velocity > 0) then return true end
    end
    return false
  end
  local function hat(beat, expected, description)
    local found = matching(beat, 0x99, 42, true)
    if found ~= expected then
      fail(("%s: closed hat at beat %.2f was %s, expected %s"):format(
        description, beat, found and "present" or "absent", expected and "present" or "absent"))
    end
  end
  hat(1.0, true, "pattern 1 baseline")
  hat(3.25, false, "pattern change waits for boundary")
  hat(4.25, false, "highest held key selects pattern 3")
  hat(4.5, true, "pattern 3 is playing")
  hat(7.25, false, "pattern 3 continues until boundary after release")
  hat(8.25, true, "releasing higher key selects held pattern 2")
  hat(11.25, true, "pattern 2 continues until boundary after release")
  hat(12.0, true, "pattern 1 resumes")
  hat(12.25, false, "pattern 1 resumes after last key release")
  hat(15.0, true, "pattern 1 continues before pattern 16")
  for _, e in ipairs(events) do
    if e.status == 0x99 and e.velocity > 0 and e.beat >= 16 and e.beat < 20 then
      fail(("Empty pattern 16 emitted note %d at beat %.3f"):format(e.note, e.beat))
    end
  end
  hat(20.0, true, "pattern 1 resumes after pattern 16")
  for _, event in ipairs({ {1.125, 0x90, 85}, {2.125, 0x90, 86},
      {5.125, 0x80, 86}, {9.125, 0x80, 85}, {13.125, 0x90, 99}, {17.125, 0x80, 99} }) do
    if not matching(event[1], event[2], event[3], false) then
      fail(("Missing passed-through MIDI event %02X %d at beat %.3f"):format(event[2], event[3], event[1]))
    end
  end
  r.ShowConsoleMsg(("PASS: DrNine pattern selection (%d MIDI events)\n"):format(count))
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
  if r.GetPlayPositionEx(project) >= 10.375 then
    r.OnStopButtonEx(project)
    local passed, result = pcall(check_events)
    if not passed then r.ShowConsoleMsg("FAIL: " .. result .. "\n") end
  elseif r.GetPlayStateEx(project) & 1 == 0 then
    r.ShowConsoleMsg("FAIL: Test playback stopped before completion\n")
  elseif r.time_precise() - start > 30 then
    r.OnStopButtonEx(project)
    r.ShowConsoleMsg("FAIL: Test playback timed out\n")
  else
    r.defer(poll)
  end
end
r.defer(poll)
