-- add more treesitter parsers
return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = function(_, opts)
      -- Register blade filetype
      vim.filetype.add({
        pattern = {
          [".*%.blade%.php"] = "blade",
        },
      })

      -- Register blade parser (new API)
      local parser_config = require("nvim-treesitter.parsers")
      if parser_config.blade == nil then
        vim.treesitter.language.register("blade", "blade")
      end

      -- Merge ensure_installed
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "php",
        "php_only",
      })

      opts.auto_install = true
      opts.highlight = { enable = true }
      opts.indent = { enable = true }
    end,
  },
  -- ts-context-commentstring for blade support
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    opts = {
      custom_calculation = function(_, language_tree)
        if vim.bo.filetype == "blade" and language_tree._lang ~= "javascript" and language_tree._lang ~= "php" then
          return "{{-- %s --}}"
        end
      end,
    },
  },
}
