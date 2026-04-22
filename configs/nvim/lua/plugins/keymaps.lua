-- lua/config/keymaps.lua
-- Keybinding-Konfigurationen

-- Verbesserte Keymapping-Funktion
local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then options = vim.tbl_extend("force", options, opts) end
  vim.keymap.set(mode, lhs, rhs, options)  -- <-- rhs war hier vergessen!
end

-- Basis-Keymaps
map('n', '<leader>w', ':w!<CR>')
map('v', '<leader>w', ':w!<CR>')
map('n', 'qq', ':wq<CR>')
map('v', '<leader>q', ':wq<CR>')
map('n', ',', '3j')
map('n', 'o', '3k')
map('n', 'c', 'ciw')
map('i', 'jj', '<Esc>')
map('v', 'jj', '<Esc>')

-- Benutzerdefinierte Bewegungen
map('n', 'j', 'h')
map('n', 'k', 'j')
map('n', 'l', 'k')
map('n', ';', 'l')
map('v', 'j', 'h')
map('v', 'k', 'j')
map('v', 'l', 'k')
map('v', ';', 'l')

map('n', 'ä', ':')
map('n', '<Space>n', ':bp<CR>')
map('n', 's', 'i')
map('n', 'i', 's')
map('n', 's', 'a')
map('n', 'a', 'i')
map('n', '<Space>a', '0')
map('n', '<Space>s', '$')
map("n", "<leader>pv", vim.cmd.Ex)
map('n', '<C-a>', 'ggVG')
map('n', '<Esc><Esc>', ':bufdo w | bd | qa!<CR>')

-- ============================================
-- C-Funktions-Auswahl Hotkeys (NEU)
-- ============================================

-- Im Normal Mode: Direkt C-Funktion auswählen
map('n', '<leader>vf', 'vaf', { desc = "Visual select whole function" })
map('n', '<leader>vi', 'vif', { desc = "Visual select function body" })

-- Im Visual Mode: Auswahl erweitern auf C-Funktion
map('v', '<leader>f', 'af', { desc = "Extend to whole function" })
map('v', '<leader>i', 'if', { desc = "Extend to function body" })

-- Bonus: Schnelle Kombinationen
map('n', '<leader>df', 'daf', { desc = "Delete whole function" })
map('n', '<leader>yf', 'yaf', { desc = "Yank whole function" })

-- Return empty table for lazy.nvim
return {}
