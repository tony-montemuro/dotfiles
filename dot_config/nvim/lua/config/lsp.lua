-- Enable LSP servers
vim.lsp.enable({
    'lua',
    'go',
    'typescript',
    'svelte',
    'tailwindcss',
    'css'
})

-- Autocommand that enables features based on LSP client capabilities
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        -- Keybinds
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition)

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

        local f = io.open("/tmp/save.txt", "w")
        f:write(client.name)
        f:close()

        -- JS/TS formatting settings
        if client ~= nil and client.name == "typescript" then
            local filetype = vim.bo.filetype
            local format_settings = { convertTabsToSpaces = true, indentStyle = 'Smart' }

            local indentSize = 4
            if filetype:match("react") ~= nil then
                indentSize = 2
                format_settings.insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces = true
            end
            format_settings.indentSize = indentSize

            local settings = {}
            if filetype:match("typescript") then
                settings = { typescript = { format = format_settings } }
            else
                settings = { javascript = { format = format_settings } }
            end

            client.notify("workspace/didChangeConfiguration", { settings = settings })
        end
    end
})

-- Useful for autocomplete
vim.cmd('set completeopt+=noselect')

-- Enable virtual text
vim.diagnostic.config({ virtual_lines = { current_line = true } })
