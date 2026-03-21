return
{
  'saghen/blink.cmp',
  cond = not vim.g.vscode,
  dependencies = { 'rafamadriz/friendly-snippets' },
  version = '1.*',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = 'super-tab' },

    appearance = {
      nerd_font_variant = 'mono'
    },

    completion = {
      -- Show documentation popup automatically
      documentation = { auto_show = true },
      -- Ghost text: inline preview of the top completion item
      ghost_text = { enabled = true },
    },

    signature = { enabled = true },

    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" }
  },
  opts_extend = { "sources.default" }
}
