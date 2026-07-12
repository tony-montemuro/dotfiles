return {
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        keys = {
            { "<leader>vd", "<cmd>DiffviewOpen<CR>",          desc = "Diffview: open" },
            { "<leader>vh", "<cmd>DiffviewFileHistory<CR>",   desc = "Diffview: full file history" },
            { "<leader>vf", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview: individual file history" },
            { "<leader>vc", "<cmd>DiffviewClose<CR>",         desc = "Diffview: close" },
        }
    }
}
