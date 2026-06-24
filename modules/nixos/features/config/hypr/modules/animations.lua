-- M3 Standard scheme spatial
hl.curve("md3_spacial_fast", { type = "spring", mass = 1, stiffness = 600, dampening = 49 })
hl.curve("md3_spacial_defualt", { type = "spring", mass = 1, stiffness = 300, dampening = 35 })
hl.curve("md3_spacial_slow", { type = "spring", mass = 1, stiffness = 160, dampening = 25 })

-- Effect springs
hl.curve("md3_effects_fast", { type = "spring", mass = 1, stiffness = 3800, dampening = 123 })
hl.curve("md3_effects_defualt", { type = "spring", mass = 1, stiffness = 1600, dampening = 80 })
hl.curve("md3_effects_slow", { type = "spring", mass = 1, stiffness = 800, dampening = 57 })

-- Beziers for layers
hl.curve("md3_standard", { type = "bezier", points = { { 0.2, 0.0 }, { 0.0, 1.0 } } })
hl.curve("md3_emphasized_accel", { type = "bezier", points = { { 0.3, 0.0 }, { 0.8, 0.15 } } })

-- Animations
hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "md3_spacial_defualt" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, spring = "md3_spacial_defualt", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, spring = "md3_spacial_defualt", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, spring = "md3_spacial_defualt" })

hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "md3_standard", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "md3_standard", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 2.5, bezier = "md3_emphasized_accel", style = "slide" })

hl.animation({ leaf = "fade", enabled = true, speed = 2, spring = "md3_effects_defualt" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, spring = "md3_spacial_defualt" })

hl.animation({ leaf = "border", enabled = true, speed = 2, spring = "md3_spacial_defualt" })
hl.animation({ leaf = "borderangle", enabled = false })

hl.animation({ leaf = "workspaces", enabled = true, speed = 5, spring = "md3_spacial_defualt", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, spring = "md3_spacial_fast", style = "slidevert" })
