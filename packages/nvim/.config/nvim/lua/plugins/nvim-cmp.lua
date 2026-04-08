-- Copilot completion source for blink.cmp
-- Uses blink.compat to wrap the nvim-cmp-style copilot source
return {
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink.compat.source",
            score_offset = 100,
            async = true,
          },
        },
      },
    },
  },
}
