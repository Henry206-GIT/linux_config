-- text_replace_functions.lua
-- Funktion zum Ersetzen des aktuellen Wortes
function _G.replace_word(new_word)
    local current_word = vim.fn.expand('<cword>')
    vim.api.nvim_command('normal! ciw' .. new_word)
end

-- Funktion zum Ersetzen im visuellen Modus mit Prompt
function _G.EnterReplaceModeVisualWithPrompt()
  -- Eingabeaufforderung für das zu ersetzende Zeichen
  local char_to_replace = vim.fn.input("old: ")
  if char_to_replace == "" then return end
  
  -- Eingabeaufforderung für das neue Zeichen
  local replace_with = vim.fn.input("new: ")
  if replace_with == "" then return end
  
  -- Ersetzen im ausgewählten Bereich
  vim.cmd(string.format("'<,'>s/%s/%s/g", vim.fn.escape(char_to_replace, '/\\'), vim.fn.escape(replace_with, '/\\')))
  
  -- Hervorhebung deaktivieren (ersetzt :noh)
  vim.cmd('nohlsearch')
  
  -- Verlasse den visuellen Modus
  vim.cmd('normal! `>')
  vim.cmd('normal! v')
end

-- Befehl, der die replace_word Funktion aufruft, mit einem Argument
vim.api.nvim_create_user_command('Rpw', function(input)
    _G.replace_word(input.args)
end, {nargs = 1})

-- Tastenkombinationen zuweisen
vim.api.nvim_set_keymap('n', '<Space>r', ':Rpw ', {noremap = true})
vim.api.nvim_set_keymap('v', '<Space>e', ':lua _G.EnterReplaceModeVisualWithPrompt()<CR>', {noremap = true, silent = true})

-- Optional: Rückgabe eines leeren Tabellenobjekts, falls Sie in Zukunft Funktionen exportieren möchten
return {}
