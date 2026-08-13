hl.layer_rule({
match     = { namespace = "quickshell:bar" },
  blur = true,
  ignore_alpha = 0.5,
})

hl.window_rule({
  name = "center-qs-settings",
  match = {
    class = "org.quickshell",
    title = "Settings"
  },
  float = true,
  center = true
})

hl.window_rule({
  name  = "hyprglass-off-fullscreen",
  match = { fullscreen = true },
  tag   = "+hyprglass_disabled",
})

hl.window_rule({
  name  = "hyprglass-off-mpv",
  match = { class = "mpv" },
  tag   = "+hyprglass_disabled",
})

hl.window_rule({
  name  = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name  = "fix-xwayland-drags",
  match = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

hl.window_rule({
  name  = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move  = "20 monitor_h-120",
  float = true,
})

  
