local configs = require("plugins.configs.lspconfig")
local on_attach = configs.on_attach
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"
local servers = {
  "clangd", -- C
  "cssls", -- Css
  "dockerls", -- Dockerfile
  "lua_ls", -- Lua
  "pyright", -- Python
  "tsserver", -- TypeScript, JavaScript
  "vimls", -- Vim
}

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end
