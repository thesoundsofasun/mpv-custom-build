# Custom MPV Player Config
## Added features
### Functions:
- Auto loads playlist from any folder
- Auto loops audio that is shorter than 5 sec
- MIDI playback support
- Single instance playing
- YouTube video playback

### Visual:
- Custom font
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

### Binaries
- Icons library https://github.com/yjlin0224/MPC-HC_KLite-IconLibrary/tree/main/64bit
- MIDI Playback https://github.com/FluidSynth/fluidsynth/releases?page=2#release-v2.3.5
  - Soundfont https://github.com/craffel/pretty-midi/blob/main/pretty_midi/TimGM6mb.sf2
