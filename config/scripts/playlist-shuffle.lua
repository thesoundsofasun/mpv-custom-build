local mp = require 'mp'

local is_shuffled = false

-- Function 1: The strict ON/OFF toggle
local function toggle_shuffle()
    if is_shuffled then
        -- Returns to the absolute original order
        mp.command("playlist-unshuffle")
        mp.set_property("playlist-pos", 0)
        mp.osd_message("Shuffle: OFF (Original Order)", 2)
        is_shuffled = false
    else
        mp.command("playlist-shuffle")
        mp.set_property("playlist-pos", 0)
        mp.osd_message("Shuffle: ON", 2)
        is_shuffled = true
    end
end

-- Function 2: Continuous Re-shuffle
local function reshuffle_playlist()
    if is_shuffled then
        -- Silently revert to the pristine original order FIRST before scrambling again
        mp.command("playlist-unshuffle")
    end
    
    mp.command("playlist-shuffle")
    mp.set_property("playlist-pos", 0)
    mp.osd_message("Playlist Re-Shuffled!", 2)
    is_shuffled = true
end

-- =========================================================
-- HARDCODED KEYBINDS (Overrides input.conf and MPV defaults)
-- =========================================================

-- Press lowercase 's' to Toggle ON/OFF
mp.add_forced_key_binding("s", "toggle_shuffle", toggle_shuffle)

-- Press uppercase 'S' (Shift + s) to continuously scramble
mp.add_forced_key_binding("S", "reshuffle_playlist", reshuffle_playlist)
