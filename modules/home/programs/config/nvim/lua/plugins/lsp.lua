return {
  { "mason.nvim",           enabled = false },
  { "mason-lspconfig.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nil_ls = {},
        ts_ls = {},
        lua_ls = {},
        cssls = {},
        hyprls = {},
        html = {},
        pyright = {},
      },
    },
  },
}
