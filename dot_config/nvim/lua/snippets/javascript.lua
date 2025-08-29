local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("javascript", {
  s("===", { -- Trigger: `banner`
    t { "/**", " * ==============  " },
    i(1, "Title"),
    t { "  ===============", " */" },
  }),
})
