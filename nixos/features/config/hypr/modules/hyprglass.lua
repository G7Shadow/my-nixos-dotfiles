-- HyprGlass: Liquid Glass effect plugin
-- Loads after decoration so glass settings layer on top.
hl.config({
  plugin = "/etc/hypr/hyprglass.so",
})

if hl.plugin.hyprglass then
  local hg = hl.plugin.hyprglass

  hg.config({
    default_theme = "dark",
    default_preset = "subtle",
    tint_color = 0x8899aa22,

    brightness = 0.9,
    dark = { brightness = 0.82 },
    layers = { enabled = true },
  })

  hg.layer("quickshell:bar", { mask_threshold = 0.05 })
end
