return {
    {
        'echasnovski/mini.nvim',
        version = false,
        config = function()
            local statusline = require 'mini.statusline'
            local files = require 'mini.files'

            statusline.setup { use_icons = true }
            files.setup({
                mappings = {
                    synchronize = 'w'
                },

                options = {
                    permanent_delete = false
                },

                windows = {
                    preview = true
                }
            })

            -- Set keybind to open mini icon viewer
            vim.keymap.set('n', '<leader>d', '<cmd>:lua MiniFiles.open()<CR>')
        end
    },
}
