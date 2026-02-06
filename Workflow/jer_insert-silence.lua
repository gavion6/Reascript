-- @description Insert Silence
-- @about Insert silence between items, can be a negative value as well.
-- @version 0.2025-25-9
-- @author jeravi
-- @donation https://buymeacoffee.com/vitjerabek
-- @changelog initial release


-- Function to create the GUI
function createGUI()
    local retval, user_input = reaper.GetUserInputs("Insert Silence", 1, "Silence Length (seconds):", "0.5")
    if retval then
        return tonumber(user_input)
    end
    return nil
end

-- Function to insert silence
function insertSilence(silenceLength)
    local selectedItems = reaper.CountSelectedMediaItems(0)
    if selectedItems < 2 then
        reaper.ShowMessageBox("Please select at least two items.", "Error", 0)
        return
    end

    -- Convert silence length from seconds to seconds
    local silenceLengthInSeconds = silenceLength

    -- Get the position of the first selected item
    local firstItem = reaper.GetSelectedMediaItem(0, 0)
    local lastItemEnd = reaper.GetMediaItemInfo_Value(firstItem, "D_POSITION") + reaper.GetMediaItemInfo_Value(firstItem, "D_LENGTH")

    -- Loop through selected items starting from the second one
    for i = 1, selectedItems - 1 do
        local currentItem = reaper.GetSelectedMediaItem(0, i)
        local currentItemStart = reaper.GetMediaItemInfo_Value(currentItem, "D_POSITION")

        -- Move the current item to the end of the last item plus silence
        reaper.SetMediaItemInfo_Value(currentItem, "D_POSITION", lastItemEnd + silenceLengthInSeconds)

        -- Update the last item end position
        lastItemEnd = reaper.GetMediaItemInfo_Value(currentItem, "D_POSITION") + reaper.GetMediaItemInfo_Value(currentItem, "D_LENGTH")
    end
end

-- Main script execution
local silenceLength = createGUI()
if silenceLength then
    insertSilence(silenceLength)
else
    reaper.ShowMessageBox("No length specified. Exiting.", "Info", 0)
end

