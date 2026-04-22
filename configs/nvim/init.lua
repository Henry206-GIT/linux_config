-- ==========================================================================
-- init.lua - Optimierte Neovim-Konfiguration
-- ==========================================================================

-- 1. PERFORMANCE & LOADER
vim.loader.enable()
if jit and jit.opt then
  jit.opt.start('loopunroll=45')
  jit.opt.start('sizemcode=64')
  jit.opt.start('maxmcode=4096')
end

-- 2. GRUNDLEGENDE OPTIONEN
vim.g.mapleader = " "
vim.o.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.updatetime = 100
vim.opt.timeoutlen = 500
vim.opt.history = 100

-- Backup & Undo
vim.opt.swapfile = true
vim.opt.undofile = true
vim.opt.backup = true
vim.opt.backupdir = vim.fn.stdpath('state') .. '/backup//'
vim.opt.directory = vim.fn.stdpath('state') .. '/swap//'
vim.opt.undodir = vim.fn.stdpath('state') .. '/undo//'

-- 3. INTERFACE & LOOK
vim.wo.number = true
vim.wo.relativenumber = true
vim.opt.lazyredraw = false -- Auf False gesetzt, da es in modernen Neovim-Versionen oft zu Glitches führt
vim.opt.synmaxcol = 240
vim.opt.colorcolumn = "100"
vim.opt.list = true -- Zeigt unsichtbare Zeichen (optional)

-- 4. ZEILENUMBRUCH-LOGIK (DIE "GARANTIERT" FUNKTIONIERT)
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.textwidth = 100

-- Funktion zum Erzwingen der Wrap-Einstellungen
local function apply_wrap_settings()
  -- t: auto-wrap text, c: auto-wrap comments
  -- WICHTIG: Kein 'l' (verhindert Umbruch) und kein 'o' (macht oft Probleme)
  vim.opt_local.formatoptions = "tcrqnj"
  vim.opt_local.textwidth = 100
  vim.opt_local.wrap = true
  vim.opt_local.colorcolumn = "100"
end

local wrap_group = vim.api.nvim_create_augroup("HardWrap", { clear = true })

-- Überall anwenden, wenn ein Buffer geöffnet wird
vim.api.nvim_create_autocmd({"BufEnter", "FileType"}, {
  group = wrap_group,
  pattern = "*",
  callback = apply_wrap_settings,
})

-- Speziell nochmal nach LSP-Start erzwingen (LSPs überschreiben das oft!)
vim.api.nvim_create_autocmd("LspAttach", {
  group = wrap_group,
  callback = function(args)
    apply_wrap_settings()
  end,
})

-- 5. PLUGIN MANAGER (lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- 6. CUSTOM COMMANDS & LSP TOOLS
-- Custom :LspInfo
vim.api.nvim_create_user_command("LspInfo", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local lines = {}
  if #clients == 0 then
    table.insert(lines, "No LSP clients attached")
  else
    for _, client in ipairs(clients) do
      table.insert(lines, string.format("Client: %s (id %d)", client.name, client.id))
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, {})

-- Custom :LspRestart
vim.api.nvim_create_user_command("LspRestart", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(clients) do
    vim.lsp.stop_client(client.id)
  end
  vim.defer_fn(function()
    vim.cmd("edit!")
    vim.notify("LSP restarted", vim.log.levels.INFO)
  end, 500)
end, {})

-- Dynamische Breite setzen: :Width 100
vim.api.nvim_create_user_command("Width", function(opts)
  local width = tonumber(opts.args)
  if width then
    vim.opt_local.textwidth = width
    vim.opt_local.colorcolumn = tostring(width)
    vim.opt_local.formatoptions = "tcrqnj"
    print("Breite auf " .. width .. " gesetzt.")
  end
end, { nargs = 1 })

-- Debug: :WidthCheck
vim.api.nvim_create_user_command("WidthCheck", function()
  print(string.format("textwidth=%d, formatoptions=%s, colorcolumn=%s",
    vim.bo.textwidth, vim.bo.formatoptions, vim.wo.colorcolumn))
end, {})

-- LTeX Toggle: :LtexToggle
vim.api.nvim_create_user_command("LtexToggle", function()
  local clients = vim.lsp.get_clients({ name = "ltex" })
  if #clients > 0 then
    -- ltex läuft, stoppen
    for _, client in ipairs(clients) do
      vim.lsp.stop_client(client.id)
    end
    vim.notify("LTeX deaktiviert", vim.log.levels.INFO)
  else
    -- ltex läuft nicht, starten
    vim.lsp.start({ name = "ltex" })
    vim.notify("LTeX aktiviert", vim.log.levels.INFO)
  end
end, {})

-- 7. KEYBINDINGS FÜR ZEILENUMBRUCH
-- Leader+b = Aktuelle Zeile umbrechen
vim.keymap.set("n", "<leader>b", "gqgq", { desc = "Aktuelle Zeile umbrechen" })
-- Leader+B = Ganzen Paragraph umbrechen
vim.keymap.set("n", "<leader>B", "gqap", { desc = "Paragraph umbrechen" })
-- Im Visual Mode: Leader+b = Markierung umbrechen
vim.keymap.set("v", "<leader>b", "gq", { desc = "Markierung umbrechen" })

-- 8. PERFORMANCE MESSUNG
local start_time = vim.fn.reltime()
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    local end_time = vim.fn.reltime(start_time)
    print(string.format("Neovim gestartet in %.3f s", vim.fn.reltimefloat(end_time)))
  end,
})
