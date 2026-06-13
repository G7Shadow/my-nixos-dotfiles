local mainMod  = "SUPER"
local terminal = "kitty"
local menu     = "pkill rofi || rofi -show drun -theme ~/.config/rofi/themes/grid.rasi"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M",
  hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
-- hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill -SIGUSR2 waybar"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("noctalia-shell ipc call lockScreen lock"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("noctalia-shell ipc call launcher toggle"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Noctalia panels
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("noctalia-shell ipc call controlCenter toggle"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("noctalia-shell ipc call sessionMenu toggle"))

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

-- Media/brightness keys — delegated to Noctalia IPC
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia-shell ipc call volume increase"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia-shell ipc call volume decrease"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia-shell ipc call volume muteOutput"),
  { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia-shell ipc call volume muteInput"),
  { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia-shell ipc call brightness increase"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia-shell ipc call brightness decrease"),
  { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
