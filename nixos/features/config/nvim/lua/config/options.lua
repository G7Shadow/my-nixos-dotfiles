vim.g.mapleader = " "

vim.opt.swapfile = false

vim.opt.number = true
vim.opt.shell = "zsh"

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
