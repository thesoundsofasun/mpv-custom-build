local mp = require 'mp'
local overlay = mp.create_osd_overlay("ass-events")

local function update_idle()
if mp.get_property_native("idle-active") then
    -- Draw your custom blue text
    local ass = "{\\an5}{\\fs45}{\\b1}{\\c&HFF8800&}MPV MEDIA PLAYER\\N\\N{\\b0}{\\fs30}{\\c&HFFFFFF&}Drop a track here to play"
    overlay.data = ass
    overlay:update()
    else
        -- Remove the text when media starts (Notice we removed the osc=yes command here!)
        overlay:remove()
        end
        end

mp.observe_property("idle-active", "bool", update_idle)
