return {
  "dundalek/lazy-lsp.nvim",
  event = "BufReadPre",
  dependencies = { "neovim/nvim-lspconfig" },
  config = function()
    require("lazy-lsp").setup {
      use_vim_lsp_config = true,

      excluded_servers = {
        "ccls",        -- prefer clangd
        "denols",      -- prefer ts_ls
        "flow",        -- prefer ts_ls
        "ltex",        -- too CPU heavy
        "quick_lint_js",
        "tailwindcss", -- too greedy with filetypes
        "biome",
        "oxlint",
      },

      preferred_servers = {
        python = { "pyright", "ruff" },
        nix    = { "nil_ls" },
      },
    }
  end,
}
