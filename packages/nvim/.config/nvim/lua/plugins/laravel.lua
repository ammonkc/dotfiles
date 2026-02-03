return {
  -- Laravel.nvim for artisan commands, route list, etc.
  {
    "adalessa/laravel.nvim",
    dependencies = {
      "tpope/vim-dotenv",
      "nvim-telescope/telescope.nvim",
      "MunifTanjim/nui.nvim",
      "kevinhwang91/promise-async",
    },
    cmd = { "Laravel" },
    keys = {
      { "<leader>la", ":Laravel artisan<cr>", desc = "Laravel Artisan" },
      { "<leader>lr", ":Laravel routes<cr>", desc = "Laravel Routes" },
      { "<leader>lm", ":Laravel related<cr>", desc = "Laravel Related Files" },
    },
    event = { "VeryLazy" },
    opts = {
      -- All Laravel projects use docker-compose.
      environments = {
        default = "docker-compose",
        ask_on_boot = false,
      },
    },
    config = true,
  },
  -- Neotest for running PHPUnit/Pest tests
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "V13Axel/neotest-pest",
      "olimorris/neotest-phpunit",
    },
    opts = {
      adapters = {
        ["neotest-pest"] = {
          pest_cmd = function()
            return "vendor/bin/pest"
          end,
        },
        ["neotest-phpunit"] = {
          phpunit_cmd = function()
            return "vendor/bin/phpunit"
          end,
        },
      },
    },
  },
}

