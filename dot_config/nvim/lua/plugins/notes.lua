return {
    {
        "epwalsh/obsidian.nvim",
        version = "*",
        lazy = true,
        ft = "markdown",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "hrsh7th/nvim-cmp"
        },
        opts = {
            workspaces = {
                {
                    name = "notes",
                    path = "~/notes"
                }
            },

            completion = {
                nvim_cmp = true,
                min_chars = 2
            },

            new_notes_location = "notes_subdir",

            ---@param title string|?
            ---@return string
            note_id_func = function(title)
                return title or tostring(os.time())
            end,
        }
    }
}
