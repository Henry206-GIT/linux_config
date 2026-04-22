-- lua/plugins/telescope.lua
return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Telescope",  -- Lazy loading: lädt nur bei :Telescope Befehl
  keys = {
    { "<Space>f", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Fuzzy find in buffer" },
    { "<Space>d", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<Space>o", "<cmd>lua BrowseFolders()<CR>", desc = "Browse folders" },
  },
  config = function()
    local actions = require('telescope.actions')
    
    require('telescope').setup({
      defaults = {
        mappings = {
          i = {
            ["<esc>"] = actions.close
          },
        },
      },
    })
    
    -- Globale Funktion für Ordner-Browsing
    _G.BrowseFolders = function()
      require('telescope.builtin').find_files({
        find_command = {'find', '.', '-type', 'd'}
      })
    end
  end,
}
