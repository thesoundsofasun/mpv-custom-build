local mp = require("mp")

function show_title()
    -- media-title automatically grabs embedded tags (Artist - Title) or filename
    local title = mp.get_property_osd("media-title")
    if title and title ~= "" then
        mp.osd_message(title, 4) -- Displays the title on screen for 4 seconds
    end
end

-- Trigger whenever playback starts or switches to a new file
mp.observe_property("media-title", "string", show_title)
