hl.plugin.load("/etc/profiles/per-user/jeremyl/lib/hyprglass.so")

if hl.plugin.hyprglass then
  local hg = hl.plugin.hyprglass

  hg.config({
    default_theme  = "dark",
    default_preset = "clear",

    glass_opacity = 0.85,
    brightness    = 0.9,

    layers = { enabled = true },
  })

  hg.layer("quickshell:bar", { preset = "subtle", mask_threshold = 0.05 })
  hg.layer("quickshell:bezel", { preset = "ui", mask_threshold = 0.3 })
end
