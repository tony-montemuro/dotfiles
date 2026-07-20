-- Enable LSP servers
vim.lsp.enable({
    'lua',
    'go',
    'typescript',
    'svelte',
    'html',
    'tailwindcss',
    'css',
    'deno'
})

-- Format the current buffer on save. Deno projects use `deno fmt`; everything
-- else goes through the LSP formatter, explicitly excluding tailwindcss (it
-- has no formatting capability today, but keep it excluded in case that
-- changes) so typescript's formatting always wins on JS/TS buffers.
local function format_on_save(bufnr)
    local deno_attached = false
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if c.name == 'deno' then
            deno_attached = true
            break
        end
    end

    if deno_attached then
        local ext = vim.fn.expand('%:e')
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local input = table.concat(lines, '\n') .. '\n'

        local result = vim.system({ 'deno', 'fmt', '--ext', ext, '-' }, { stdin = input }):wait()

        if result.code == 0 and result.stdout and #result.stdout > 0 then
            local formatted = vim.split(result.stdout, '\n')
            if formatted[#formatted] == '' then
                table.remove(formatted) -- drop trailing blank line from split
            end
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
        else
            vim.notify('deno fmt failed:\n' .. (result.stderr or 'unknown error'), vim.log.levels.WARN)
        end
        return
    end

    vim.lsp.buf.format({
        bufnr = bufnr,
        async = false,
        filter = function(c)
            return c.name ~= 'tailwindcss'
        end,
    })
end

-- Organize Go imports (goimports behavior), then format.
local function organize_go_imports(bufnr)
    local params = vim.lsp.util.make_range_params()
    params.context = { only = { 'source.organizeImports' } }
    local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params)

    for cid, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
            if r.edit then
                local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or 'utf-16'
                vim.lsp.util.apply_workspace_edit(r.edit, enc)
            end
        end
    end

    vim.lsp.buf.format({ bufnr = bufnr, async = false })
end

-- Autocommand that enables features based on LSP client capabilities
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end
        local bufnr = args.buf

        -- Keybinds
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr })

        -- Register format-on-save exactly once per buffer, regardless of how
        -- many clients attach to it.
        if not vim.b[bufnr].lsp_format_on_save then
            vim.b[bufnr].lsp_format_on_save = true

            vim.api.nvim_create_autocmd('BufWritePre', {
                buffer = bufnr,
                callback = function()
                    if vim.bo[bufnr].filetype == 'go' then
                        organize_go_imports(bufnr)
                    else
                        format_on_save(bufnr)
                    end
                end,
            })
        end

        -- JS/TS formatting settings
        if client.name == 'typescript' then
            local filetype = vim.bo[bufnr].filetype
            local format_settings = {
                convertTabsToSpaces = true,
                indentStyle = 'Smart',
                indentSize = 2,
                tabSize = 2,
            }

            if filetype:match('react') ~= nil then
                format_settings.insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces = true
            end

            local settings
            if filetype:match('typescript') then
                settings = { typescript = { format = format_settings } }
            else
                settings = { javascript = { format = format_settings } }
            end

            client.notify('workspace/didChangeConfiguration', { settings = settings })
        end
    end
})

-- Useful for autocomplete
vim.cmd('set completeopt+=noselect')

-- Enable virtual text
vim.diagnostic.config({ virtual_lines = { current_line = true } })
