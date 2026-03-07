--------------------------------------------------------------------------------
-- 0. Global LSP Defaults (Neovim 0.11+)
--------------------------------------------------------------------------------

local base_caps = vim.lsp.protocol.make_client_capabilities()
local caps = require("blink.cmp").get_lsp_capabilities(base_caps)
caps.textDocument.completion.completionItem.snippetSupport = true

vim.lsp.config('*', {
  capabilities = caps,
  root_markers = { '.git' },
})

--------------------------------------------------------------------------------
-- 1. Diagnostic Configuration
--------------------------------------------------------------------------------
vim.diagnostic.config({
  virtual_text  = true,
  severity_sort = true,
  float         = {
    style  = 'minimal',
    border = 'rounded',
    source = 'if_many',
    header = '',
    prefix = '',
  },
  signs         = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✘',
      [vim.diagnostic.severity.WARN]  = '▲',
      [vim.diagnostic.severity.INFO]  = '»',
      [vim.diagnostic.severity.HINT]  = '⚑',
    },
  },
})

local orig_float = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts            = opts or {}
  opts.border     = opts.border or 'rounded'
  opts.max_width  = opts.max_width or 80
  opts.max_height = opts.max_height or 24
  opts.wrap       = opts.wrap ~= false
  return orig_float(contents, syntax, opts, ...)
end

--------------------------------------------------------------------------------
-- 2. LSP Attach Behavior
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp.attach', {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local buf = ev.buf

    local map = function(mode, lhs, rhs)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf })
    end

    map('n', 'K', vim.lsp.buf.hover)
    map('n', 'gd', vim.lsp.buf.definition)
    map('n', 'gD', vim.lsp.buf.declaration)
    map('n', 'gi', vim.lsp.buf.implementation)
    map('n', 'go', vim.lsp.buf.type_definition)
    map('n', 'gr', vim.lsp.buf.references)
    map('n', 'gs', vim.lsp.buf.signature_help)
    map('n', 'gl', vim.diagnostic.open_float)
    map('n', '<F2>', vim.lsp.buf.rename)
    map({ 'n', 'x' }, '<F3>', function()
      vim.lsp.buf.format({ async = true })
    end)
    map('n', '<F4>', vim.lsp.buf.code_action)

    if client.supports_method('textDocument/formatting')
        and not client.supports_method('textDocument/willSaveWaitUntil')
    then
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('my.lsp.format.' .. buf, { clear = true }),
        buffer = buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = buf, id = client.id, timeout_ms = 1000 })
        end,
      })
    end
  end,
})

--------------------------------------------------------------------------------
-- 3. Server-specific settings (no cmd/enable needed — lazy-lsp handles that)
--------------------------------------------------------------------------------

vim.lsp.config['lua_ls'] = {
  settings = {
    Lua = {
      runtime     = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace   = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file('', true),
      },
      telemetry   = { enable = false },
    },
  },
}

vim.lsp.config['nil_ls'] = {
  settings = {
    ['nil'] = {
      formatting = { command = { "alejandra" } },
    },
  },
}

vim.lsp.config['ts_ls'] = {
  settings = {
    completions = { completeFunctionCalls = true },
  },
}

vim.lsp.config['pyright'] = {
  settings = {
    python = {
      analysis = {
        autoSearchPaths        = true,
        useLibraryCodeForTypes = true,
        diagnosticMode         = 'openFilesOnly',
      },
    },
  },
}

vim.lsp.config['qmlls'] = {
  cmd = { 'qmlls', '--build-dir', '/nix/store' },
}

vim.lsp.config['html'] = {
  init_options = {
    provideFormatter     = true,
    embeddedLanguages    = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },
}
