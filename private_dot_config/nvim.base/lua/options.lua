local api = vim.api

function WinbarContent()
	local alignment = '%='
	local filename = '%f'
	local modifiers = '[%M%R%H%W] '
	local expanded_filename = api.nvim_eval_statusline(filename, { use_winbar = true })
	local expanded_modifiers = api.nvim_eval_statusline(modifiers, { use_winbar = true })
	if expanded_modifiers.width <= 3 then
		return alignment .. expanded_filename.str
	end
	return alignment .. expanded_modifiers.str .. expanded_filename.str
end

-- Set leader key to space
vim.g.mapleader = ' '

-- Disable Python3 provider
vim.g.loaded_python3_provider = 0
-- Disable Ruby provider
vim.g.loaded_ruby_provider = 0
-- Disable Perl provider
vim.g.loaded_perl_provider = 0
-- Disable Node provider
vim.g.loaded_node_provider = 0

-- Enable true color support
vim.opt.termguicolors = true
-- Enable syntax highlighting
vim.opt.syntax = 'on'
-- Set the number of spaces that a <Tab> in the file counts for
vim.opt.tabstop = 2
-- Use the value of 'tabstop' for the number of spaces to use for each step of (auto)indent
vim.opt.shiftwidth = 0
-- Enable automatic indentation
vim.opt.autoindent = true
-- Enable smart indentation
vim.opt.smartindent = true
-- Automatically read a file when it is changed from outside of Vim
vim.opt.autoread = true
-- Configure backspace behavior to be more intuitive
vim.opt.backspace = { 'indent', 'eol', 'start' }
-- Disable bell sound for certain actions
vim.opt.belloff = { 'cursor', 'esc' }
-- Enable break indent
vim.opt.breakindent = true
-- Show confirmation dialog when closing an unsaved file
vim.opt.confirm = true
-- Set the command-line height to zero
vim.opt.cmdheight = 0
-- Ignore case in search patterns
vim.opt.ignorecase = true
-- Command-line completion mode
vim.opt.wildmode = { 'longest', 'list', 'lastused' }
-- Disable line wrapping
vim.opt.wrap = false
-- Show the filename in the window title
vim.opt.title = true
-- Highlight the screen line of the cursor with CursorLine
vim.opt.cursorline = true
-- Highlight only the number column
vim.opt.cursorlineopt = 'number'
-- Show line numbers
vim.opt.number = true
-- Enable mouse support in all modes
vim.opt.mouse = 'a'
-- Set mouse model to 'extend'
vim.opt.mousemodel = 'extend'
-- Show some invisible characters
vim.opt.list = true
-- Specify which characters to show for various whitespace characters
vim.opt.listchars = { tab = '> ', trail = '-', nbsp = '+', lead = '·' }
-- Automatically set the sign column width
vim.opt.signcolumn = 'auto'
-- Automatically set the fold column width
vim.opt.foldcolumn = 'auto'
-- Set folding method to 'expr'
vim.opt.foldmethod = 'expr'
-- Set folding expression to use Tree-sitter
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
-- Disable folding by default
vim.opt.foldenable = false
-- Set the window bar content
vim.opt.winbar = '%{%v:lua.WinbarContent()%}'
-- Do not add a newline at the end of the file
vim.opt.fixendofline = false
-- Disable search highlighting
vim.opt.hlsearch = false
-- Set the cursor shape to block in all modes
vim.opt.guicursor = 'a:block'
-- Enable persistent undo
vim.opt.undofile = true
-- Set maximum text width for formatting
vim.opt.textwidth = 88
-- Keep the window position unchanged on split
vim.opt.splitkeep = 'screen'
-- Optimize for redrawing
vim.opt.lazyredraw = true
-- Enable line breaking
vim.opt.linebreak = true
-- Set the minimum number of screen lines to keep above and below the cursor
vim.opt.scrolloff = 0
-- Configure format options
vim.opt.formatoptions = 'croqlj'
-- Set the command-line history size
vim.opt.history = 10000
-- Enable the window title
vim.opt.title = true
-- Set the title string
vim.opt.titlestring = '%t'
