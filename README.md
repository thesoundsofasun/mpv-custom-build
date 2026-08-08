# Custom MPV Player Config


<img width="150" height="150" alt="mpv-icon" src="https://github.com/user-attachments/assets/3a20d57a-d3d4-4ab8-a318-5fcdc5782f76" />
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="100%" height="100%" viewBox="0 0 48 48" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" xmlns:serif="http://www.serif.com/" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:2;">
    <g id="Layer-1" serif:id="Layer 1">
        <path d="M48,7.059L48,40.941C48,44.837 44.837,48 40.941,48L7.059,48C3.163,48 0,44.837 0,40.941L0,7.059C0,3.163 3.163,0 7.059,0L40.941,0C44.837,0 48,3.163 48,7.059Z" style="fill:url(#_Linear1);"/>
        <g id="g835" transform="matrix(1.264273,0,0,1.264273,-6.310706,-7.044258)">
            <path id="path827" d="M17.764,15.57L17.764,35.064L25.867,30.191L33.971,25.317L25.867,20.444L17.764,15.57Z" style="fill:white;stroke:white;stroke-width:0.79px;"/>
        </g>
    </g>
    <defs>
        <linearGradient id="_Linear1" x1="0" y1="0" x2="1" y2="0" gradientUnits="userSpaceOnUse" gradientTransform="matrix(0,48,-48,0,24,0)"><stop offset="0" style="stop-color:rgb(42,128,185);stop-opacity:1"/><stop offset="0.5" style="stop-color:rgb(39,120,174);stop-opacity:1"/><stop offset="1" style="stop-color:rgb(29,87,126);stop-opacity:1"/></linearGradient>
    </defs>
</svg>




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
  - Download FluidSynth release from https://github.com/FluidSynth/fluidsynth/releases?page=2#release-v2.3.5 (or just download "midi-synth" folder from my repository and drop it in the C:\Program Files\MPV Player" directory)
   - Create "midi-synth" folder in "C:\Program Files\MPV Player" directory
   - Unpack the archive and drop all of the binaries from the bin folder in newly created "midi-synth" folder
   - Download .sf2 soundfont this for example "https://github.com/craffel/pretty-midi/blob/main/pretty_midi/TimGM6mb.sf2"
   - Drop a soundfont file into "midi-synth" folder and rename it to "soundfont.sf2"
  - Download ytdlp.exe and drop it in "C:\Program Files\MPV Player" directory (To support YT video playback)
  - Download ffprobe.exe and drop it in "C:\Program Files\MPV Player" directory (To support metadata)

- Install custom icons for the app and each format:
  - Download "installer" folder from the source "https://github.com/thesoundsofasun/mpv-custom-build/tree/main/installer"
  - Replace original files in "C:\Program Files\MPV Player\installer" with the files downloaded from the source
  - Run "mpv-install.bat" script to assign modern icons to each media file type
  - Make MPV Player a default app in Windows App Settings

- Finish  
  
