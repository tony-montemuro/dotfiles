return {
    {
        'echasnovski/mini.nvim',
        version = false,
        config = function()
            local statusline = require 'mini.statusline'
            local icons = require 'mini.icons'
            local files = require 'mini.files'

            statusline.setup { use_icons = true }
            icons.setup()
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
            vim.keymap.set('n', '<leader>ft', '<cmd>:lua MiniFiles.open()<CR>')
        end
    },
}
