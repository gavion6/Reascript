-- Function to check if any items are selected
function main()
    reaper.Undo_BeginBlock()
    -- Get the number of selected items
    local selected_items_count = reaper.CountSelectedMediaItems(0)
    local cut_obey_sel = 41384
    local cut_items = 40699
    local unsel_all = reaper.NamedCommandLookup("_SWS_UNSELALL")
    local cut_ignore_sel = 40059

    -- If no items are selected, do nothing
    if selected_items_count == 0 then
        reaper.ShowMessageBox("No selecected items", "Info", 0)
        return
    end
    
    -- Get the time selection start and end
    local time_selection_start, time_selection_end = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, false)
    
    -- Get the current position of mouse in time
    
    local mouse_position = reaper.BR_PositionAtMouseCursor(false)

    -- Check if the time selection is valid
    if time_selection_start == time_selection_end then
        reaper.Main_OnCommand(cut_items, 0)
        -- reaper.ShowMessageBox("No selection", "Info", 0)
    end

    -- Check if the transport is within the time selection
    if mouse_position >= time_selection_start and mouse_position <= time_selection_end then
        -- Transport is within the time selection
        reaper.Main_OnCommand(cut_obey_sel, 0)
        --reaper.ShowMessageBox("Transport is within the time selection.", "Info", 0)
    else
        -- Transport is outside the time selection
        reaper.Main_OnCommand(cut_ignore_sel, 0)
        --reaper.ShowMessageBox("START: " .. time_selection_start .. " END: " .. time_selection_end .. " POS: " .. transport_position, "Info", 0)
        --reaper.ShowMessageBox("Cut ignored due to transport position.", "Info", 0)
    end

    -- Unselect all items
    reaper.Main_OnCommand(unsel_all, 0)
    
    reaper.Undo_EndBlock("Cut operation based on transport position", -1)
end

-- Run the main function
main()
