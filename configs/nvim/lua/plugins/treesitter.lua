-- plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "markdown", "markdown_inline", "c", "lua", "vim", "vimdoc", "cpp", "cuda"},
      highlight = { enable = true },
      
      -- Textobjects für präzise Auswahl
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Springt automatisch zum nächsten Textobject
          keymaps = {
            ["af"] = "@function.outer",  -- ganze Funktion mit Signatur
            ["if"] = "@function.inner",  -- nur Funktionskörper
            ["ac"] = "@class.outer",     -- ganze Klasse/Struct
            ["ic"] = "@class.inner",     -- Klasse/Struct innen
            ["aa"] = "@parameter.outer", -- Funktionsparameter
            ["ia"] = "@parameter.inner",
          },
        },
      },
    })
  end,
}
