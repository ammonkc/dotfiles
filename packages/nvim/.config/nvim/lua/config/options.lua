-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- General
opt.relativenumber = true -- Relative line numbers (useful for motions)
opt.scrolloff = 8 -- Keep 8 lines visible above/below cursor
opt.sidescrolloff = 8 -- Keep 8 columns visible left/right of cursor

-- Search
opt.ignorecase = true -- Ignore case in search
opt.smartcase = true -- Unless uppercase is used

-- Indentation (defaults, can be overridden per filetype in autocmds.lua)
opt.tabstop = 4 -- PHP standard
opt.shiftwidth = 4
opt.expandtab = true

-- Wrapping
opt.wrap = false -- Don't wrap lines
opt.linebreak = true -- If wrap is enabled, break at word boundaries

-- File handling
opt.autoread = true -- Auto-reload files changed outside of Neovim
opt.backup = false -- Don't create backup files
opt.swapfile = false -- Don't create swap files (LazyVim handles recovery)

-- Completion
opt.completeopt = "menu,menuone,noselect"

-- Splits
opt.splitbelow = true -- Horizontal splits below
opt.splitright = true -- Vertical splits to the right

-- Performance
opt.updatetime = 200 -- Faster CursorHold events
opt.timeoutlen = 300 -- Faster key sequence completion

-- Appearance
opt.termguicolors = true -- True color support
opt.signcolumn = "yes" -- Always show sign column (prevents layout shift)
opt.cursorline = true -- Highlight current line

-- Shell (for :terminal and shell commands)
if vim.fn.executable("zsh") == 1 then
  opt.shell = "zsh"
end
