return {
  "akinsho/bufferline.nvim",
  event = "BufReadPost",  -- lazy-load: only after a file is opened
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  opts = {
    options = {
      mode = "tabs",
    },
  },
}