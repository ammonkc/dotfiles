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
  -- Add dadbod completion via blink.cmp
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = {
          sql = { "dadbod" },
          mysql = { "dadbod" },
          plsql = { "dadbod" },
        },
        providers = {
          dadbod = { module = "vim_dadbod_completion.blink" },
        },
      },
    },
  },
}

