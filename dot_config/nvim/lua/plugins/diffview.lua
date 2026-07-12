return {
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        keys = {
            { "<leader>vd", "<cmd>DiffviewOpen<CR>",          desc = "Diffview: open" },
            { "<leader>vc", "<cmd>DiffviewClose<CR>",         desc = "Diffview: close" },
            { "<leader>vh", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview: file history" },
        }
    }
}
