local plugins = {
  {
    "neovim/nvim-lspconfig",
     config = function()
        require "plugins.configs.lspconfig"
        require "custom.configs.lspconfig"
     end,
  },

  {
   "williamboman/mason.nvim",
   opts = {
      ensure_installed = {
        -- LSP
        "clangd", -- C
        "css-lsp", -- Css
        "dockerfile-language-server", -- Dockerfile
        "lua-language-server", -- Lua
        "pyright", -- Python
        "typescript-language-server", -- TypeScript, JavaScript
        "vim-language-server", -- Vim

        -- Linters
        "flake8", -- Python

        -- Formatters
        "black", -- Python
        "prettier", -- JavaScript
      },
    },
  },

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
