local tools = {
  "actionlint",
  "ansible-language-server",
  "ansible-lint",
  "antlers-language-server",
  "black",
  "bash-language-server",
  "blade-formatter",
  "docker-compose-language-service",
  "dockerfile-language-server",
  "dot-language-server",
  "emmet-ls",
  "eslint_d",
  "hadolint",
  "html-lsp",
  "intelephense",
  "nginx-language-server",
  "php-debug-adapter",
  "phpstan",
  "prettierd",
  "pyright",
  "rustywind",
  "shellcheck",
  "shfmt",
  "stylua",
  "tailwindcss-language-server",
}

-- Mason installs pint (Laravel's PHP formatter) with Composer. Composer is only in the full
-- Homebrew bundle, so skip pint when it is missing; a core install then still finishes with
-- every other tool installed, and the next restore adds pint once Composer exists.
if vim.fn.executable("composer") == 1 then
  table.insert(tools, "pint")
end

return {
  -- Mason package manager
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = tools,
    },
  },

  -- Mason tool installer - enables headless install/update of Mason packages
  -- Provides :MasonToolsInstall, :MasonToolsUpdate, :MasonToolsClean commands
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason.nvim" },
    cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
    event = "VeryLazy",
    opts = {
      ensure_installed = tools,
      auto_update = false, -- Don't auto-update on startup (can be slow)
      run_on_start = true, -- Install missing tools on startup
    },
  },
}
