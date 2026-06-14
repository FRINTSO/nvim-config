return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      local mypy_args = {
        '--show-column-numbers',
        '--show-error-end',
        '--hide-error-context',
        '--no-color-output',
        '--no-error-summary',
        '--output=json',
      }
      local venv = os.getenv 'VIRTUAL_ENV'
      if venv and vim.fn.executable(venv .. '/bin/python') == 1 then
        table.insert(mypy_args, 1, '--python-executable')
        table.insert(mypy_args, 2, venv .. '/bin/python')
      end

      lint.linters.mypy = {
        cmd = 'mypy',
        args = mypy_args,
        stdin = false,
        append_fname = true,
        stream = 'stdout',
        ignore_exitcode = true,
        parser = function(output, bufnr)
          if output == '' then
            return {}
          end
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          local diagnostics = {}
          for _, line in ipairs(vim.split(output, '\n')) do
            if line ~= '' then
              local ok, item = pcall(vim.json.decode, line)
              if ok and item and item.message then
                local item_path = item.file and vim.fn.fnamemodify(item.file, ':p') or ''
                if item_path == bufname then
                  local severity = vim.diagnostic.severity.ERROR
                  if item.severity == 'note' then
                    severity = vim.diagnostic.severity.HINT
                  elseif item.severity == 'warning' then
                    severity = vim.diagnostic.severity.WARN
                  end
                  table.insert(diagnostics, {
                    lnum = (item.line or 1) - 1,
                    end_lnum = (item.end_line or item.line or 1) - 1,
                    col = (item.column or 1) - 1,
                    end_col = (item.end_column or item.column or 1) - 1,
                    severity = severity,
                    source = 'mypy',
                    message = item.message,
                  })
                end
              end
            end
          end
          return diagnostics
        end,
      }

      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        python = { 'mypy' },
      }

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })

      -- Fast linters: run on BufEnter, BufWritePost, InsertLeave
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          if vim.bo.modifiable then
            local ft = vim.bo.filetype
            if ft ~= 'python' then
              lint.try_lint()
            end
          end
        end,
      })

      -- Slower linters (mypy): run on open and save
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
        group = lint_augroup,
        pattern = '*.py',
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
