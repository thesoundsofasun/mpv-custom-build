local mp = require 'mp'
local overlay = mp.create_osd_overlay("ass-events")

local function update_idle()
    if mp.get_property_native("idle-active") then
        
        -- ENGINE LEVEL KILL SWITCH: Physically disables the default UI component
        mp.set_property("osc", "no")
        
        -- Draw your custom text
        local ass = "{\\an5}{\\fs45}{\\b1}{\\c&HB9802A&}MPV PLAYER\\N\\N{\\b0}{\\fs30}{\\c&HFFFFFF&}Drop a track here to play"
        overlay.data = ass
        overlay:update()
    else
        -- Physically turn the default UI back on when music starts
        mp.set_property("osc", "yes")
        overlay:remove()
    end
end

mp.observe_property("idle-active", "bool", update_idle)
