local mainMod  = "SUPER"
local terminal = "kitty"
local menu     = "pkill rofi || rofi -show drun -theme ~/.config/rofi/themes/grid.rasi"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill -SIGUSR2 waybar"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Focus
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

-- Workspaces
for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Quickshell panels (registered as GlobalShortcuts)
hl.bind("SUPER + Space", hl.dsp.global("quickshell:launcher"))
hl.bind("SUPER + T", hl.dsp.global("quickshell:theme"))
hl.bind("SUPER + SHIFT + T", hl.dsp.global("quickshell:wallpaper"))
hl.bind("SUPER + comma", hl.dsp.global("quickshell:settings"))
hl.bind("SUPER + C", hl.dsp.global("quickshell:calendar"))
hl.bind("CTRL + ALT + Delete", hl.dsp.global("quickshell:logout"))
hl.bind("CTRL + ALT + L", hl.dsp.global("quickshell:lock"))
hl.bind("SUPER + N", hl.dsp.global("quickshell:nightlight"))
hl.bind("SUPER + G", hl.dsp.global("quickshell:gamemode"))
hl.bind("SUPER + A", hl.dsp.exec_cmd("qs ipc call controlcenter toggle"))

-- Media keys (quickshell, locked + repeating)
hl.bind("XF86AudioRaiseVolume", hl.dsp.global("quickshell:volumeUp"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.global("quickshell:volumeDown"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.global("quickshell:volumeMute"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.global("quickshell:brightnessUp"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("quickshell:brightnessDown"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
