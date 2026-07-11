return {
    {
        'nvim-telescope/telescope.nvim',
        version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
        },
        config = function()
            require('telescope').setup {
                defaults = {
                    sorting_strategy = "ascending",
                    layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                        },
                    },
                },
                pickers = {
                    git_commits = {
                        theme = "ivy"
                    },
                    git_branches = {
                        theme = "ivy"
                    },
                    lsp_references = {
                        theme = "ivy"
                    },
                    lsp_implementations = {
                        theme = "ivy"
                    }
                },
                extensions = {
                    fzf = {}
                }
            }

            require('telescope').load_extension('fzf')

            local builtin = require('telescope.builtin')

            -- All pickers
            vim.keymap.set('n', '<leader>fa', builtin.builtin, { desc = 'Telescope find pickers' })

            -- File pickers
            vim.keymap.set('n', '<leader>fd', builtin.find_files, { desc = 'Telescope find files' })
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
            vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
            vim.keymap.set('n', '<leader>fs', builtin.grep_string, { desc = 'Telescope grep string' })
            vim.keymap.set('n', '<leader>fc', function()
                builtin.find_files {
                    cwd = vim.fn.stdpath("config")
                }
            end, { desc = 'Telescope find system config files' })
            vim.keymap.set('n', '<leader>hfd', function()
                builtin.find_files {
                    hidden = true
                }
            end, { desc = 'Telescope find files (with hidden files)' })
            vim.keymap.set('n', '<leader>afd', function()
                builtin.find_files {
                    hidden = true,
                    no_ignore = true
                }
            end, { desc = 'Telescope find files (all files)' })

            -- Vim pickers
            vim.keymap.set('n', '<leader>fj', builtin.jumplist, { desc = 'Vim jumplist' })

            -- Git pickers
            vim.keymap.set('n', '<leader>gfc', builtin.git_commits, { desc = 'Git commits' })
            vim.keymap.set('n', '<leader>gfb', builtin.git_branches, { desc = 'Git branches' })

            -- LSP pickers
            vim.keymap.set('n', '<leader>lr', builtin.lsp_references, { desc = 'LSP references' })
            vim.keymap.set('n', '<leader>gi', builtin.lsp_implementations, { desc = 'LSP implementations' })

            -- require 'config.telescope.multigrep'.setup()
        end
    }
}
