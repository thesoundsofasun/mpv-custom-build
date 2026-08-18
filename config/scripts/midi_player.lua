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

-- Dynamically find the midi-synth folder regardless of where MPV is installed
local function get_midi_synth_dir()
    local paths = {
        "C:\\Program Files\\Utilities\\mpv\\midi-synth",
        "C:\\Program Files\\Utilities\\MPV Player\\midi-synth",
        "C:\\Program Files\\MPV Player\\midi-synth",
        "C:\\Program Files\\mpv\\midi-synth"
    }
    
    -- Dynamically check relative to the MPV config folder (for pure portable setups)
    local config_dir = mp.command_native({"expand-path", "~~/"})
    if config_dir then
        config_dir = config_dir:gsub("/", "\\")
        table.insert(paths, config_dir .. "\\..\\midi-synth")
        table.insert(paths, config_dir .. "\\midi-synth")
    end

    for _, dir in ipairs(paths) do
        local test_exe = dir .. "\\fluidsynth.exe"
        if file_exists(test_exe) then
            return dir
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
        
        local synth_dir = get_midi_synth_dir()
        
        if not synth_dir then
            mp.osd_message("Error: midi-synth folder not found anywhere!", 4)
            msg.error("Could not locate fluidsynth.exe in any known MPV folders.")
            return
        end
        
        local fluidsynth = synth_dir .. "\\fluidsynth.exe"
        local soundfont = synth_dir .. "\\soundfont.sf2"
        
        if not file_exists(soundfont) then
            mp.osd_message("Error: soundfont.sf2 is missing from midi-synth!", 4)
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
