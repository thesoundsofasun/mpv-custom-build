local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'
local opts = require 'mp.options'

-- ======================================================================
-- 1. BYPASS CHECK (For independent windows)
-- ======================================================================
local options = { bypass = "no" }
opts.read_options(options, "single_instance")

if options.bypass == "yes" then
    msg.info("Standalone instance spawned via shortcut. Bypassing IPC.")
    return 
end

-- ======================================================================
-- 2. FILE TYPE DETECTION (Audio vs Video)
-- ======================================================================
local first_file = mp.get_property("playlist/0/filename") or ""
local ext = first_file:match("^.+%.(.+)$")
if ext then ext = ext:lower() end

local video_exts = {
    ["3gp"]=true, ["asf"]=true, ["avi"]=true, ["dv"]=true, ["flv"]=true,
    ["ivf"]=true, ["m2ts"]=true, ["mkv"]=true, ["mov"]=true, ["mp4"]=true,
    ["mpa"]=true, ["mpg"]=true, ["mxf"]=true, ["ogm"]=true, ["rm"]=true,
    ["rmvb"]=true, ["ts"]=true, ["vob"]=true, ["webm"]=true, ["wmv"]=true
}

local is_video = video_exts[ext] or false
local is_windows = package.config:sub(1,1) == "\\"

-- ======================================================================
-- 3. CROSS-PLATFORM IPC SOCKET SETUP
-- ======================================================================
local pipe_name = is_video and "mpvsocket_video" or "mpvsocket_audio"
local ipc_socket_path = is_windows and ("\\\\.\\pipe\\" .. pipe_name) or ("/tmp/" .. pipe_name)

local function escape_json_str(str)
    if not str then return "" end
    return (str:gsub("\\", "\\\\"):gsub("\"", "\\\""))
end

-- Universal function to send data to another MPV instance
local function send_ipc(path, json)
    if is_windows then
        local f = io.open(path, "w")
        if not f then return false end
        f:write(json .. "\n")
        f:close()
        return true
    else
        -- Linux/Mac Socket Handlers
        local payload = json .. "\n"
        
        -- 1. Try socat (The Linux standard for MPV)
        local res = utils.subprocess({args = {"socat", "-", "UNIX-CONNECT:" .. path}, stdin_data = payload, cancellable = false})
        if res.status == 0 then return true end
        
        -- 2. Try nc (Netcat)
        res = utils.subprocess({args = {"nc", "-U", path}, stdin_data = payload, cancellable = false})
        if res.status == 0 then return true end
        
        -- 3. Try Python3 (Pre-installed on almost all distros)
        local py_script = "import socket,sys; s=socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect(sys.argv[1]); s.send(sys.argv[2].encode('utf-8')); s.close()"
        res = utils.subprocess({args = {"python3", "-c", py_script, path, payload}, cancellable = false})
        if res.status == 0 then return true end
        
        return false
    end
end

-- Checks if a main instance is actively running
local function is_server_alive(path)
    local alive = send_ipc(path, '{"command":["get_version"]}')
    -- Linux Auto-Cleanup: If socket is dead, delete the leftover file so we can become the new server
    if not is_windows and not alive then
        os.remove(path)
    end
    return alive
end

local function create_ipc_server(path)
    mp.set_property("input-ipc-server", path)
end

-- ======================================================================
-- 4. ANTI-FLICKER GHOSTING
-- ======================================================================
local is_main_instance = false
if is_server_alive(ipc_socket_path) then
    is_main_instance = false
    mp.set_property("force-window", "no")
    mp.set_property("vid", "no")
else
    create_ipc_server(ipc_socket_path)
    is_main_instance = true
end

-- ======================================================================
-- 5. THE FILE ROUTER
-- ======================================================================
mp.add_hook("on_load", 10, function()
    local filepath = mp.get_property("stream-open-filename", "")
    if filepath == "" then return end

    if not is_main_instance then
        local escaped_path = escape_json_str(filepath)
        local json = string.format('{"command": ["loadfile", "%s", "replace"]}', escaped_path)
        
        if send_ipc(ipc_socket_path, json) then
            mp.commandv("quit")
        else
            -- Failsafe: Resurrect if main window crashes mid-transfer
            create_ipc_server(ipc_socket_path)
            is_main_instance = true
            mp.set_property("force-window", "yes")
            mp.set_property("vid", "auto")
        end
    end
end)

-- ======================================================================
-- 6. HOTKEY: SPAWN INDEPENDENT WINDOW
-- ======================================================================
mp.add_key_binding("Ctrl+n", "open-new-window", function()
    mp.command_native_async({
        name = "subprocess",
        args = {"mpv", "--script-opts=single_instance-bypass=yes", "--player-operation-mode=pseudo-gui"},
        detach = true
    }, function() end)
    mp.osd_message("Opened Independent Window", 2)
end)
