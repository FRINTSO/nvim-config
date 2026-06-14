local M = {}

local function detect_indent_width(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)
  local counts = {}

  for _, line in ipairs(lines) do
    local spaces = line:match '^( +)[^%s*]'
    if spaces and #spaces > 1 then
      counts[#spaces] = (counts[#spaces] or 0) + 1
    end
  end

  if vim.tbl_isempty(counts) then
    return nil
  end

  -- Find the GCD of all indent widths
  local function gcd(a, b)
    while b ~= 0 do
      a, b = b, a % b
    end
    return a
  end

  local result = nil
  for width, _ in pairs(counts) do
    result = result and gcd(result, width) or width
  end

  return result and result >= 2 and result or nil
end

local function leading_spaces_to_tabs(bufnr, space_width)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local changed = false
  for i, line in ipairs(lines) do
    local leading = line:match '^( +)'
    if leading then
      local tabs = math.floor(#leading / space_width)
      local remainder = #leading % space_width
      lines[i] = string.rep('\t', tabs) .. string.rep(' ', remainder) .. line:sub(#leading + 1)
      changed = true
    end
  end
  if changed then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end
end

local function leading_tabs_to_spaces(bufnr, space_width)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local leading = line:match '^(\t+)'
    if leading then
      lines[i] = string.rep(' ', #leading * space_width) .. line:sub(#leading + 1)
    end
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

local skip_filetypes = { yaml = true, make = true }

function M.enable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= '' then
    return
  end
  if skip_filetypes[vim.bo[bufnr].filetype] then
    return
  end

  local width = detect_indent_width(bufnr)
  if width then
    leading_spaces_to_tabs(bufnr, width)
    vim.bo[bufnr].modified = false
    vim.b[bufnr].viewmode_width = width
  elseif not vim.b[bufnr].viewmode_width then
    return
  end

  vim.bo[bufnr].expandtab = false
  vim.bo[bufnr].tabstop = 8
  vim.bo[bufnr].shiftwidth = 8
  vim.b[bufnr].viewmode = true
end

function M.disable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.bo[bufnr].modified = false
  vim.cmd 'silent! edit'
  vim.b[bufnr].viewmode = false
  vim.b[bufnr].viewmode_width = nil
end

function M.toggle()
  if vim.g.viewmode then
    vim.g.viewmode = false
    M.disable(vim.api.nvim_get_current_buf())
    print 'View: raw'
  else
    vim.g.viewmode = true
    M.enable(vim.api.nvim_get_current_buf())
    print 'View: tabs-8'
  end
end

local group = vim.api.nvim_create_augroup('viewmode', { clear = true })

vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  group = group,
  callback = function(ev)
    if vim.g.viewmode then
      M.enable(ev.buf)
    elseif vim.b[ev.buf].viewmode then
      M.disable(ev.buf)
    end
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  group = group,
  callback = function(ev)
    if vim.b[ev.buf].viewmode then
      leading_tabs_to_spaces(ev.buf, vim.b[ev.buf].viewmode_width)
    end
  end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  callback = function(ev)
    if vim.b[ev.buf].viewmode then
      leading_spaces_to_tabs(ev.buf, vim.b[ev.buf].viewmode_width)
      vim.bo[ev.buf].modified = false
    end
  end,
})

vim.keymap.set('n', '<leader>tv', M.toggle, { desc = '[T]oggle [V]iew mode' })

return {}
