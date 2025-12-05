return {
  -- Database UI - connect to MySQL, PostgreSQL, SQLite, etc.
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Database UI" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      -- Optional: Set default database connections
      -- vim.g.dbs = {
      --   { name = "local", url = "mysql://root:password@localhost/database" },
      -- }
    end,
  },
  -- Add completion for dadbod in SQL files
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = {
      "kristijanhusak/vim-dadbod-completion",
    },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, { name = "vim-dadbod-completion" })
    end,
  },
}

