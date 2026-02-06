-- @description Insert Silence Between Selected Item Groups (DEMO)
-- @about If you select two or more item groups, you can automate how long silence is in between them. Intended to work with the script "Create regions from item blocks in parent track"
-- @version 0.2026-02-06
-- @author jeravi
-- @donation https://buymeacoffee.com/vitjerabek
-- @changelog Demo version. Sometimes works unexpectadely. But you can always undo.


-- Function to create the GUI
function createGUI()
    local retval, user_input = reaper.GetUserInputs("Insert Silence", 1, "Silence Length (seconds):", "0.5")
    if retval then
        return tonumber(user_input)
    end
    return nil
end


---manage 

sel_items_cnt = reaper.CountSelectedMediaItems(0)
if sel_items_cnt <= 1 then return end

 
function get_items_data(sel_items_cnt)
  local items_tbl = {}
  for i = 0, sel_items_cnt-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local grp_id = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    if grp_id == 0 then 
      break
    end
    local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    table.insert(items_tbl, {item, grp_id, item_start, item_end})             ------ 1: item, 2: grp_id, 3: item_start, 4: item_end
  end
  return items_tbl
end

function get_item_groups()
  
  local uniqueGroupIDs = {}
  local seen = {}
  
  for i=0, sel_items_cnt-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local id = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    
    if not seen[id] then
      seen[id] = true
      table.insert(uniqueGroupIDs, id)
    end
  end
  return uniqueGroupIDs
end

function get_grp_starts_ends()
  local grp_IDs = get_item_groups()
  local items_tbl = get_items_data(sel_items_cnt)
  local grps_start_end = {}
  
  for i, id in pairs(grp_IDs) do
    local min_start = reaper.GetProjectLength(0)
    local max_end = 0
    if items_tbl[i][2]==id then
      local item_start = items_tbl[i][3]
      
      if item_start<min_start then
        min_start = item_start
      end
      
      local item_end = items_tbl[i][4]
      
      if item_end>max_end then
        max_end  = item_end
      end
      
    end
    table.insert(grps_start_end, {id, min_start, max_end}) -- 1: grp id, 2: min_start, 3: max_end)
  end
  return grps_start_end, items_tbl
end

function main(slc_length)

  --create table with new starts and ends
  
  local new_grps_starts = {}
  local grps_start_end, items_tbl = get_grp_starts_ends()
  
  if #grps_start_end == 1 or #grps_start_end == 0 then
    reaper.ShowMessageBox("No selected group.", "Info", 0)
    return
  end
  
  table.insert(new_grps_starts, grps_start_end[1]) --first group stays at place, insert their start, propably not needed for now
  
  local last_end = grps_start_end[1][3]
  
  for i=2, #grps_start_end do
    local grp_id = grps_start_end[i][1]
    local new_start = last_end + slc_length
    
    last_end = new_start + (grps_start_end[i][3] - grps_start_end[i][2]) --update the last group position
    
    table.insert(new_grps_starts, {grp_id, new_start})
  end
    
  -- calculate new start for each item - o kolik se posunula grupa o tolik se posune kazdy item v grupe
  
  for i=2, #grps_start_end do
    local id = grps_start_end[i][1]
    local position_change = new_grps_starts[i][2] - grps_start_end[i][2]
    
    if not id == new_grps_starts[i][1] then
      reaper.ShowConsoleMsg("old and new groups starts dont match by id")
      return
    end
    
    for j, item in pairs(items_tbl) do
      local media_item = item[1]
      local item_grp_id = item[2]
      local item_old_start = item[3]
      
      if id == item_grp_id then
        -- calculate new start
        local new_item_start = item_old_start + position_change
        reaper.SetMediaItemInfo_Value(media_item, "D_POSITION", new_item_start)
        reaper.UpdateArrange()
      end
    end
  end
end
      
  
  


--- do the thing

local slc_length = createGUI()
if slc_length then
  reaper.Undo_BeginBlock()
  main(slc_length)
  reaper.Undo_EndBlock("Insert Silence Between Selected Item Groups", 0)
else
  reaper.ShowMessageBox("No value specified.", "Info", 0)
end