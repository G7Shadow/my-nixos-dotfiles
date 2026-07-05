return {
  -- fallback / default
  { "craftzdog/solarized-osaka.nvim", lazy = true, priority = 1000,              opts = { transparent = true } },

  -- theme plugins (lazy — only load when the colorscheme is activated)
  { "folke/tokyonight.nvim",          lazy = true, opts = { transparent = true } },
  { "catppuccin/nvim",                lazy = true, name = "catppuccin",          opts = { transparent = true } },
  { "ellisonleao/gruvbox.nvim",       lazy = true, opts = { transparent = true } },
  { "sainnhe/everforest",             lazy = true, opts = { transparent = true } },
  { "rebelot/kanagawa.nvim",          lazy = true, opts = { transparent = true } },
  { "EdenEast/nightfox.nvim",         lazy = true, opts = { transparent = true } },
  { "rose-pine/neovim",               lazy = true, name = "rose-pine",           opts = { transparent = true } },
  { "shaunsingh/nord.nvim",           lazy = true, opts = { transparent = true } },
  { "sainnhe/gruvbox-material",       lazy = true, opts = { transparent = true } },
  { "rose-pine/neovim",               lazy = true, name = "rose-pine",           opts = { transparent = true } },
}
