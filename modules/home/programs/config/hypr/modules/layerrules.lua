hl.layer_rule({
  match     = { namespace = "rofi" },
  animation = "popin 95%",
})

hl.layer_rule({
  match     = { namespace = "my-ags-bar" },
  animation = "slide top",
})

hl.layer_rule({
  match        = { namespace = "noctalia-background-.*" },
  blur         = true,
  blur_popups  = true,
  ignore_alpha = 0.5,
})
