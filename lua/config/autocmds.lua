vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'gitcommit', 'markdown', 'dosini' },
  callback = function()
    vim.bo.textwidth = 72
    vim.wo.colorcolumn = '72'
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'cpp' },
  callback = function()
    vim.bo.expandtab = false
    vim.bo.tabstop = 8
    vim.bo.shiftwidth = 8
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'py', 'pyi', 'python' },
  callback = function ()
    vim.wo.colorcolumn = '88'
  end
})
