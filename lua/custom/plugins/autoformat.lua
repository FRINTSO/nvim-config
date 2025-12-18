vim.opt.tabstop = 8
vim.opt.shiftwidth = 8
vim.opt.expandtab = false
vim.opt.colorcolumn = '80'

local reloading = false

local function to_tabs()
  if vim.bo.buftype ~= '' or reloading then return end
  for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, 50, false)) do
    local s = l:match '^( +)[^%s]'
    if s then
      vim.bo.tabstop = #s
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
    if vim.bo.buftype ~= '' then return end
    reloading = true
    vim.cmd 'silent! edit'  -- reload formatter's output from disk
    reloading = false
    to_tabs()
  end,
})

return {}
