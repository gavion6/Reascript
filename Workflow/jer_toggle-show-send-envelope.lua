-- @description In ReaImGUI window shows all sends for first selected track. By clicking the sends button, you can toggle view its volume envelope. If the envelope is not active it makes it active.
-- @version 0.2026-02-05
-- @author jeravi
-- @donation https://buymeacoffee.com/vitjerabek
-- @changelog initial release


function get_snds_tr()
  local track = reaper.GetSelectedTrack(0, 0)
  local retval, tr_name = reaper.GetTrackName(track)
  local snds_cnt = reaper.GetTrackNumSends(track, 0)
  local snds = {}
  for i=0, snds_cnt-1 do
    local env = reaper.GetTrackSendInfo_Value(track, 0, i, "P_ENV:<VOLENV")
    local retval, name = reaper.GetTrackSendName(track, i)
    table.insert(snds, {env = env, name = name})
  end
  return snds, snds_cnt, tr_name
end

--GUI

local ctx = reaper.ImGui_CreateContext('toggle show sends')
local sans_serif = reaper.ImGui_CreateFont('sans-serif', 13)
reaper.ImGui_Attach(ctx, sans_serif)

local function loop()
  local snds, snds_cnt, tr_name = get_snds_tr()
  reaper.ImGui_PushFont(ctx, sans_serif, 13)
  local visible, open = reaper.ImGui_Begin(ctx, 'Toggle show sends', true)
  if visible then
    -- TODO: window contents here
    reaper.ImGui_Text(ctx, tr_name)
    for i=1, snds_cnt do
      local info = snds[i]
      if reaper.ImGui_Button(ctx, info.name)==true then
        local retval, env_active = reaper.GetSetEnvelopeInfo_String(info.env, "ACTIVE", "", false)
        local ok, env_visible = reaper.GetSetEnvelopeInfo_String(info.env, "VISIBLE", "", false)
        
        if env_active=="0" then
          reaper.GetSetEnvelopeInfo_String(info.env, "ACTIVE", "1", true)
          reaper.TrackList_AdjustWindows(false)
        end
        
        if env_visible=="0" then
          reaper.GetSetEnvelopeInfo_String(info.env, "VISIBLE", "1", true)
          reaper.TrackList_AdjustWindows(false)
          reaper.ShowConsoleMsg("track was not visible")
        end
        
        if env_visible=="1" then
          reaper.GetSetEnvelopeInfo_String(info.env, "VISIBLE", "0", true)
          reaper.TrackList_AdjustWindows(false)
          reaper.ShowConsoleMsg("track was visible")
        end
        
      end
    end
    reaper.ImGui_End(ctx)
  end
  reaper.ImGui_PopFont(ctx)
  
  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)
