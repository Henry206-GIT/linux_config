-- Legen Sie Swap-Dateien in einem zentralen Verzeichnis ab
vim.opt.directory = vim.fn.stdpath('data') .. '/swp'

-- Aktivieren Sie Datei-Backups mit mehreren Versionen
vim.opt.backup = true
vim.opt.backupdir = vim.fn.stdpath('data') .. '/backup'
vim.opt.backupext = '.bak'
vim.opt.writebackup = true

-- Aktivieren Sie Undo-Dateien für persistente Undo-Historie
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath('data') .. '/undo'

-- Setzen Sie ein kürzeres Zeitlimit für Swap-Datei-Warnungen
vim.opt.updatetime = 100

-- Automatisches Speichern beim Fokusverlust, beim Verlassen des Buffers oder bei Inaktivität
vim.cmd[[
  augroup AutoSave
    autocmd!
    autocmd FocusLost,BufLeave,CursorHold,CursorHoldI * silent! wall
  augroup END
]]

-- Funktion zum Löschen alter Swap-Dateien und Backups
local function clean_old_files()
  local dirs = {
    vim.fn.stdpath('data') .. '/swp',
    vim.fn.stdpath('data') .. '/backup',
    vim.fn.stdpath('data') .. '/undo'
  }
  for _, dir in ipairs(dirs) do
    local files = vim.fn.glob(dir .. '/*', true, true)
    for _, file in ipairs(files) do
      local mod_time = vim.fn.getftime(file)
      if os.time() - mod_time > 7 * 86400 then -- älter als 7 Tage
        os.remove(file)
      end
    end
  end
end

-- Führen Sie diese Funktion beim Neovim-Start aus
clean_old_files()

-- Fügen Sie einen benutzerdefinierten Befehl hinzu, um alte Dateien manuell zu löschen
vim.api.nvim_create_user_command('CleanOldFiles', clean_old_files, {})

-- Erstellen Sie die Verzeichnisse, falls sie nicht existieren
local function ensure_dir(dir)
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

ensure_dir(vim.fn.stdpath('data') .. '/swp')
ensure_dir(vim.fn.stdpath('data') .. '/backup')
ensure_dir(vim.fn.stdpath('data') .. '/undo')

-- Aktivieren Sie Versionssteuerung für Backups
vim.opt.backupdir:append('//')

-- Setzen Sie eine maximale Anzahl von Undo-Schritten
vim.opt.undolevels = 1000

-- Deaktivieren Sie Swap-Dateien für temporäre Dateien und private Informationen
vim.cmd[[
  augroup NoSwap
    autocmd!
    autocmd BufNewFile,BufReadPre /tmp/*,/private/*,/private/tmp/* setlocal noswapfile
  augroup END
]]

-- ERWEITERT: Globale Funktionen zum Speichern von Cursor- UND Scroll-Position
_G.save_view = function()
  -- Speichere nur wenn Buffer gültig ist und einen Namen hat
  if vim.fn.expand('%') ~= '' and vim.bo.buftype == '' then
    vim.cmd('silent! mkview')
  end
end

_G.restore_view = function()
  -- Stelle View wieder her wenn vorhanden
  if vim.fn.expand('%') ~= '' and vim.bo.buftype == '' then
    vim.cmd('silent! loadview')
  end
end

-- ERWEITERT: Funktion zum Wiederherstellen von Cursor- UND Scroll-Position
vim.cmd[[
  augroup RestoreCursorAndScroll
    autocmd!
    " Speichere View beim Verlassen
    autocmd BufWinLeave,BufLeave * lua _G.save_view()
    " Stelle View beim Öffnen wieder her
    autocmd BufWinEnter * lua _G.restore_view()
  augroup END
]]

-- Alternative Methode mit manueller Scroll-Position (falls mkview Probleme macht)
-- Speichere Position in einer globalen Tabelle
_G.scroll_positions = _G.scroll_positions or {}

_G.save_scroll_position = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(winid)
  local top_line = vim.fn.line('w0')
  
  _G.scroll_positions[bufnr] = {
    cursor = cursor_pos,
    topline = top_line,
    file = vim.fn.expand('%:p')
  }
end

_G.restore_scroll_position = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = _G.scroll_positions[bufnr]
  
  if pos and pos.file == vim.fn.expand('%:p') then
    -- Stelle Cursor-Position wieder her
    vim.api.nvim_win_set_cursor(0, pos.cursor)
    -- Stelle Scroll-Position wieder her
    vim.cmd('normal! zt')
    vim.fn.winrestview({topline = pos.topline})
  end
end

-- Backup-System für Scroll-Position (läuft parallel zu mkview)
vim.cmd[[
  augroup ScrollPositionBackup
    autocmd!
    autocmd BufLeave * lua _G.save_scroll_position()
    autocmd BufEnter * lua _G.restore_scroll_position()
  augroup END
]]

-- Debug-Befehl zum Testen
vim.api.nvim_create_user_command('ShowScrollPos', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = _G.scroll_positions[bufnr]
  if pos then
    print(string.format("Cursor: [%d, %d], TopLine: %d", pos.cursor[1], pos.cursor[2], pos.topline))
  else
    print("Keine gespeicherte Position für diesen Buffer")
  end
end, {})

-- Return empty table for lazy.nvim
return {}
