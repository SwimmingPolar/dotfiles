if not table.unpack then
    table.unpack = unpack
end

vim.loader.enable()

require 'utils'

vim.cmd 'colorscheme gruvluke'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system {
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable',
		lazypath,
	}
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins', {
	defaults = {
		lazy = true,
	},
	dev = {
		path = '/home/luke/src',
		fallback = false,
	},
	install = {
		colorscheme = { 'gruvluke' },
	},
	change_detection = {
		enabled = false,
	},
	ui = {
		border = 'rounded',
		backdrop = 100,
	},
	checker = {
		enabled = false,
	},
	performance = {
		rtp = {
			disabled_plugins = {
				'netrwPlugin',
				'rplugin',
				'gzip',
				'tarPlugin',
				'tohtml',
				'tutor',
				'zipPlugin',
			},
		},
	},
})

require 'filetype'
require 'options'
require 'keymap'
-- require 'tmux'
require 'autocmds'

-- source all .vimrc files
local function source_vimrc_files()
  local vimrc_dir = vim.fn.expand("./vimrc/")
  local vimrc_files = vim.fn.globpath(vimrc_dir, "*.vimrc", false, true)

  for _, file in ipairs(vimrc_files) do
    vim.cmd('source ' .. file)
  end
end

-- Call the function to source the .vimrc files
source_vimrc_files()
