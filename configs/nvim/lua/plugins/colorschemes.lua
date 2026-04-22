-- lua/plugins/colorschemes.lua
return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    config = function()
      -- Aktiviere rose-pine mit transparentem Hintergrund
      vim.cmd([[colorscheme rose-pine]])
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      
      -- Globale Funktion zum Colorscheme-Wechsel mit transparentem Hintergrund
      _G.ColorMyPencils = function(color)
        color = color or "rose-pine"
        vim.cmd("colorscheme " .. color)
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      end
      
      -- Optional: Command zum einfachen Wechseln
      vim.api.nvim_create_user_command('ColorMyPencils', function(opts)
        _G.ColorMyPencils(opts.args)
      end, { nargs = '?' })
    end,
  },
  
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 900,
    config = function()
      require('nightfox').setup({
        options = {
          styles = {
            comments = "italic",
            keywords = "bold",
            types = "italic,bold",
          }
        }
      })
    end,
  },
}
