return {
  -- REST Client for testing API endpoints
  {
    "rest-nvim/rest.nvim",
    ft = "http",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>rr", "<cmd>Rest run<cr>", desc = "Run REST request" },
      { "<leader>rl", "<cmd>Rest run last<cr>", desc = "Run last REST request" },
    },
    opts = {
      -- Skip SSL verification (useful for local development)
      skip_ssl_verification = true,
      -- Highlight request on run
      highlight = {
        enable = true,
        timeout = 150,
      },
      -- Response result settings
      result = {
        split = {
          horizontal = false,
          in_place = false,
        },
        behavior = {
          show_headers = true,
          show_statistics = true,
        },
      },
    },
  },
}

