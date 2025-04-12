-- gotmpl filetype
vim.filetype.add({
    extension = {
        gotmpl = 'gotmpl',
    },
    pattern = {
        [".*/templates/.*%.tmpl"] = "gotmpl",
        [".*/ui/.*%.tmpl"] = "gotmpl",
    },
})
