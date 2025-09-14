--[[
Creates seamless loop from a selected item with user specified crossfade length. It does so by cutting the item in half, swapping the new two items and overlapping them.

It is important to set auto crossfades in preferences to zero to work properly.


--]]
 
--[[
 * Changelog:
 * v1.0 (2025-9-14)
  + Initial Release
--]]

--[[ --------------------------------------------------------------
   Create a manual cross‑fade for a single selected media item
   Steps:
   1️ Verify exactly one item is selected
   2️ Ask the user for the desired cross‑fade length (seconds)
   3️ Split the item in half
   4️  Shift the left part so the two halves overlap by that length
   5️  Apply matching fade‑out / fade‑in envelopes
   --------------------------------------------------------------]]

-----------------------------------------------------------------
-- 1️ Helper: ensure exactly one item is selected
-----------------------------------------------------------------
local function one_item_selected()
    local cnt = reaper.CountSelectedMediaItems(0)

    if cnt == 0 then
        reaper.ShowMessageBox("No items selected.", "Info", 0)
        return false
    elseif cnt > 1 then
        reaper.ShowMessageBox("Select only ONE item.", "Info", 0)
        return false
    end
    return true
end

-----------------------------------------------------------------
-- 2️  Ask the user for the cross‑fade length (seconds)
-----------------------------------------------------------------
local function get_cross_len()
    local retval, inp = reaper.GetUserInputs(
        "Cross‑fade length",
        1,
        "Length (seconds):",
        "0.5"                 -- sensible default; edit if you wish
    )
    if not retval then return nil end            -- user cancelled
    local len = tonumber(inp)
    if not len or len <= 0 then
        reaper.ShowMessageBox("Enter a positive number.", "Error", 0)
        return nil
    end
    return len
end

-----------------------------------------------------------------
-- 3️  Core routine – split, shift, and apply fades
-----------------------------------------------------------------
local function create_crossfade(cross_len)
    reaper.Undo_BeginBlock()

    -------------------------------------------------
    -- Grab the selected item (the *left* piece will be moved)
    -------------------------------------------------
    local left_item = reaper.GetSelectedMediaItem(0, 0)
    if not left_item then
        reaper.ShowMessageBox("Failed to fetch the selected item.", "Error", 0)
        reaper.Undo_EndBlock("Manual cross‑fade – error", -1)
        return
    end

    -------------------------------------------------
    -- Determine split point (exactly halfway)
    -------------------------------------------------
    local start_pos = reaper.GetMediaItemInfo_Value(left_item, "D_POSITION")
    local length    = reaper.GetMediaItemInfo_Value(left_item, "D_LENGTH")
    local split_at  = start_pos + length / 2

    -------------------------------------------------
    -- Split the item – the function returns the *right* piece
    -------------------------------------------------
    local right_item = reaper.SplitMediaItem(left_item, split_at)
    if not right_item then
        reaper.ShowMessageBox("Split failed.", "Error", 0)
        reaper.Undo_EndBlock("Manual cross‑fade – error", -1)
        return
    end

    -------------------------------------------------
    -- Compute the new start position for the left piece
    -- so that the two pieces overlap by `cross_len`
    -------------------------------------------------
    local right_start = reaper.GetMediaItemInfo_Value(right_item, "D_POSITION")
    local right_len   = reaper.GetMediaItemInfo_Value(right_item, "D_LENGTH")
    local new_left_start = right_start + right_len - cross_len

    -- Move the left piece
    reaper.SetMediaItemInfo_Value(left_item, "D_POSITION", new_left_start)

    -------------------------------------------------
    -- Apply matching fades
    -------------------------------------------------
    -- Left piece: fade‑out
    reaper.SetMediaItemInfo_Value(left_item,  "D_FADEINLEN", cross_len)
    -- Right piece: fade‑in
    reaper.SetMediaItemInfo_Value(right_item, "D_FADEOUTLEN",  cross_len)

    -- Optional: set fade shape (0 = linear, 1 = fast‑start, 2 = fast‑end,
    -- 3 = S‑curve, 4 = logarithmic, 5 = exponential, 6 = quarter‑sin,
    -- 7 = half‑sin, 8 = cosine, 9 = cubic, 10 = quartic, 11 = quintic)
    local fade_shape = 3   -- S‑curve gives a natural sounding cross‑fade
    reaper.SetMediaItemInfo_Value(left_item,  "C_FADEINSHAPE", fade_shape)
    reaper.SetMediaItemInfo_Value(right_item, "C_FADEOUTSHAPE",  fade_shape)

    -------------------------------------------------
    -- Refresh the arrange view and finish the undo block
    -------------------------------------------------
    reaper.UpdateArrange()
    reaper.Undo_EndBlock(string.format("Manual %g‑sec cross‑fade", cross_len), -1)
end

-----------------------------------------------------------------
-- Execution flow
-----------------------------------------------------------------
if one_item_selected() then
    local len = get_cross_len()
    if len then
        create_crossfade(len)
    else
        reaper.ShowMessageBox("No length supplied – script stopped.", "Info", 0)
    end
end
