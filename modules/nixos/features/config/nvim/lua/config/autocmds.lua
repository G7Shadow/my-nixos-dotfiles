-- highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  pattern = "*",
  desc = "highlight selection on yank",
  callback = function()
    vim.highlight.on_yank({ timeout = 200, visual = true })
  end,
})

-- restore cursor to file position in previous editing session
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
      vim.schedule(function()
        vim.cmd("normal! zz")
      end)
    end
  end,
})

-- open help in vertical split
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  command = "wincmd L",
})

-- auto resize splits when the terminal's window is resized
vim.api.nvim_create_autocmd("VimResized", {
  command = "wincmd =",
})

-- no auto continue comments on new line
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("no_auto_comment", {}),
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- syntax highlighting for dotenv files
vim.api.nvim_create_autocmd("BufRead", {
  group = vim.api.nvim_create_augroup("dotenv_ft", { clear = true }),
  pattern = { ".env", ".env.*" },
  callback = function()
    vim.bo.filetype = "dosini"
  end,
})

-- show cursorline only in active window enable
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("active_cursorline", { clear = true }),
  callback = function()
    vim.opt_local.cursorline = true
  end,
})

-- show cursorline only in active window disable
vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
  group = "active_cursorline",
  callback = function()
    vim.opt_local.cursorline = false
  end,
})

-- ide like highlight when stopping cursor (native Neovim only —
-- vscode-neovim doesn't implement vim.lsp.buf.clear_references)
if not vim.g.vscode then
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = vim.api.nvim_create_augroup("LspReferenceHighlight", { clear = true }),
    desc = "Highlight references under cursor",
    callback = function()
      if vim.fn.mode() ~= "i" then
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        local supports_highlight = false
        for _, client in ipairs(clients) do
          if client.server_capabilities.documentHighlightProvider then
            supports_highlight = true
            break
          end
        end

        if supports_highlight then
          vim.lsp.buf.clear_references()
          vim.lsp.buf.document_highlight()
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = "LspReferenceHighlight",
    desc = "Clear highlights when entering insert mode",
    callback = function()
      vim.lsp.buf.clear_references()
    end,
  })
end

-- watch ~/.cache/nvim-dynamite-theme for live theme switching
local cache_file = vim.fn.expand("~/.cache/nvim-dynamite-theme")
if vim.uv.fs_stat(cache_file) then
  local debounce
  local function apply_theme()
    local f = io.open(cache_file, "r")
    local theme = f and f:read("*l") or nil
    if f then f:close() end
    if not theme or theme == "" then return end

    local mapping = { ["tokyo-night"] = "tokyonight" }
    theme = mapping[theme] or theme

    vim.cmd.colorscheme(theme)
    vim.notify("Theme: " .. theme, vim.log.levels.INFO, { title = "Theme" })
  end

  local watcher = vim.uv.new_fs_event()
  watcher:start(cache_file, {}, vim.schedule_wrap(function()
    if debounce then debounce:close() end
    debounce = vim.defer_fn(apply_theme, 100)
  end))

  vim.api.nvim_create_autocmd("FocusGained", {
    callback = function()
      local stat = vim.uv.fs_stat(cache_file)
      if stat and stat.mtime.sec > (vim.g._dynamite_mtime or 0) then
        vim.g._dynamite_mtime = stat.mtime.sec
        apply_theme()
      end
    end,
  })
  vim.g._dynamite_mtime = vim.uv.fs_stat(cache_file).mtime.sec

  -- :DTheme command to manually trigger
  vim.api.nvim_create_user_command("DTheme", apply_theme, {})
end
