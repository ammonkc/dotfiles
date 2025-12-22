return {
  "m4xshen/hardtime.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    -- Disable in these filetypes
    disabled_filetypes = {
      "qf",
      "netrw",
      "NvimTree",
      "neo-tree",
      "lazy",
      "mason",
      "oil",
      "Avante",
      "AvanteInput",
    },
    -- Max count before hint/restriction kicks in
    max_count = 3,
    -- Show hints for better alternatives
    hints = {
      ["[kj][kj][kj]"] = {
        message = function()
          return "Use {count}j/k or search"
        end,
        length = 3,
      },
      ["[hl][hl][hl]"] = {
        message = function()
          return "Use w/b/f/t"
        end,
        length = 3,
      },
    },
    -- Set to true to completely block bad habits (stricter mode)
    restriction_mode = "hint", -- "hint" or "block"
  },
}

