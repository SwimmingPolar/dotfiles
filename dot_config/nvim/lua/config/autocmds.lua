vim.cmd "language en_US"

-- Disable goddamn annoying auto-commenting
vim.cmd "autocmd BufEnter * set formatoptions-=cro"
vim.cmd "autocmd BufEnter * setlocal formatoptions-=cro"

-- set named registers with macros
vim.cmd [[
let @d = "gg/default.*[A-Z]\w*\>\r"
let @f = "/\\(\\(^export=\\?\\s\\+\\(const\\|function\\|default\\)\\s\\+.*(=\\?.*)=\\?\\s\\+=(\\=>)\\?\\s\\+{$\\)\\|\\(^const\\s\\+.*(=\\?.*)=\\?.*=>\\s\\+{$\\)\\)\r"
let @r = "0/return\rzzm0"
]]

-- set line numbers on help
vim.cmd "autocmd FileType help setlocal number"

-- tailwind sort on save
vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("tailwind sort on save", { clear = true }),
  pattern = "*",
  callback = function()
    local lsp_clients = vim.lsp.get_clients()
    for _, lsp in ipairs(lsp_clients) do
      if lsp.name == "tailwindcss" then
        vim.cmd "TailwindSortSync"
      end
    end
  end,
})
