return {
    "girishji/pythondoc.vim",
    init = function()
        vim.cmd("source " .. vim.fn.stdpath("data") .. "/lazy/pythondoc.vim/plugin/pythondoc.vim")
    end,
}
