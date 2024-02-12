local plugins = {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = 'VeryLazy',
    opts = {
      panel = {
        enabled = true,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
      },
      filetypes = {
        ["*"] = true,
      },
    },
  },

  {
    "RaafatTurki/hex.nvim",
    config = true,
    lazy = false,
  },
}

return plugins
