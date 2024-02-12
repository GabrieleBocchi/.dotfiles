local plugins = {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
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
    config = function()
      require("copilot").setup({})
    end,
  },
}

return plugins
