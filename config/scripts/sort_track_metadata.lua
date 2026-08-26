local mp = require 'mp'
local utils = require 'mp.utils'

-- Silently uses ffprobe to read track metadata
local function get_track_num(path)
    local args = {
        "ffprobe", 
        "-v", "error", 
        "-show_entries", "format_tags=track", 
        "-of", "default=noprint_wrappers=1:nokey=1", 
        path
    }
    local res = utils.subprocess({args = args, cancellable = false})
    
    if res.error == nil and res.status == 0 and res.stdout then
        -- Extracts the number (turns "1/12" into just "1")
        local num = res.stdout:match("%d+")
        return tonumber(num) or 9999
    end
    return 9999
end

local function sort_metadata()
    mp.osd_message("Reading metadata... (UI may pause for a second)", 3)
    
    local count = mp.get_property_number("playlist-count", 0)
    if count < 2 then return end
    
    -- Store track numbers
    local nums = {}
    for i = 0, count - 1 do
        local path = mp.get_property("playlist/" .. i .. "/filename")
        nums[i] = get_track_num(path)
    end
    
    -- Bubble sort the playlist in-place
    for i = 0, count - 1 do
        for j = 0, count - 2 - i do
            if nums[j] > nums[j+1] then
                -- Move the tracks around inside MPV's engine
                mp.commandv("playlist-move", j+1, j)
                
                -- Swap them in our script to match
                local temp = nums[j]
                nums[j] = nums[j+1]
                nums[j+1] = temp
            end
        end
    end
    
    -- ==========================================
    -- NEW: Jump to the very first track!
    -- ==========================================
    mp.set_property("playlist-pos", 0)
    
    mp.osd_message("Playlist Sorted chronologically by Track Number!", 3)
end

-- Binds this to the 't' key
mp.add_key_binding("t", "sort-metadata", sort_metadata)
