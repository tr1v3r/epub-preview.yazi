# Records docs/demo.gif: hover EPUBs in Yazi and watch the covers appear.
#
#   vhs docs/demo.tape
#
# ⚠️  THIS DOES NOT CURRENTLY PRODUCE A USABLE DEMO. VHS renders through
# ttyd + xterm.js, which cannot display Yazi's image previews: Yazi's terminal
# probe false-positives under ttyd, so it picks the Kitty/Sixel driver and
# writes escapes that xterm.js silently discards. The result is a preview pane
# that looks empty (or, if KITTY_WINDOW_ID leaks in from the recorder's own
# Kitty session, a grid of placeholder glyphs). See docs/RECORDING.md.
#
# The tape is kept because the fixture/setup path is still correct and useful;
# swap the Output for a real terminal recording once the capture story changes.
#
# Requires vhs, yazi, ImageMagick (magick) and zip.

Output docs/demo.gif

Require yazi
Require magick
Require zip

Set Shell "bash"
Set FontFamily "Hack Nerd Font Mono"
Set FontSize 17
Set Width 1200
Set Height 720
Set Padding 12
Set Framerate 12
Set Theme "Catppuccin Mocha"
Set WindowBar Colorful
Set TypingSpeed 1ms

Hide
Type `repo_root="$(pwd -P)"`
Enter
Type `sh "$repo_root/docs/demo-env.sh" "$(cd /tmp && pwd -P)/epub-preview-demo"`
Enter
# Clear anything advertising a graphics-capable terminal, otherwise Yazi emits
# image escapes that ttyd cannot render.
Type `unset KITTY_WINDOW_ID KITTY_PID KITTY_PUBLIC_KEY WEZTERM_EXECUTABLE GHOSTTY_RESOURCES_DIR TERM_PROGRAM`
Enter
Type `export TERM=xterm-256color`
Enter
Type `export YAZI_CONFIG_HOME="$(cd /tmp && pwd -P)/epub-preview-demo/config"`
Enter
Type `cd "$(cd /tmp && pwd -P)/epub-preview-demo/books"`
Enter
Type "clear"
Enter
Type "yazi"
Enter
Sleep 3s
Show

Sleep 1s
Type "j"
Sleep 1500ms
Type "j"
Sleep 1500ms
Type "j"
Sleep 3s
