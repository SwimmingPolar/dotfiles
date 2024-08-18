return {
  "l3mon4d3/LuaSnip",
  dependencies = {
    {
      "mlaursen/vim-react-snippets",
      config = function()
        require("vim-react-snippets").lazy_load()
      end,
    },
  },
}
