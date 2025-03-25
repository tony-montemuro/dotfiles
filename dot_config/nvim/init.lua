require("config.lazy")

vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=0 noexpandtab")
vim.cmd("set shiftwidth=4")

-- Keybinds for executing Lua from within the editor
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", ":.lua<CR>")
vim.keymap.set("v", "<space>x", ":lua<CR>")

-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = vim.api.nvim_create_augroup('kickstart-highlight-tank', { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end
})
