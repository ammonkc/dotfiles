-- Override via NVIM_COLORSCHEME env var (e.g., "catppuccin-mocha", "tokyonight")
-- Override catppuccin flavor via NVIM_CATPPUCCIN_FLAVOR env var (latte, frappe, macchiato, mocha)
local colorscheme = os.getenv("NVIM_COLORSCHEME") or "catppuccin-mocha"
local catppuccin_flavor = os.getenv("NVIM_CATPPUCCIN_FLAVOR") or "mocha"

return {
  -- Add catppuccin theme plugin
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = catppuccin_flavor, -- latte, frappe, macchiato, mocha
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mini = true,
        native_lsp = {
          enabled = true,
        },
      },
    },
  },
  -- Configure LazyVim to use the colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = colorscheme,
    },
  },
}
