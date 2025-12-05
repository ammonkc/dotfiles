return {
  "mfussenegger/nvim-lint",
  event = "LazyFile",
  opts = {
    -- Event to trigger linters
    events = { "BufWritePost", "BufReadPost", "InsertLeave" },
    linters_by_ft = {
      fish = { "fish" },
      dockerfile = { "hadolint" },
      php = { "phpstan" },
      -- Shell scripting
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
      -- Use the "*" filetype to run linters on all filetypes.
      -- ['*'] = { 'global linter' },
      -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
      -- ['_'] = { 'fallback linter' },
    },
    -- LazyVim extension to easily override linter options
    -- or add custom linters.
    ---@type table<string,table>
    linters = {
      phpstan = {
        args = {
          "analyze",
          "--error-format=json",
          "--no-progress",
          "--memory-limit=2G",
        },
      },
      shellcheck = {
        -- Exclude some common warnings
        -- SC1091: Not following sourced file
        -- SC2034: Variable appears unused
        args = { "-f", "json", "-x", "-e", "SC1091" },
      },
    },
  },
}
