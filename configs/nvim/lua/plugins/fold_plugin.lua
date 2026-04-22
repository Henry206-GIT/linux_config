-- lua/config/plugins/ui.lua
-- UI und Interface-Plugins

return {
  -- Performance-Optimierung: impatient.nvim für Lua-Modul-Caching
  {
    "lewis6991/impatient.nvim",
    priority = 1500,
    config = function()
      require('impatient')
    end
  },

  -- Folding Plugin
  {
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async",
      {
        "luukvbaal/statuscol.nvim",
        config = function()
          local builtin = require("statuscol.builtin")
          require("statuscol").setup({
            relculright = true,
            segments = {
              { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
              { text = { "%s" }, click = "v:lua.ScSa" },
              { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
            },
          })
        end,
      },
    },
    event = "BufReadPost",
    opts = {
      provider_selector = function(bufnr, filetype, buftype)
        return { "treesitter", "indent" }
      end,
    },
    init = function()
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      
      -- Speichere nur Folds in Views
      vim.o.viewoptions = "folds,cursor"
      
      -- Autocmds für automatisches Speichern/Laden von Folds
      local view_group = vim.api.nvim_create_augroup("AutoSaveFolds", { clear = true })
      
      -- Speichere View beim Verlassen des Buffers (nicht beim Speichern!)
      vim.api.nvim_create_autocmd("BufWinLeave", {
        group = view_group,
        pattern = "*.*",
        callback = function()
          if vim.bo.filetype ~= "" and vim.fn.expand("%") ~= "" then
            vim.cmd("silent! mkview")
          end
        end,
      })
      
      -- Lade View beim Öffnen des Buffers
      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = view_group,
        pattern = "*.*",
        callback = function()
          if vim.bo.filetype ~= "" and vim.fn.expand("%") ~= "" then
            vim.cmd("silent! loadview")
            -- Nach dem Laden: wenn noch keine manuellen Folds gesetzt wurden,
            -- öffne alle Folds
            vim.schedule(function()
              if vim.wo.foldlevel == 0 then
                vim.wo.foldlevel = 99
              end
            end)
          end
        end,
      })
    end,
    config = function(_, opts)
      local handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local totalLines = endLnum - lnum
        local suffix = (" 󰁂 %d"):format(totalLines)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end

      opts["fold_virt_text_handler"] = handler
      require("ufo").setup(opts)
      vim.keymap.set("n", "zR", require("ufo").openAllFolds)
      vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
      vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
      vim.keymap.set("n", "ff", "za", { desc = 'Toggle fold' })
      vim.keymap.set("n", "K", function()
        local winid = require("ufo").peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end)
    end,
  },
}
