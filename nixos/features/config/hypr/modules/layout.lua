hl.config({
  general = {
    layout = "master",
  },

  dwindle = {
    force_split = 2,
    preserve_split = true,
  },

  master = {
    allow_small_split = false,
    new_status = "slave",
    new_on_top = false,
    new_on_active = "before",
    smart_resizing = true,
    drop_at_cursor = true,
    always_keep_position = false,
  },
})
