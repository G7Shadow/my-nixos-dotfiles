hl.config({
  general = {
    gaps_in          = 8,
    gaps_out         = 20,
    border_size      = 1,
    col              = {
      active_border   = colors.bg2,
      inactive_border = colors.bg1,
    },

    resize_on_border = false,
    allow_tearing    = false,
  },

  decoration = {
    rounding         = 25,
    rounding_power   = 10,
    active_opacity   = 1.0,
    inactive_opacity = 0.8,

    shadow           = {
      enabled      = true,
      range        = 28,
      render_power = 3,
      color        = 0x890a0a0a,
    },

    blur             = {
      enabled  = true,

      size     = 10,
      passes   = 2,
      noise    = 0.01,
      contrast = 0.8,
      vibrancy = 0.2,
    },
  },

  xwayland = {
    force_zero_scaling = true,
  },
})
