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

  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    ft = { "json" },
    config = true,
  },
}

return plugins
