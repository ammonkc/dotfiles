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
    opts = function(_, opts)
      -- Disable built-in CursorHold: it runs even when `vim.treesitter.get_parser()` is nil (e.g. Lazy UI),
      -- which crashes in utils.get_node_at_cursor. We replace it with a guarded autocmd below.
      return vim.tbl_deep_extend("force", opts or {}, {
        enable_autocmd = false,
        custom_calculation = function(_, language_tree)
          if vim.bo.filetype ~= "blade" or not language_tree then
            return
          end
          local lang = language_tree:lang()
          if lang ~= "javascript" and lang ~= "php" then
            return "{{-- %s --}}"
          end
        end,
      })
    end,
    config = function(_, opts)
      require("ts_context_commentstring").setup(opts)

      local function should_update_commentstring()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].buftype ~= "" then
          return false
        end
        local ft = vim.bo[buf].filetype
        if ft == "lazy" or ft == "notify" or ft == "noice" then
          return false
        end
        local ok, parser = pcall(vim.treesitter.get_parser, buf)
        return ok and parser ~= nil
      end

      local group = vim.api.nvim_create_augroup("user_ts_context_commentstring_hold", { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = group,
        callback = function()
          if not should_update_commentstring() then
            return
          end
          require("ts_context_commentstring").update_commentstring()
        end,
      })
    end,
  },
}
