-- lua/plugins/harpoon.lua
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")

    -- Harpoon2 hat keine setup() Funktion - Keymaps direkt setzen

    -- Debug: Zeigt an ob Datei hinzugefügt wurde
    vim.keymap.set("n", "<leader><BS>", function()
      local filename = vim.fn.expand("%:p")
      if filename == "" then
        vim.notify("No file to add", vim.log.levels.WARN)
        return
      end
      harpoon:list():add()
      vim.notify("Added: " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
    end, { desc = "Harpoon add" })

    vim.keymap.set("n", "<leader>e", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Harpoon menu" })

    -- Navigation
    vim.keymap.set("n", "11", function() harpoon:list():select(1) end)
    vim.keymap.set("n", "22", function() harpoon:list():select(2) end)
    vim.keymap.set("n", "33", function() harpoon:list():select(3) end)
    vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end)
  end,
}
