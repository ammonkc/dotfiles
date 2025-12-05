-- Optional: AI chat with Claude inside Neovim
-- Uncomment and add your ANTHROPIC_API_KEY to use
-- export ANTHROPIC_API_KEY="your-key" in your shell config

return {
  {
    "yetone/avante.nvim",
    enabled = false, -- Set to true to enable
    event = "VeryLazy",
    lazy = false,
    version = false,
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = { file_types = { "markdown", "Avante" } },
        ft = { "markdown", "Avante" },
      },
    },
    opts = {
      provider = "claude",
      claude = {
        model = "claude-sonnet-4-20250514",
        max_tokens = 4096,
      },
    },
  },
}

