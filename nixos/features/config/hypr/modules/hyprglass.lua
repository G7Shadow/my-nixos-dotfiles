-- HyprGlass: Liquid Glass effect plugin
-- Loads the .so first, then configures it.

hl.config({
  plugin = "/etc/hypr/hyprglass.so",
})

if hl.plugin.hyprglass then
  local hg = hl.plugin.hyprglass

  hg.config({
    default_theme = "dark",
    default_preset = "subtle",
    tint_color = 0x8899aa22,

    blur_strength = 1.5,
    refraction_strength = 0.4,
    chromatic_aberration = 0.3,
    fresnel_strength = 0.5,
    specular_strength = 0.6,
    glass_opacity = 0.85,
    edge_thickness = 0.04,

    dark = { brightness = 0.82 },
    light = { adaptive_boost = 0.4 },

    layers = { enabled = true },
  })

  hg.layer("quickshell:bar", { mask_threshold = 0.05 })
end
