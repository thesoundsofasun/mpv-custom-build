local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local is_windows = package.config:sub(1,1) == "\\"
local is_flatpak = false

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true else return false end
end

local function get_file_size(path)
    local f = io.open(path, "rb")
    if not f then return 0 end
    local size = f:seek("end")
    f:close()
    return size
end

if not is_windows and file_exists("/.flatpak-info") then
    is_flatpak = true
end

local function get_soundfont()
    local config_dir = mp.command_native({"expand-path", "~~/"})
    local sf2_path = config_dir .. "/midi-synth/soundfont.sf2"
    if is_windows then sf2_path = sf2_path:gsub("/", "\\") end
    if file_exists(sf2_path) then return sf2_path end
    
    if not is_windows then
        local home = os.getenv("HOME")
        if home then
            local linux_paths = {
                home .. "/.var/app/io.mpv.Mpv/config/mpv/midi-synth/soundfont.sf2",
                home .. "/.config/mpv/midi-synth/soundfont.sf2"
            }
            for _, p in ipairs(linux_paths) do
                if file_exists(p) then return p end
            end
        end
    end
    return nil
end

mp.add_hook("on_load", 50, function()
    local path = mp.get_property("stream-open-filename", "")
    if not path then return end
    
    local ext = path:match("^.+%.(.+)$")
    if ext then ext = ext:lower() end
    
    if ext == "mid" or ext == "midi" then
        
        local soundfont = get_soundfont()
        if not soundfont then
            mp.osd_message("Error: soundfont.sf2 missing from midi-synth!", 4)
            return
        end
        
        mp.osd_message("Synthesizing MIDI...", 10)
        
        local temp_wav = ""
        if is_windows then
            temp_wav = os.getenv("TEMP") .. "\\mpv_midi_temp.wav"
        elseif is_flatpak then
            temp_wav = os.getenv("HOME") .. "/.var/app/io.mpv.Mpv/cache/mpv_midi_temp.wav"
        else
            temp_wav = "/tmp/mpv_midi_temp.wav"
        end
        os.remove(temp_wav)
        
        local args = {}
        if is_windows then
            local config_dir = mp.command_native({"expand-path", "~~/"}):gsub("/", "\\")
            local fluidsynth = config_dir .. "\\midi-synth\\fluidsynth.exe"
            if not file_exists(fluidsynth) then fluidsynth = "C:\\Program Files\\Utilities\\mpv\\midi-synth\\fluidsynth.exe" end
            table.insert(args, fluidsynth)
        elseif is_flatpak then
            table.insert(args, "flatpak-spawn")
            table.insert(args, "--host")
            table.insert(args, "fluidsynth")
        else
            table.insert(args, "fluidsynth")
        end
        
        -- Append standard FluidSynth commands
        local fs_args = {"-ni", "-F", temp_wav, "-T", "wav", "-O", "s16", "-r", "44100", "-g", "1.0", soundfont, path}
        for _, a in ipairs(fs_args) do table.insert(args, a) end
        
        -- Run the command
        local res = utils.subprocess({args = args, cancellable = false, capture_stdout = true, capture_stderr = true})
        
        if res.status == 0 and file_exists(temp_wav) and get_file_size(temp_wav) > 100 then
            mp.set_property("stream-open-filename", temp_wav)
            mp.osd_message("Playing MIDI", 3)
        else
            -- Print the exact failure reason to the terminal/console
            msg.error("FLUIDSYNTH FAILED! Status: " .. tostring(res.status))
            msg.error("Stderr: " .. (res.stderr or "None"))
            msg.error("Stdout: " .. (res.stdout or "None"))
            mp.osd_message("Error: Permission Denied by Flatpak (See Console)", 5)
        end
    end
end)
