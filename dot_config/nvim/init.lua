require("config.lazy")

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

-- Enable LSP servers
vim.lsp.enable({ 'lua' })

-- Autocommand that enables features based on LSP client capabilities
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        -- Enable auto completion, if possible
        if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        end

        -- Format the current buffer on save
        if client:supports_method('textDocument/formatting') then
            vim.api.nvim_create_autocmd('BufWritePre', {
                callback = function()
                    vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
                end
            })
        end
    end
})

-- Useful for autocomplete
vim.cmd('set completeopt+=noselect')
