return {
    init_options = { hostInfo = 'neovim' },
    cmd = { "typescript-language-server", "--stdio" },
    root_markers = { "package.json", "tsconfig.json", ".git" },
    filetypes = {
        "typescript",
        "typescriptreact",
        "javascript",
        "javascriptreact"
    },
    single_file_support = true
}
