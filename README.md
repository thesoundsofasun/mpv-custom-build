# Custom MPV Player Config
<img width="128" height="128" alt="mpv-icon_5" src="https://github.com/user-attachments/assets/376f0cfc-96d0-49ef-aa10-edf59df7644d" />


## Added features
### Functions:
- Auto loads playlist from any folder
- Auto loops audio that is shorter than 5 sec
- MIDI playback support
- Single instance playing
- YouTube video playback

### Visual:
- Ableton Sans font
- New MPV Player icon.
- Icons for every supported codec format
- Removed MPV logo from fresh MPV window
- Taskbar buttons

### Playlist control:
- Shuffle tracks in playlist (press S)
- Sort tracks by track number metadata (press T)

## Sources being used
### Scripts:
- Autoload script https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua
- Autoloop script https://github.com/zc62/mpv-scripts/blob/master/autoloop.lua
- Taskbar buttons https://github.com/qwerty12/mpv-taskbar-buttons/

### Binaries:
- Icons library (K-Lite Codec Pack (Flatro)) https://github.com/yjlin0224/MPC-HC_KLite-IconLibrary/tree/main/64bit
- MIDI Playback (fluidsynth) https://github.com/FluidSynth/fluidsynth/releases?page=2#release-v2.3.5
  - Soundfont https://github.com/craffel/pretty-midi/blob/main/pretty_midi/TimGM6mb.sf2
- YT playback (yt-dlp.exe) https://github.com/yt-dlp/yt-dlp/releases  
- Metadata sorting by track number (ffprobe.exe)

## Installation
### Automatic installation:
```powershell
irm https://raw.githubusercontent.com/thesoundsofasun/mpv-custom-build/refs/heads/main/Deploy.ps1 | iex
```

### Manual installation:
- Install MPV using WinGet:
```powershell
winget install -e --id shinchiro.mpv
```
- Set up folders for scripts in "%appdata%\mpv" (C:\Users\"USERNAME"\AppData\Roaming\mpv) alternatively its possible to create a "portable_config" folder in "C:\Program Files\MPV Player" directory
  - create "scripts" and "fonts" folders
  - download "config" folder from the source "https://github.com/thesoundsofasun/mpv-custom-build/tree/main/config" and drop all of the files into your preferred config directory (%appdata%\mpv)

- Download necessary binaries:
  - Download FluidSynth release from https://github.com/FluidSynth/fluidsynth/releases?page=2#release-v2.3.5
   - Create "midi-synth" folder in "C:\Program Files\MPV Player" directory
   - Unpack the archive and drop all of the binaries from the bin folder in newly created "midi-synth" folder
   - Download .sf2 soundfont this for example "https://github.com/craffel/pretty-midi/blob/main/pretty_midi/TimGM6mb.sf2"
   - Drop a soundfont file into "midi-synth" folder and rename it to "soundfont.sf2"
  - Download ytdlp.exe and drop it in "C:\Program Files\MPV Player" directory (To support YT video playback)
  - Download ffprobe.exe and drop it in "C:\Program Files\MPV Player" directory (To support metadata)

- Install custom icons for each format:
  - Download "installer" folder from the source "https://github.com/thesoundsofasun/mpv-custom-build/tree/main/installer"
  - Replace original files in "C:\Program Files\MPV Player\installer" with the files downloaded from the source
  - Run "mpv-install.bat" script to assign modern icons to each media file type
  - Make MPV Player a default app in Windows App Settings

- Finish  
  
