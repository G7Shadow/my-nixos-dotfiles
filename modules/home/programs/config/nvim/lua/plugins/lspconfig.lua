return {
  "neovim/nvim-lspconfig",
  cond = not vim.g.vscode,
  event = "BufReadPre",
  config = function() end,
}
