-- Enable LSP servers
vim.lsp.enable({
    'lua',
    'go',
    'c',
    'typescript',
    'svelte',
    'html',
    'tailwindcss',
    'css',
    'deno'
})

local prettier_filetypes = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'vue',
    'svelte',
    'css',
    'scss',
    'less',
    'html',
    'json',
    'jsonc',
    'json5',
    'yaml',
    'markdown',
    'markdown.mdx',
    'graphql',
    'handlebars',
}

local prettier_config_files = {
    '.prettierrc',
    '.prettierrc.json',
    '.prettierrc.yml',
    '.prettierrc.yaml',
    '.prettierrc.json5',
    '.prettierrc.js',
    '.prettierrc.mjs',
    '.prettierrc.cjs',
    '.prettierrc.ts',
    '.prettierrc.mts',
    '.prettierrc.cts',
    '.prettierrc.toml',
    'prettier.config.js',
    'prettier.config.mjs',
    'prettier.config.cjs',
    'prettier.config.ts',
    'prettier.config.mts',
    'prettier.config.cts',
}

-- Mirror Prettier's own config lookup: walk up from the file, nearest config
-- wins, and a `package.json` only counts when it actually carries a `prettier`
-- key. Returns the directory holding the config, which becomes Prettier's cwd
-- so that plugins resolve the same way the project's own CLI would resolve
-- them.
local function find_prettier_root(path)
    for dir in vim.fs.parents(path) do
        for _, name in ipairs(prettier_config_files) do
            if vim.uv.fs_stat(vim.fs.joinpath(dir, name)) then
                return dir
            end
        end

        local package_json = vim.fs.joinpath(dir, 'package.json')
        if vim.uv.fs_stat(package_json) then
            local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), '\n'))
            if ok and type(decoded) == 'table' and decoded.prettier ~= nil then
                return dir
            end
        end
    end
end

-- Prefer the project's own Prettier over anything global, the same way
-- `lsp/typescript.lua` prefers a local typescript-language-server. This pins
-- us to the version and plugins the project actually declares.
local function find_prettier_bin(path)
    for dir in vim.fs.parents(path) do
        local bin = vim.fs.joinpath(dir, 'node_modules', '.bin', 'prettier')
        if vim.fn.executable(bin) == 1 then
            return bin
        end
    end
end

-- Resolve (and cache per buffer) the Prettier invocation for a buffer, or nil
-- when this buffer should be formatted some other way. The lookup touches the
-- filesystem, so it runs once per buffer rather than once per write; clear
-- `b:prettier_checked` to force a re-resolve after installing dependencies.
local function resolve_prettier(bufnr)
    if not vim.b[bufnr].prettier_checked then
        vim.b[bufnr].prettier_checked = true

        local path = vim.api.nvim_buf_get_name(bufnr)
        if path ~= '' and vim.tbl_contains(prettier_filetypes, vim.bo[bufnr].filetype) then
            local root = find_prettier_root(path)
            if root then
                local cmd = find_prettier_bin(path)
                if cmd then
                    vim.b[bufnr].prettier = { cmd = cmd, cwd = root }
                else
                    vim.notify(
                        ('prettier config found in %s but no node_modules/.bin/prettier; falling back to the LSP formatter')
                        :format(vim.fn.fnamemodify(root, ':~')),
                        vim.log.levels.WARN
                    )
                end
            end
        end
    end

    return vim.b[bufnr].prettier
end

-- Replace the buffer with `text` as a set of minimal edits. Rewriting every
-- line unconditionally would reset the cursor, marks and folds on every save.
local function apply_formatted(bufnr, text)
    local current = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n') .. '\n'
    if current == text then
        return
    end

    local formatted = vim.split(text, '\n')
    if formatted[#formatted] == '' then
        table.remove(formatted)
    end

    local hunks = vim.text.diff(current, text, { result_type = 'indices' })
    -- Apply back to front so earlier hunks keep their line numbers.
    for i = #hunks, 1, -1 do
        local start_a, count_a, start_b, count_b = unpack(hunks[i])
        -- A hunk with no removed lines is an insertion *after* `start_a`.
        local first = count_a == 0 and start_a or start_a - 1
        local replacement = vim.list_slice(formatted, start_b, start_b + count_b - 1)
        vim.api.nvim_buf_set_lines(bufnr, first, first + count_a, false, replacement)
    end
end

-- Format through the project's Prettier. `--stdin-filepath` is what makes this
-- work without reimplementing anything: Prettier resolves the config, honors
-- `.prettierignore` and infers the parser from the path we hand it.
local function prettier_format(bufnr, prettier)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local input = table.concat(lines, '\n') .. '\n'

    local result = vim.system({ prettier.cmd, '--stdin-filepath', vim.api.nvim_buf_get_name(bufnr) }, {
        stdin = input,
        cwd = prettier.cwd,
        text = true,
    }):wait(5000)

    if result.code ~= 0 or not result.stdout or #result.stdout == 0 then
        -- Forget the resolution so the fallback path takes over silently from
        -- here on instead of warning on every write.
        vim.b[bufnr].prettier = nil
        vim.notify(
            'prettier failed, falling back to the LSP formatter for this buffer:\n'
            .. (result.stderr ~= '' and result.stderr or 'unknown error'),
            vim.log.levels.WARN
        )
        return false
    end

    apply_formatted(bufnr, result.stdout)
    return true
end

local function deno_format(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local input = table.concat(lines, '\n') .. '\n'
    local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':e')

    local result = vim.system({ 'deno', 'fmt', '--ext', ext, '-' }, { stdin = input, text = true }):wait(5000)

    if result.code == 0 and result.stdout and #result.stdout > 0 then
        apply_formatted(bufnr, result.stdout)
    else
        vim.notify('deno fmt failed:\n' .. (result.stderr or 'unknown error'), vim.log.levels.WARN)
    end
end

-- Organize imports (goimports behavior) ahead of the formatter.
local function organize_imports(bufnr, client)
    local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
    params.context = { only = { 'source.organizeImports' }, diagnostics = {} }
    local result = vim.lsp.buf_request_sync(bufnr, 'textDocument/codeAction', params)

    for cid, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
            if r.edit then
                local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or 'utf-16'
                vim.lsp.util.apply_workspace_edit(r.edit, enc)
            end
        end
    end
end

-- Format the current buffer on save, in order of how explicit the project has
-- been about its intent: a checked-in Prettier config wins over everything,
-- Deno projects use `deno fmt`, and everything else goes through the LSP
-- formatter. tailwindcss is excluded from the LSP path (it has no formatting
-- capability today, but keep it excluded in case that changes) so typescript's
-- formatting always wins on JS/TS buffers.
local function format_on_save(bufnr)
    local prettier = resolve_prettier(bufnr)
    if prettier and prettier_format(bufnr, prettier) then
        return
    end

    if #vim.lsp.get_clients({ bufnr = bufnr, name = 'deno' }) > 0 then
        deno_format(bufnr)
        return
    end

    local clients = vim.tbl_filter(function(c)
        return c.name ~= 'tailwindcss'
    end, vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/formatting' }))

    if #clients == 0 then
        return
    end

    if vim.bo[bufnr].filetype == 'go' then
        organize_imports(bufnr, clients[1])
    end

    vim.lsp.buf.format({
        bufnr = bufnr,
        async = false,
        filter = function(c)
            return c.name ~= 'tailwindcss'
        end,
    })
end

-- Prettier applies to plenty of filetypes that have no language server here
-- (json, markdown, yaml), so format-on-save is registered per buffer rather
-- than on LspAttach. Every path above no-ops when there is nothing to run.
vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('format-on-save', { clear = true }),
    callback = function(args)
        if vim.bo[args.buf].buftype == '' then
            format_on_save(args.buf)
        end
    end,
})

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

            client:notify('workspace/didChangeConfiguration', { settings = settings })
        end
    end
})

-- Useful for autocomplete
vim.cmd('set completeopt+=noselect')

-- Enable virtual text
vim.diagnostic.config({ virtual_lines = { current_line = true } })
