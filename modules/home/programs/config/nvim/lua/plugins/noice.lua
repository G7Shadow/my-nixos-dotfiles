return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    -- snacks.nvim is already loaded via opencode.nvim, no need to redeclare
  },
  opts = {
    -- Keep the default command line
    cmdline = { enabled = false },
    messages = { enabled = false },

    -- LSP progress shown as a compact spinner in the corner
    lsp = {
      progress = { enabled = true },
      -- Show hover/signature docs in noice's floating windows
      hover = { enabled = true },
      signature = { enabled = true },
      -- Don't override message routing for LSP messages (blink handles completion)
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = false,
      },
    },

    -- Compact popupmenu
    popupmenu = { enabled = true },

    -- A small command history viewer (<leader>snh to open)
    notify = { enabled = true },

    routes = {
      -- Send "written" file messages to mini (bottom-right corner, non-intrusive)
      {
        filter = { event = "msg_show", kind = "", find = "written" },
        opts   = { skip = true },
      },
      -- Hide "search hit BOTTOM" wrap messages
      {
        filter = { event = "msg_show", find = "search hit" },
        opts   = { skip = true },
      },
    },

    presets = {
      long_message_to_split = true,  -- long messages go to a split instead
      inc_rename            = false,
      lsp_doc_border        = true,  -- rounded borders on hover docs
    },
  },
  keys = {
    { "<leader>sn",  "",                                                            desc = "+noice" },
    { "<leader>snh", function() require("noice").cmd("history") end,                desc = "Noice history" },
    { "<leader>snl", function() require("noice").cmd("last") end,                   desc = "Noice last message" },
    { "<leader>snd", function() require("noice").cmd("dismiss") end,                desc = "Dismiss notifications" },
  },
}