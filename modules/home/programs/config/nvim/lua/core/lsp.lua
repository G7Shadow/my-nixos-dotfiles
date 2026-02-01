--------------------------------------------------------------------------------
-- 0. Global LSP Defaults (Neovim 0.11+)
--------------------------------------------------------------------------------

-- Blink-cmp capabilities
local base_caps = vim.lsp.protocol.make_client_capabilities()
local caps = require("blink.cmp").get_lsp_capabilities(base_caps)
caps.textDocument.completion.completionItem.snippetSupport = true

-- Defaults applied to EVERY LSP unless overridden
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

-- Consistent borders for floating LSP windows
local orig_float = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or 'rounded'
  opts.max_width = opts.max_width or 80
  opts.max_height = opts.max_height or 24
  opts.wrap = opts.wrap ~= false
  return orig_float(contents, syntax, opts, ...)
end

--------------------------------------------------------------------------------
-- 2. LSP Attach Behavior (keymaps, formatting)
--------------------------------------------------------------------------------

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp.attach', {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local buf = ev.buf

    local map = function(mode, lhs, rhs)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf })
    end

    -- Keymaps
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

    -- Autoformat (safe)
    if client.supports_method('textDocument/formatting')
        and not client.supports_method('textDocument/willSaveWaitUntil')
    then
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('my.lsp.format', { clear = false }),
        buffer = buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = buf, id = client.id, timeout_ms = 1000 })
        end,
      })
    end
  end,
})

--------------------------------------------------------------------------------
-- 3. Server Definitions (modern `vim.lsp.config`)
--------------------------------------------------------------------------------

-- Lua
vim.lsp.config['lua_ls'] = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file('', true),
      },
      telemetry = { enable = false },
    },
  },
}

-- CSS
vim.lsp.config['cssls'] = {
  cmd = { 'vscode-css-language-server', '--stdio' },
  filetypes = { 'css', 'scss', 'less' },
  root_markers = { 'package.json', '.git' },
  settings = {
    css = { validate = true },
    scss = { validate = true },
    less = { validate = true },
  },
}

-- Typescript / Javascript
vim.lsp.config['ts_ls'] = {
  cmd = { 'typescript-language-server', '--stdio' },
  root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
  filetypes = {
    'javascript', 'javascriptreact', 'javascript.jsx',
    'typescript', 'typescriptreact', 'typescript.tsx',
  },
  settings = {
    completions = {
      completeFunctionCalls = true,
    },
  },
}

-- Nix
vim.lsp.config['nil_ls'] = {
  cmd = { 'nil' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', 'default.nix', '.git' },
  settings = {
    ['nil'] = {
      formatting = {
        command = { "alejandra" },
      },
    },
  },
}

-- Python
vim.lsp.config['pyright'] = {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyrightconfig.json',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
}

-- Hyprlang
vim.lsp.config['hyprls'] = {
  cmd = { 'hyprls', '--stdio' },
  filetypes = { 'hyprlang' },
  root_markers = { '.git' },
}

-- Html
vim.lsp.config['html'] = {
  cmd = { 'vscode-html-language-server', '--stdio' },
  filetypes = { 'html', 'templ' },
  root_markers = { 'package.json', '.git' },
  settings = {},
  init_options = {
    provideFormatter = true,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },
}

-- Qml

vim.lsp.config['qmlls'] = {
  cmd = { 'qmlls' },
  filetypes = { 'qml', 'qmljs' },
  root_markers = { '.git' },
}

--------------------------------------------------------------------------------
-- 4. Enable Servers
--------------------------------------------------------------------------------
vim.lsp.enable('lua_ls')
vim.lsp.enable('cssls')
vim.lsp.enable('ts_ls')
vim.lsp.enable('pyright')
vim.lsp.enable('nil_ls')
vim.lsp.enable('hyprls')
vim.lsp.enable('html')
vim.lsp.enable('qmlls')
