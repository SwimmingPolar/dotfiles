return {
  dir = "~/Projects/tailwind-classname.nvim",
  dev = true,
  -- opts = {
  --   name = "YDH",
  -- },
  config = function()
    require("example").setup({
      name = "YDH from setup",
    })
  end,
}
