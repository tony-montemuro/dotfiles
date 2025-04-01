require("config.lazy")
require("config.lsp")

vim.opt.shiftwidth = 4
vim.opt.clipboard = "unnamedplus"

-- Keybinds for executing Lua from within the editor
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<leader>x", ":.lua<CR>")
vim.keymap.set("v", "<leader>x", ":lua<CR>")

-- Keybinds for quickfix
vim.keymap.set("n", "<M-j>", "<cmd>cnext<CR>")
vim.keymap.set("n", "<M-k>", "<cmd>cprev<CR>")

-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-tank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end
})
