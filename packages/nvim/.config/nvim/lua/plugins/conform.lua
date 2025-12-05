local util = require("conform.util")
return {
  "stevearc/conform.nvim",
  opts = function()
    ---@type conform.setupOpts
    local opts = {
      default_format_opts = {
        timeout_ms = 3000,
        async = false, -- not recommended to change
        quiet = false, -- not recommended to change
        lsp_format = "fallback", -- not recommended to change
      },
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        -- Shell scripting
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        -- PHP/Laravel
        php = { "pint" },
        blade = { "blade-formatter", "rustywind" },
        -- Python
        python = { "black" },
        -- JavaScript/TypeScript
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescriptreact = { "prettierd" },
        vue = { "prettierd" },
        -- Misc
        json = { "prettierd" },
        yaml = { "prettierd" },
        markdown = { "prettierd" },
      },
      -- LazyVim will merge the options you set here with builtin formatters.
      -- You can also define any custom formatters here.
      ---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
      formatters = {
        injected = { options = { ignore_errors = true } },
        -- Laravel Pint - prefers local vendor version
        pint = {
          meta = {
            url = "https://github.com/laravel/pint",
            description = "Laravel Pint is an opinionated PHP code style fixer for minimalists.",
          },
          command = util.find_executable({
            "vendor/bin/pint",
            vim.fn.stdpath("data") .. "/mason/bin/pint",
          }, "pint"),
          args = { "$FILENAME" },
          stdin = false,
        },
        -- shfmt with sensible defaults for shell scripts
        shfmt = {
          prepend_args = { "-i", "2", "-ci", "-bn" },
        },
      },
    }
    return opts
  end,
}
