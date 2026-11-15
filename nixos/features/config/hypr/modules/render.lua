hl.config({
  render = {
    -- Auto-HDR flips the monitor into wide color gamut (BT2020) when a
    -- fullscreen surface advertises HDR. WCG is part of aquamarine's
    -- reconfig mask, so it forces a full KMS modeset (black flash) on every
    -- fullscreen enter/exit. This panel is 8-bit (no `bitdepth, 10`), so it
    -- can't even display it and Hyprland warns:
    --   "Monitor eDP-1: wide color gamut is enabled but the display is not in
    --    10-bit mode."
    cm_auto_hdr = 0,
  },
})
