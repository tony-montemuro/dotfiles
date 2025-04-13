return {
    cmd = { "gopls" },
    root_markers = { "go.mod", ".git" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    settings = {
        gopls = {
            templateExtensions = { "html", "tmpl" }
        },
    },
    single_file_support = true
}
