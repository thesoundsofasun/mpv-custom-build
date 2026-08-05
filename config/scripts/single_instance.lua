local mp    = require 'mp'
local msg   = require 'mp.msg'
local utils = require 'mp.utils'
 
-- IPC socket path per OS
local ipc_socket_path
if package.config:sub(1,1) == "\\" then
    ipc_socket_path = "\\\\.\\pipe\\mpvsocket"
else
    ipc_socket_path = "/tmp/mpvsocket"
end
 
-- Escape JSON special chars
local function escape_json_str(str)
    if not str then return "" end
    return (str:gsub("\\", "\\\\")
               :gsub("\"", "\\\""))
end
 
-- Get full absolute path for the current file
local function get_full_path()
    local path = mp.get_property("path") or ""
    if path == "" then return "" end
    return path
end
 
-- Try open IPC pipe in write mode to check if main instance is running
local function try_connect_pipe(path)
    local f = io.open(path, "w")
    if f then f:close() return true end
    return false
end
 
-- Send loadfile command with 'replace' to main instance or use 'append' to ADD to PLAYLIST instead
local function send_file_to_main(path, filepath)
    local escaped_path = escape_json_str(filepath or "")
    local json = string.format('{"command": ["loadfile", "%s", "replace"]}', escaped_path)
 
    local f = io.open(path, "w")
    if not f then
        msg.error("Could not connect to IPC pipe: " .. path)
        return false
    end
    f:write(json .. "\n")
    f:close()
    msg.info("Sent file to main MPV: " .. filepath)
    return true
end
 
-- Create IPC server pipe for main instance
local function create_ipc_server(path)
    mp.set_property("input-ipc-server", path)
    msg.info("Created IPC server pipe: " .. path)
end
 
-- Determine instance mode on script load
local is_main_instance = false
if try_connect_pipe(ipc_socket_path) then
    is_main_instance = false
    msg.info("Detected existing MPV instance. This is a secondary instance.")
    
    -- =========================================
    -- ANTI-FLICKER FIX #1:
    -- Instantly prevent this secondary instance from drawing a window
    -- =========================================
    mp.set_property("force-window", "no")
    mp.set_property("vid", "no")
else
    create_ipc_server(ipc_socket_path)
    is_main_instance = true
    msg.info("No MPV instance detected. This is the main instance.")
end
 
-- =========================================
-- ANTI-FLICKER FIX #2:
-- Use "on_load" hook instead of "start-file". 
-- This runs BEFORE video rendering initializes.
-- =========================================
mp.add_hook("on_load", 10, function()
    local filepath = get_full_path()
 
    if filepath == "" then
        msg.warn("No valid file path detected. Continuing standby.")
        return
    end
 
    msg.info("Playing file: " .. filepath)
 
    if is_main_instance then
        msg.info("Main instance: playing file normally.")
        -- normal playback behavior
    else
        msg.info("Secondary instance: sending file and quitting.")
        if send_file_to_main(ipc_socket_path, filepath) then
            -- Quit immediately (the timeout is no longer needed since no window is rendering)
            mp.commandv("quit")
        else
            msg.error("Failed to send file; continuing as standalone.")
            create_ipc_server(ipc_socket_path)
            is_main_instance = true
            
            -- Restore properties if the main instance died and this needs to become the main player
            mp.set_property("force-window", "yes")
            mp.set_property("vid", "auto")
        end
    end
end)