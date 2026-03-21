-- init.lua
require("core.keymaps")
require("core.options")
require("core.lazy")

if not vim.g.vscode then
  require("core.lsp")
end