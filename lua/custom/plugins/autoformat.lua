vim.go.tabstop = 8
vim.go.shiftwidth = 8
vim.go.expandtab = false
vim.go.colorcolumn = '80'

local reloading = false

local skip_extensions = { py = true, json = true }
local skip_filetypes = { python = true, json = true, yaml = true }

local function should_skip()
  if skip_filetypes[vim.bo.filetype] then
    return true
  end
  local name = vim.api.nvim_buf_get_name(0)
  local ext = name:match '%.(%w+)$'
  return ext and skip_extensions[ext]
end

local function to_tabs()
  if vim.bo.buftype ~= '' or reloading then
    return
  end
  if should_skip() then
    return
  end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 50, false)) do
    local spaces = line:match '^( +)[^%s]'
    if spaces then
      vim.bo.tabstop = #spaces
      vim.cmd 'silent! retab!'
      vim.bo.tabstop = 8
      vim.bo.modified = false
      return
    end
  end
end

vim.api.nvim_create_autocmd('BufReadPost', { pattern = '*', callback = to_tabs })

vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*',
  callback = function()
    if vim.bo.buftype ~= '' then
      return
    end
    if should_skip() then
      return
    end
    reloading = true
    vim.cmd 'silent! edit'
    reloading = false
    to_tabs()
  end,
})

local space_indent = vim.api.nvim_create_augroup('space-indent', { clear = true })

local function use_spaces(width)
  vim.bo.expandtab = true
  vim.bo.tabstop = width
  vim.bo.shiftwidth = width
  vim.bo.softtabstop = width
  if vim.bo.modifiable and not vim.bo.readonly then
    vim.cmd 'silent! retab'
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = space_indent,
  pattern = 'python',
  callback = function()
    use_spaces(4)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = space_indent,
  pattern = 'json',
  callback = function()
    use_spaces(2)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = space_indent,
  pattern = 'yaml',
  callback = function()
    use_spaces(4)
  end,
})

return {}
