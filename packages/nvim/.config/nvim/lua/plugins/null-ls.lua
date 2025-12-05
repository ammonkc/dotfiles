-- NOTE: PHPStan is now configured in nvim-lint.lua to avoid duplicate linting
-- This file is kept for other none-ls sources if needed

return {
  {
    "nvimtools/none-ls.nvim",
    opts = function()
      -- local nls = require("null-ls")
      return {
        sources = {
          -- Add any none-ls specific sources here that aren't covered by nvim-lint or conform
          -- PHPStan has been moved to nvim-lint.lua
        },
      }
    end,
  },
}
