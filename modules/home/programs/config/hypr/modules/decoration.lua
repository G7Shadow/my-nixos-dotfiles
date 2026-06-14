local c = require("colors.matugen")

hl.config({
  general = {
    gaps_in          = 10,
    gaps_out         = 20,
    border_size      = 2,
    col = {
      active_border   = c.background,
      inactive_border = c.inverse_primary,
    },
    resize_on_border = false,
    allow_tearing    = false,
    layout           = "master",
  },
  decoration = {
    rounding         = 15,
    rounding_power   = 2,
    active_opacity   = 1.0,
    inactive_opacity = 0.8,
    shadow = {
      enabled      = true,
      range        = 10,
      render_power = 5,
      color        = c.shadow,
    },
    blur = {
      enabled           = true,
      size              = 3,
      passes            = 1,
      vibrancy          = 0.5,
      vibrancy_darkness = 0.2,
    },
  },
  dwindle = {
    preserve_split = true,
  },
  master = {
    new_status = "slave",
  },
  misc = {
    force_default_wallpaper = -1,
    disable_hyprland_logo   = false,
  },
  xwayland = {
    force_zero_scaling = true,
  },
})