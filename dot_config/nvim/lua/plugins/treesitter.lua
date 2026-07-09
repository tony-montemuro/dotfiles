return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        branch = "main",
        config = function()
            local langs = {
                "c",
                "lua",
                "vim",
                "vimdoc",
                "query",
                "markdown",
                "markdown_inline",
                "go",
                "gotmpl",
                "javascript",
                "typescript",
                "html",
                "css",
                "svelte"
            }

            require("nvim-treesitter").setup {}
            require("nvim-treesitter").install(langs)

            -- enable highlighting
            vim.api.nvim_create_autocmd("FileType", {
                pattern = langs,
                callback = function(ev)
                    local max_filesize = 100 * 1024 -- 100 KB
                    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(ev.buf))
                    if ok and stats and stats.size > max_filesize then
                        return
                    end
                    vim.treesitter.start()
                end,
            })

            -- enable treesitter-based folding
            vim.api.nvim_create_autocmd("FileType", {
                pattern = langs,
                callback = function()
                    vim.wo[0][0].foldmethod = "expr"
                    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                end
            })
        end
    }
}
