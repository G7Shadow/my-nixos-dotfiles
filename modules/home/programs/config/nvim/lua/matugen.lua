local M = {}
function M.setup()
  require('base16-colorscheme').setup {
    base00 = '#101417',
    base01 = '#1c2024',
    base02 = '#262a2e',
    base03 = '#8b9198',
    base04 = '#c1c7ce',
    base05 = '#e0e3e8',
    base06 = '#e0e3e8',
    base07 = '#e0e3e8',
    base08 = '#ffb4ab',
    base09 = '#d0c0e8',
    base0A = '#b8c8d9',
    base0B = '#97ccf8',
    base0C = '#d0c0e8',
    base0D = '#97ccf8',
    base0E = '#b8c8d9',
    base0F = '#93000a',
  }
end

local signal = vim.uv.new_signal()
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return  M