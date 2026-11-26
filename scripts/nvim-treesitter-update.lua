-- Run by `task nvim:restore` and `task nvim:update` inside headless Neovim: reinstall interrupted
-- parsers, then update.
--
-- nvim-treesitter writes parser-info/<lang>.revision as the last step of a parser install, and
-- update() reads that file for every installed language, raising an error when it is missing.
-- LazyVim starts parser installs as soon as the plugin loads, and the headless runs before this one
-- (Lazy! restore, Lazy! clean) quit without waiting for them. That leaves a parser with its .so file
-- but no revision file, and every later update fails with "parser-info/<lang>.revision: No such
-- file or directory". Remove those leftovers and install them again before updating.
local config = require("nvim-treesitter.config")
local parsers = require("nvim-treesitter.parsers")

local function remove(path)
  local stat = vim.uv.fs_lstat(path)
  if not stat then
    return
  end
  if stat.type == "link" then
    vim.uv.fs_unlink(path)
  else
    vim.fn.delete(path, "rf")
  end
end

local info_dir = config.get_install_dir("parser-info")
local interrupted = {}
for _, lang in ipairs(config.get_installed()) do
  local parser = parsers[lang]
  -- Languages without install_info only have queries and never get a revision file.
  if parser and parser.install_info and vim.fn.filereadable(info_dir .. "/" .. lang .. ".revision") == 0 then
    table.insert(interrupted, lang)
  end
end

for _, lang in ipairs(interrupted) do
  remove(config.get_install_dir("parser") .. "/" .. lang .. ".so")
  remove(config.get_install_dir("queries") .. "/" .. lang)
end

local ts = require("nvim-treesitter")
if #interrupted > 0 then
  io.stdout:write("Reinstalling interrupted parsers: " .. table.concat(interrupted, ", ") .. "\n")
  ts.install(interrupted, { force = true }):wait(300000)
end
ts.update():wait(300000)
