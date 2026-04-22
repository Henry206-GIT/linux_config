-- Grundeinstellungen für den Editor
vim.opt.number = true                    -- Zeilennummern anzeigen
vim.opt.relativenumber = true            -- Relative Zeilennummern
vim.opt.wrap = false                     -- Keine Zeilenumbrüche
vim.opt.tabstop = 4                      -- Tabulatorbreite
vim.opt.shiftwidth = 4                   -- Einrückungsbreite
vim.opt.expandtab = true                 -- Tabs in Leerzeichen umwandeln
vim.opt.smartindent = true               -- Intelligentes Einrücken
vim.opt.termguicolors = true             -- Aktiviert 24-Bit RGB Farben
vim.opt.clipboard = 'unnamedplus'        -- Systemzwischenablage verwenden

-- Funktion zum Hervorheben von Text nach // in Rot
function HighlightComments()
    vim.cmd([[highlight CommentHighlight guifg=#FF0000 ctermfg=red gui=none cterm=none]])
    vim.cmd([[match CommentHighlight /\/\/.*$/]])
end

-- Autokommando, um die Funktion NUR für .md Dateien anzuwenden
vim.cmd([[
    augroup HighlightComments
        autocmd!
        autocmd BufReadPost,BufWritePost,TextChanged,TextChangedI *.md lua HighlightComments()
    augroup END
]])

-- Syntax-Hervorhebung aktivieren
vim.cmd('syntax on')

-- Benutzerdefinierte Syntax-Hervorhebung für .md Dateien
vim.cmd([[
    augroup markdown_syntax
        autocmd!
        autocmd BufRead,BufNewFile *.md set syntax=markdown
    augroup END
]])

-- Ersetze Ö durch < und Ä durch > beim Tippen
vim.api.nvim_create_autocmd("InsertCharPre", {
    callback = function()
        local char = vim.v.char
        if char == "Ö" then
            vim.v.char = "<"
        elseif char == "Ä" then
            vim.v.char = ">"
        end
    end,
})

-- Allgemeine Tastenbelegungen
vim.g.mapleader = " "                    -- Leertaste als Leader-Taste

-- Grundlegende Mappings
vim.keymap.set('n', '<leader>w', ':w<CR>')           -- Speichern
vim.keymap.set('n', '<leader>q', ':q<CR>')           -- Beenden
vim.keymap.set('n', '<leader>x', ':x<CR>')           -- Speichern und Beenden

-- Navigations-Mappings
vim.keymap.set('n', '<C-h>', '<C-w>h')               -- Fenster links
vim.keymap.set('n', '<C-j>', '<C-w>j')               -- Fenster unten
vim.keymap.set('n', '<C-k>', '<C-w>k')               -- Fenster oben
vim.keymap.set('n', '<C-l>', '<C-w>l')               -- Fenster rechts

-- Buffer-Management
vim.keymap.set('n', '<leader>bn', ':bnext<CR>')      -- Nächster Buffer
vim.keymap.set('n', '<leader>bp', ':bprevious<CR>')  -- Vorheriger Buffer
vim.keymap.set('n', '<leader>bd', ':bdelete<CR>')    -- Buffer löschen

-- Suchen und Ersetzen
vim.keymap.set('n', '<leader>r', ':%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>')
vim.keymap.set('n', '<leader>s', ':set hlsearch!<CR>') -- Suchhervorhebung umschalten

-- Dateibrowser-Einstellungen (wenn netrw verwendet wird)
vim.g.netrw_banner = 0                   -- Banner ausblenden
vim.g.netrw_liststyle = 3                -- Baumansicht
vim.g.netrw_browse_split = 4             -- Öffnen in vorherigem Fenster
vim.g.netrw_altv = 1                     -- Splits rechts öffnen
vim.g.netrw_winsize = 25                 -- Breite des Explorers

-- Highlighting von Leerzeichen am Zeilenende entfernen
vim.cmd([[
    augroup remove_trailing_whitespace
        autocmd!
    augroup END
]])

-- Return empty table for lazy.nvim
return {}
