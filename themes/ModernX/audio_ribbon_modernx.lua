local mp = require 'mp'

local NORMAL_SCALE = "2.5"
local RIBBON_SCALE = "5" 
local RIBBON_HEIGHT = "190" 

local is_strip_mode = false
local saved_geometry = ""

-- Function 1: Switch back to the big square window
local function apply_normal_mode()
    if not is_strip_mode then return end
    
    -- 1. Restore the big window geometry
    if saved_geometry ~= "" and not saved_geometry:match("x" .. RIBBON_HEIGHT) then
        mp.set_property("geometry", saved_geometry)
    else
        mp.set_property("geometry", "800x800")
    end
    
    -- 2. Restore normal UI scale and Auto-Hiding progress bar
    mp.commandv("change-list", "script-opts", "append", "osc-scalewindowed=" .. NORMAL_SCALE)
    mp.commandv("change-list", "script-opts", "append", "osc-visibility=auto")
    
    is_strip_mode = false
end

-- Function 2: Snap into the tiny audio ribbon
local function apply_strip_mode()
    if is_strip_mode then return end
    
    saved_geometry = mp.get_property("geometry") or ""
    local current_width = mp.get_property("osd-width") or "800"
    
    mp.set_property("autofit-larger", "none")
    mp.set_property("autofit", "none")
    
    -- 1. Shrink the window vertically
    mp.set_property("geometry", current_width .. "x" .. RIBBON_HEIGHT) 
    
    -- 2. Boost the UI scale, and force the progress bar to stay ALWAYS ON
    mp.commandv("change-list", "script-opts", "append", "osc-scalewindowed=" .. RIBBON_SCALE)
    mp.commandv("change-list", "script-opts", "append", "osc-visibility=always")
    
    is_strip_mode = true
end

-- The core logic that decides which mode to use
local function update_window_shape()
    local idle = mp.get_property_native("idle-active")
    local vid = mp.get_property("vid")
    
    if idle then
        apply_normal_mode()
    elseif vid == "no" or vid == nil then
        apply_strip_mode()
    else
        apply_normal_mode()
    end
end

-- ANTI-FLICKER: Wait 0.1s for the engine to settle before resizing!
local debounce_timer = nil
local function trigger_update()
    if debounce_timer then debounce_timer:kill() end
    debounce_timer = mp.add_timeout(0.1, update_window_shape)
end

-- Watch the engine for real-time changes using the anti-flicker timer
mp.observe_property("idle-active", "bool", trigger_update)
mp.observe_property("vid", "string", trigger_update)