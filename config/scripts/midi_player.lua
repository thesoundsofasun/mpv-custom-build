local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

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

mp.add_hook("on_load", 50, function()
    local path = mp.get_property("stream-open-filename", "")
    if not path then return end
    
    local ext = path:match("^.+%.(.+)$")
    if ext then ext = ext:lower() end
    
    if ext == "mid" or ext == "midi" then
        
        local install_dir = "C:\\Program Files\\mpv"
        if not file_exists(install_dir .. "\\mpv.exe") then
            install_dir = "C:\\Program Files\\MPV Player"
        end
        
        local fluidsynth = install_dir .. "\\midi-synth\\fluidsynth.exe"
        local soundfont = install_dir .. "\\midi-synth\\soundfont.sf2"
        
        if not file_exists(fluidsynth) or not file_exists(soundfont) then
            mp.osd_message("Error: FluidSynth or SoundFont missing!", 4)
            return
        end
        
        mp.osd_message("Synthesizing MIDI...", 10)
        
        local temp_wav = os.getenv("TEMP") .. "\\mpv_midi_temp.wav"
        os.remove(temp_wav)
        
        -- Clean, bulletproof arguments
        local args = {
            fluidsynth,
            "-ni",
            "-F", temp_wav,     
            "-T", "wav",        
            "-O", "s16",        
            "-r", "44100",      
            "-g", "1.0",        
            soundfont,          
            path                
        }
        
        local res = utils.subprocess({args = args, cancellable = false})
        
        if res.status == 0 and file_exists(temp_wav) and get_file_size(temp_wav) > 100 then
            mp.set_property("stream-open-filename", temp_wav)
            mp.osd_message("Playing MIDI", 3)
        else
            mp.osd_message("Error: FluidSynth failed to render audio.", 5)
        end
    end
end)