-- lua/plugins/lsp.lua
-- Modern LSP Configuration for Neovim 0.10+ (2025)
-- Uses native vim.lsp.config API (no nvim-lspconfig needed!)
-- Optimized for C/C++/CUDA development

return {
  -- Mason: LSP/DAP/Linter Package Manager
  {
    "williamboman/mason.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end,
  },

  -- Mason-LSPConfig Bridge (only for auto-installation)
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    priority = 999,
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "pyright", "ltex" },
        automatic_installation = true,
      })
    end,
  },

  -- Native LSP Configuration (Neovim 0.10+)
  {
    "hrsh7th/cmp-nvim-lsp",
    lazy = false,
    priority = 998,
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      -- LSP Capabilities (for nvim-cmp integration)
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- CUDA Filetype Detection (.cu files)
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "*.cu",
        callback = function()
          vim.bo.filetype = "cuda"
        end,
      })

      -- Disable non-ltex LSP in Markdown
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(ev)
          local clients = vim.lsp.get_clients({ bufnr = ev.buf })
          for _, client in ipairs(clients) do
            if client.name ~= "ltex" then
              vim.lsp.stop_client(client.id)
            end
          end
        end,
      })

      -- LspAttach: Keybindings and Configuration
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          -- Block non-ltex LSP in Markdown files
          if vim.bo[bufnr].filetype == "markdown" and client.name ~= "ltex" then
            vim.lsp.stop_client(client.id)
            return
          end

          local opts = { buffer = bufnr }

          -- LSP Keybindings
          vim.keymap.set("n", "gd", function()
            vim.lsp.buf.definition({
              on_list = function(options)
                if #options.items == 0 then
                  vim.notify("No definition found", vim.log.levels.WARN)
                  return
                end
                vim.fn.setqflist({}, " ", options)
                vim.cmd("cfirst")
              end,
            })
          end, { buffer = bufnr, desc = "Go to definition" })

          vim.keymap.set("n", "gb", "<C-o>", { buffer = bufnr, desc = "Go back" })
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover documentation" })
          vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr, desc = "Find references" })
          vim.keymap.set("n", "<leader>c", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename symbol" })
          vim.keymap.set("n", "<leader>g", vim.diagnostic.open_float, { buffer = bufnr, desc = "Show diagnostics" })
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Previous diagnostic" })
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Next diagnostic" })
        end,
      })

      -- Clangd Configuration (C/C++/CUDA)
      vim.lsp.config.clangd = {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=never",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
        },
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        root_markers = { ".clangd", ".clang-format", "compile_commands.json", "compile_flags.txt", ".git" },
        capabilities = capabilities,
      }

      -- Pyright Configuration (Python)
      vim.lsp.config.pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
            },
          },
        },
      }

      -- LTeX Configuration (Grammar/Spell Check for Markdown)
      vim.lsp.config.ltex = {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/ltex-ls" },
        filetypes = { "markdown", "tex", "bib" },
        capabilities = capabilities,
        cmd_env = {
          JAVA_OPTS = "-Djdk.xml.totalEntitySizeLimit=0 -Djdk.xml.entityExpansionLimit=0",
        },
        settings = {
          ltex = {
            language = "en-US",
            enabled = { "markdown" },
            checkFrequency = "save",
            diagnosticSeverity = {
              default = "information",
              MORFOLOGIK_RULE_EN_US = "warning",
            },
          },
        },
      }

      -- Enable LSP Servers
      vim.lsp.enable({ "clangd", "pyright", "ltex" })

      -- Diagnostic Configuration
      vim.diagnostic.config({
        virtual_text = false,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.INFO] = "",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })
    end,
  },

  -- nvim-cmp: Autocompletion Engine
  {
    "hrsh7th/nvim-cmp",
    lazy = false,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        enabled = function()
          return vim.bo.filetype ~= "markdown"
        end,
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
        formatting = {
          format = function(entry, vim_item)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
    end,
  },

  -- LuaSnip: Snippet Engine
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
  },
}
