local c = require("colors.matugen")

hl.config({
  general = {
    gaps_in          = 10,
    gaps_out         = 20,
    border_size      = 2,
    col              = {
      active_border   = c.background,
      inactive_border = c.inverse_primary,
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

      range        = 10,
      render_power = 3,
      color        = c.shadow,
    },

    blur             = {
      enabled           = true,

      size              = 10,
      passes            = 2,
      noise             = 0.01,
      contrast          = 0.8,
      vibrancy          = 0.2,
      new_optimizations = true,
    },
  },

  xwayland = {
    force_zero_scaling = true,
  },
})
