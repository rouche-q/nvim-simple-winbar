local M = {}
M.buffers = {}

vim.cmd([[
  hi! link SimpleWinbarActive TabLineSel
  hi! link SimpleWinbarInactive TabLine
]])

local function ensure_window(win)
  if not M.buffers[win] then
    M.buffers[win] = {}
  end
end

local function add_buffer(win, buf)
  ensure_window(win)
  for _, b in ipairs(M.buffers[win]) do
    if b == buf then return end
  end
  table.insert(M.buffers[win], buf)
end

local function make_click_handler(win, buf)
  return function()
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_set_current_buf(buf)
    end
  end
end

function M.render()
  local win = vim.api.nvim_get_current_win()
  local current = vim.api.nvim_get_current_buf()
  ensure_window(win)

  local parts = {}
  local total = #M.buffers[win]

  for i, buf in ipairs(M.buffers[win]) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
      if name == "" then name = "[No Name]" end

      local func_name = "simple_winbar_click_" .. win .. "_" .. buf
      _G[func_name] = make_click_handler(win, buf)

      local click = string.format("%%@v:lua.%s@%s%%X", func_name, name)

      local label
      if buf == current then
        label = "%#SimpleWinbarActive# " .. click
      else
        label = "%#SimpleWinbarInactive# " .. click
      end

      table.insert(parts, label)

      if i < total then
        table.insert(parts, " ")
      else
        table.insert(parts, " %#Normal#")
      end
    end
  end

  return table.concat(parts, "")
end

function M.setup()
  vim.o.winbar = "%{%v:lua.require'simple_winbar'.render()%}"

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "BufAdd" }, {
    callback = function(args)
      local win = vim.api.nvim_get_current_win()
      add_buffer(win, args.buf)
      vim.cmd("redrawstatus")
    end,
  })
end

return M
