vim.cmd("language en_US")

-- Disable goddamn annoying auto-commenting
vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")

-- set named registers with macros
-- vim.cmd([[
-- let @C = "/export const.*= \rztf(\e%j0ztm1M"
-- let @c = "/const.*= \rztf(\e%j0ztm1M"
-- let @R = "?return\rzzm0"
-- let @E = "\e/useeffect\rztV%"
-- ]])

-- set line numbers on help
vim.cmd("autocmd FileType help setlocal number")

-- tailwind sort on save
vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("tailwind sort on save", { clear = true }),
    pattern = "*",
    callback = function()
        local lsp_clients = vim.lsp.get_clients()
        for _, lsp in ipairs(lsp_clients) do
            if lsp.name == "tailwindcss" then
                vim.cmd("TailwindSortSync")
            end
        end
    end,
})
