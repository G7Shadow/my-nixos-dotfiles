require("core.keymaps")
require("core.options")
require("core.lazy")
require("core.lsp")

-- Reload matugen colors on SIGUSR1
vim.api.nvim_create_autocmd("Signal", {
  pattern = "SIGUSR1",
  callback = function()
    local path = os.getenv("HOME") .. "/.config/nvim/matugen.lua"
    local f, _ = io.open(path, "r")
    if f then
      io.close(f)
      dofile(path)
    end
  end,
})
