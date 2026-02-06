-- @description Group Items Blocks
-- @about Groups selected items in blocks in child tracks by creating an empty item in the parent track. Makes use of X-Rayms free scripts.
-- @version 0.2025-02-06
-- @author jeravi
-- @donation https://buymeacoffee.com/vitjerabek
-- @changelog initial release 

function main()
  
  
  --check if more than one item is selected
  local sel_items_count = reaper.CountSelectedMediaItems(0)
  
  if sel_items_count<=1 then
    reaper.ShowMessageBox("No items to group. Exciting.", "Info", 0)
    return
  end
  
  --array of selected items
  
  sel_items = {}
  
  for i=0, sel_items_count-1  do
    local item = reaper.GetSelectedMediaItem(0, i)
    table.insert(sel_items, item)
  end
  
  --reaper.ShowConsoleMsg(tostring(sel_items[1]))
  
  --check if parent exists
  local parent =  reaper.GetParentTrack(reaper.GetMediaItemTrack(sel_items[1]))
  
  if not parent then
    reaper.ShowMessageBox("No parent track. Exciting.", "Info", 0)
    return
  end
  
  -- Get info
  local MaxGroupID = 0
  for i = 0, reaper.CountMediaItems(0) - 1 do
    local item = reaper.GetMediaItem(0, i)
    local item_group_id = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    if item_group_id > MaxGroupID then
      MaxGroupID = item_group_id
    end
  end
  
  --get name of parent track
  
  local retval, parent_name = reaper.GetTrackName(parent)      --get name of parent track
  
  reaper.SetTrackSelected(parent, 1) --selects parent track
  
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_RSe486db04f7692f71984dbb434393a04c62b3a089'), 0) --creates empty text items for all sel items notes in parent track
  
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_RSb6d9483d881ecd9b64f8519a12974334ca99c2d3'), 0) --merge empty text items, user input for consecutive or not
  
  local blockCount = reaper.GetTrackNumMediaItems(parent) --how many blocks are there
  
  reaper.Main_OnCommand(40421, 0) --selects all items in the parent track
  
  for i=0, blockCount-1 do
    
    local name_end=""
    
    if blockCount>1 then
      name_end="-G"..tostring(i+1)
    end
    
    local block_name=parent_name..name_end --creates name for every block from parent
    local main_item=reaper.GetSelectedMediaItem(0, i) --gets current media item
    local main_item_note=reaper.GetSetMediaItemInfo_String(main_item, "P_NOTES", block_name, true) --creates note with new name of item
    local main_item_start = reaper.GetMediaItemInfo_Value(main_item, "D_POSITION") --get item start
    local main_item_length = reaper.GetMediaItemInfo_Value(main_item, "D_LENGTH") --get item length
    local main_item_end=main_item_start+main_item_length --getblock item end
    
    MaxGroupID = MaxGroupID + 1
    reaper.SetMediaItemInfo_Value(main_item, "I_GROUPID", MaxGroupID)
    
    for i=1, sel_items_count do
      local item = sel_items[i]
      local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      if item_start >= main_item_start and item_end <= main_item_end then
        reaper.SetMediaItemInfo_Value(item, "I_GROUPID", MaxGroupID)
      end
    end
  end
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Items ungrouped", 0)
