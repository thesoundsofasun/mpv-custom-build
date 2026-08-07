local mp = require 'mp'
local overlay = mp.create_osd_overlay("ass-events")

local function update_idle()
    if mp.get_property_native("idle-active") then
        -- \an5 centers the text. 
        -- \c&HFF8800& makes the text a beautiful blue (ASS color format is Blue-Green-Red)
        local ass = "{\\an5}{\\fs45}{\\b1}{\\c&HFF8800&}MPV PLAYER\\N\\N{\\b0}{\\fs30}{\\c&HFFFFFF&}Drop a track here to play"
        overlay.data = ass
        overlay:update()
    else
        overlay:remove()
    end
end

-- Listens for when MPV stops playing media, and instantly draws the text
mp.observe_property("idle-active", "bool", update_idle)