local mp = require 'mp'

local is_shuffled = false

local function toggle_shuffle()
    if is_shuffled then
        mp.command("playlist-unshuffle")
        mp.osd_message("Shuffle: OFF", 2)
        is_shuffled = false
    else
        mp.command("playlist-shuffle")
        mp.osd_message("Shuffle: ON", 2)
        is_shuffled = true
    end
end

-- Binds the 's' key directly inside the script. 
-- (You can change "s" to any key you want right here)
mp.add_key_binding("s", "toggle_shuffle", toggle_shuffle)