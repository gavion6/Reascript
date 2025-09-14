-- Insert Silence Between Selected Items in REAPER with Randomization

-- Function to create the GUI
function createGUI()
    local retval, user_input = reaper.GetUserInputs("Insert Silence", 2, "Min Silence Length (seconds):,Max Silence Length (seconds):", "0.5,1.0")
    if retval then
        local minLength, maxLength = user_input:match("([^,]+),([^,]+)")
        return tonumber(minLength), tonumber(maxLength)
    end
    return nil, nil
end

-- Function to generate a random silence length
function getRandomSilenceLength(minLength, maxLength)
    return math.random() * (maxLength - minLength) + minLength
end

-- Function to insert silence
function insertSilence(minSilenceLength, maxSilenceLength)
    local selectedItems = reaper.CountSelectedMediaItems(0)
    if selectedItems < 2 then
        reaper.ShowMessageBox("Please select at least two items.", "Error", 0)
        return
    end

    -- Get the position of the first selected item
    local firstItem = reaper.GetSelectedMediaItem(0, 0)
    local lastItemEnd = reaper.GetMediaItemInfo_Value(firstItem, "D_POSITION") + reaper.GetMediaItemInfo_Value(firstItem, "D_LENGTH")

    -- Loop through selected items starting from the second one
    for i = 1, selectedItems - 1 do
        local currentItem = reaper.GetSelectedMediaItem(0, i)
        local currentItemStart = reaper.GetMediaItemInfo_Value(currentItem, "D_POSITION")

        -- Generate a random silence length
        local silenceLengthInSeconds = getRandomSilenceLength(minSilenceLength, maxSilenceLength)

        -- Move the current item to the end of the last item plus silence
        reaper.SetMediaItemInfo_Value(currentItem, "D_POSITION", lastItemEnd + silenceLengthInSeconds)

        -- Update the last item end position
        lastItemEnd = reaper.GetMediaItemInfo_Value(currentItem, "D_POSITION") + reaper.GetMediaItemInfo_Value(currentItem, "D_LENGTH")
    end
end

-- Main script execution
local minSilenceLength, maxSilenceLength = createGUI()
if minSilenceLength and maxSilenceLength then
    insertSilence(minSilenceLength, maxSilenceLength)
else
    reaper.ShowMessageBox("No length specified. Exiting.", "Info", 0)
end

