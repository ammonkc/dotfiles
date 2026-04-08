return {
  -- Better .env file support (syntax + hide values)
  {
    "ellisonleao/dotenv.nvim",
    config = function()
      require("dotenv").setup({
        enable_on_load = true,
        verbose = false,
      })
    end,
  },
  -- Highlight TODO, FIXME, HACK, etc.
  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble", "TodoTelescope" },
    event = "LazyFile",
    opts = {},
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next Todo Comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous Todo Comment" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Search Todos" },
    },
  },
  -- Better quickfix list
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {},
  },
}

