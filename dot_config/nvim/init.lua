require("config.lazy")

vim.opt.tabstop = 4
vim.opt.softtabstop = 0
vim.opt.expandtab = false
vim.opt.shiftwidth = 4
vim.opt.clipboard = "unnamedplus"

-- Keybinds for executing Lua from within the editor
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", ":.lua<CR>")
vim.keymap.set("v", "<space>x", ":lua<CR>")

-- Keybinds for LSP
vim.keymap.set("n", "grr", vim.lsp.buf.references)
vim.keymap.set("n", "gra", vim.lsp.buf.code_action)
vim.keymap.set("n", "grn", vim.lsp.buf.rename)

-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = vim.api.nvim_create_augroup('kickstart-highlight-tank', { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end
})

