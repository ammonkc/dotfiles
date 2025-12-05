-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- LazyDocker
map("n", "<leader>gd", function()
  Snacks.terminal({ "lazydocker" }, { cwd = LazyVim.root() })
end, { desc = "LazyDocker" })

-- Quick access to common Laravel files
map("n", "<leader>fe", "<cmd>e .env<cr>", { desc = "Edit .env" })
map("n", "<leader>fw", "<cmd>e routes/web.php<cr>", { desc = "Edit web routes" })
map("n", "<leader>fa", "<cmd>e routes/api.php<cr>", { desc = "Edit API routes" })
