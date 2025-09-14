--dependencies: x-raym

function createGUI() --ask for tail first
  local retval, user_input=reaper.GetUserInputs("Regions from selected item blocks, set render matrix to parent", 1, "Region tail (seconds):", "0")
  if retval then
      return tonumber(user_input)
  end
end

function main(tail) --main function

  reaper.Undo_BeginBlock()
  
  local selected_items=reaper.CountSelectedMediaItems(0)
  
  if selected_items==0 then
    reaper.ShowMessageBox("no items selected", "info", 0)
    return
  end
  
  local selected_track = reaper.GetSelectedTrack(0, 0)
  local selected_track_is_folder = reaper.GetMediaTrackInfo_Value(selected_track, "I_FOLDERDEPTH")
 
  if selected_track_is_folder==1 then parent_track = selected_track  --check if selected track is the parent or the child
    else parent_track = reaper.GetParentTrack(selected_track)        --if child then look for parent
  end

  local retval, parent_name = reaper.GetTrackName(parent_track)      --get name of parent track
  
  reaper.SetTrackSelected(parent_track, 1) --selects parent track
  
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_RSe486db04f7692f71984dbb434393a04c62b3a089'), 0) --creates empty text items for all sel items notes in parent track
  
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_RSb6d9483d881ecd9b64f8519a12974334ca99c2d3'), 0) --merge empty text items, user input for consecutive or not
  
  local blockCount = reaper.GetTrackNumMediaItems(parent_track) --how many blocks are there
  
  reaper.Main_OnCommand(40421, 0) --selects all items in the parent track
  
  --name every text item by parent, add version number, create a region with that name and set in region render matrix to parent
  
  --local region_names={}
  
  for i=0, blockCount-1 do
    
    local name_end=""
    
    if blockCount>1 then
      name_end="-v"..tostring(i+1)
    end
    
    local block_name=parent_name..name_end --creates name for every block from parent
    local item=reaper.GetSelectedMediaItem(0, i) --gets current media item
    local item_note=reaper.GetSetMediaItemInfo_String(item, "P_NOTES", block_name, true) --creates note with new name of item
    local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION") --get item start
    local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") --get item length
    --local item_end = item_start+item_length --get item end
    local region_end=item_start+item_length+tail --get region end(block item length plus tail)
    --local region_color=blue
    local createRegion=reaper.AddProjectMarker2(0, true, item_start, region_end, block_name, 1, reaper.ColorToNative(30, 222, 255)|0x1000000) --create region with block name
    reaper.SetRegionRenderMatrix(0, createRegion, parent_track, 1) --set parent in matrix
    --table.insert(region_names, block_name)
  end
  
  --local regions_names_string = table.concat(region_names, ", ")
  --reaper.ShowMessageBox(region_names_string, "Regions created", 0)
  
  
  reaper.Undo_EndBlock("Create region from items block with matrix ready", 0)
end

--script execution

local tail=createGUI()
if tail then
  main(tail)
else
  reaper.ShowMessageBox("No length specified. Exiting.", "Info", 0)
end
