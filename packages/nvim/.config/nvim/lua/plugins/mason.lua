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
  -- "nginx-language-server" is left out: it declares Requires-Python <3.14 (0.9.0), so pip refuses it
  -- with the Python that mise pins (3.15). Add it back once it supports the pinned Python.
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
    -- LazyVim and its extras also list tools (stylua, shfmt, shellcheck, hadolint, ...), and
    -- opts_extend concatenates the lists without removing duplicates. LazyVim's config calls
    -- install() on every entry without checking for an install in progress, so on a fresh machine
    -- a duplicated name fails with "package is already installing" and aborts mason's config.
    opts = function(_, opts)
      local seen, unique = {}, {}
      for _, tool in ipairs(vim.list_extend(opts.ensure_installed or {}, tools)) do
        if not seen[tool] then
          seen[tool] = true
          table.insert(unique, tool)
        end
      end
      opts.ensure_installed = unique
    end,
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
