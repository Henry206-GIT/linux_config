-- lua/plugins/markdown_custom.lua
-- Markdown custom highlighting for blocks and tables

local function setup_markdown_highlighting()
  local ns_id = vim.api.nvim_create_namespace("markdown_blocks")
  
  -- Highlight-Gruppen für Blöcke
  vim.api.nvim_set_hl(0, "MdBoxedBlock", {
    fg = "#d09ee8",      -- Grün
    bg = "#2C323C",      -- Dunkler Hintergrund  
    bold = true
  })
  
  vim.api.nvim_set_hl(0, "MdDividerLine", {
    fg = "#61AFEF",      -- Blau
    bold = true
  })
  
  -- Highlight-Gruppen für Tabellen
  vim.api.nvim_set_hl(0, "MdTableHeader", {
    fg = "#E5C07B",      -- Gold/Gelb
    bg = "#2C323C",
    bold = true
  })
  
  vim.api.nvim_set_hl(0, "MdTableSeparator", {
    fg = "#61AFEF",      -- Blau
    bold = true
  })
  
  vim.api.nvim_set_hl(0, "MdTableRow", {
    fg = "#ABB2BF",      -- Helles Grau
    bg = "#23272E"       -- Leicht dunklerer Hintergrund
  })
  
  vim.api.nvim_set_hl(0, "MdTableBorder", {
    fg = "#56B6C2",      -- Cyan
  })
  
  local function is_table_line(line)
    -- Prüft, ob eine Zeile Teil einer Markdown-Tabelle ist
    return line:match("^%s*|.*|%s*$") ~= nil
  end
  
  local function is_separator_line(line)
    -- Prüft, ob es eine Tabellen-Trennlinie ist (z.B. | --- | --- |)
    return line:match("^%s*|[%s%-:]+|[%s%-:|]*$") ~= nil
  end
  
  local function highlight_table_line(bufnr, line_num, line, is_header, is_separator)
    local line_idx = line_num - 1
    
    if is_separator then
      -- Trennlinie komplett highlighten
      vim.api.nvim_buf_add_highlight(
        bufnr, ns_id, "MdTableSeparator", line_idx, 0, -1
      )
    else
      -- Zeile nach Zellen aufteilen und highlighten
      local hl_group = is_header and "MdTableHeader" or "MdTableRow"
      local pos = 0
      
      for i = 1, #line do
        local char = line:sub(i, i)
        if char == "|" then
          -- Pipe-Zeichen als Border highlighten
          vim.api.nvim_buf_add_highlight(
            bufnr, ns_id, "MdTableBorder", line_idx, i - 1, i
          )
        elseif pos < i - 1 then
          -- Text zwischen Pipes highlighten
          local next_pipe = line:find("|", i + 1) or (#line + 1)
          if next_pipe > i then
            vim.api.nvim_buf_add_highlight(
              bufnr, ns_id, hl_group, line_idx, pos, next_pipe - 1
            )
            pos = next_pipe - 1
          end
        end
      end
    end
  end
  
  local function highlight_blocks()
    local bufnr = vim.api.nvim_get_current_buf()
    
    -- Nur für Markdown
    if vim.bo.filetype ~= "markdown" then return end
    
    -- Alte Highlights löschen
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local in_block = false
    local start_line = nil
    local in_table = false
    local table_start = nil
    local has_separator = false
    
    for i, line in ipairs(lines) do
      local is_divider = line:match("^%-%-%-%-%-%-%-%-%-%-%-+$")
      local is_tbl_line = is_table_line(line)
      local is_sep_line = is_separator_line(line)
      
      -- Divider-Block-Logik (unverändert)
      if is_divider then
        vim.api.nvim_buf_add_highlight(
          bufnr, ns_id, "MdDividerLine", i - 1, 0, -1
        )
        
        if not in_block then
          in_block = true
          start_line = i
        else
          for j = start_line + 1, i - 2 do
            vim.api.nvim_buf_add_highlight(
              bufnr, ns_id, "MdBoxedBlock", j, 0, -1
            )
          end
          in_block = false
        end
      end
      
      -- Tabellen-Logik
      if is_tbl_line then
        if not in_table then
          -- Neue Tabelle beginnt
          in_table = true
          table_start = i
          has_separator = false
        end
        
        if is_sep_line then
          has_separator = true
          highlight_table_line(bufnr, i, line, false, true)
        else
          -- Header wenn vor Separator, sonst normale Zeile
          local is_header = has_separator == false and table_start == i
          highlight_table_line(bufnr, i, line, is_header, false)
        end
      else
        -- Tabelle endet
        if in_table then
          in_table = false
          table_start = nil
          has_separator = false
        end
      end
    end
  end
  
  -- Bei verschiedenen Events aktualisieren
  vim.api.nvim_create_autocmd({
    "BufEnter", "BufWritePost", "TextChanged", "TextChangedI", "InsertLeave"
  }, {
    pattern = "*.md",
    callback = highlight_blocks,
  })
end

-- Setup direkt ausführen
setup_markdown_highlighting()

-- Return empty table for lazy.nvim
return {}
