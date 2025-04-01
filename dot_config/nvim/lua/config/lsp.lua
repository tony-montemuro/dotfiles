-- Enable LSP servers
vim.lsp.enable({
    'lua',
    'go'
})

-- Autocommand that enables features based on LSP client capabilities
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        -- Format the current buffer on save
        if client:supports_method('textDocument/formatting') then
            vim.api.nvim_create_autocmd('BufWritePre', {
                callback = function()
                    if vim.bo.filetype ~= "go" then
                        vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf(), id = client.id })
                    end
                end
            })
        end

        -- Go config to have imports organized on save using the logic of `goimports`
        if client:supports_method('textDocument/codeAction') then
            vim.api.nvim_create_autocmd('BufWritePre', {
                pattern = '*.go',
                callback = function()
                    local params = vim.lsp.util.make_range_params()
                    params.context = { only = { 'source.organizeImports' } }
                    local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params)

                    for cid, res in pairs(result or {}) do
                        for _, r in pairs(res.result or {}) do
                            if r.edit then
                                local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
                                vim.lsp.util.apply_workspace_edit(r.edit, enc)
                            end
                        end
                    end

                    vim.lsp.buf.format({ async = false })
                end
            })
        end
    end
})

-- Useful for autocomplete
vim.cmd('set completeopt+=noselect')

-- Enable virtual text
vim.diagnostic.config({ virtual_lines = { current_line = true } })
