-- Define once, globally accessible
local function ColorMyPencils()
  -- clear background
  vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
end

-- Sets colors to line numbers Above, Current and Below  in this order
function LineNumberColors()
  vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#A0A0A0', bold = true })
  vim.api.nvim_set_hl(0, 'LineNr', { fg = 'white', bold = true })
  vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#A0A0A0', bold = true })
end

return {
  {
    'folke/tokyonight.nvim',
    config = function()
      require('tokyonight').setup {
        style = 'storm',
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = false },
          keywords = { italic = false },
          sidebars = 'dark',
          floats = 'dark',
        },
      }
      vim.cmd 'colorscheme tokyonight'
      ColorMyPencils()
    end,
  },

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    config = function()
      require('catppuccin').setup {
        transparent_background = true, -- correct option name
      }
      vim.cmd 'colorscheme catppuccin'
      ColorMyPencils()
    end,
  },
}
