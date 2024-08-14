-- https://github.com/yacineMTB/dingllm.nvim

return {
  "yacineMTB/dingllm.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local system_prompt =
      "You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks"
    local helpful_prompt =
      "You are a helpful assistant. What I have sent are my notes so far. You are very curt, yet helpful."

    local dingllm = require("dingllm")

    local function handle_response(data_stream)
      local success, json = pcall(vim.json.decode, data_stream)
      if success then
        if json.choices and json.choices[1] and json.choices[1].text then
          local content = json.choices[1].text
          if content then
            dingllm.write_string_at_cursor(content)
          end
        end
      else
        print("non json " .. data_stream)
      end
    end

    local function send_message(opts, prompt)
      local url = opts.url
      local api_key = opts.api_key_name and os.getenv(opts.api_key_name)

      if not api_key then
        error("no api key")
      end

      local data = {
        prompt = prompt,
        model = opts.model,
        temperature = 0.7,
        stream = true,
      }
      local args = { "-N", "-X", "POST", "-H", "Content-Type: application/json", "-d", vim.json.encode(data) }
      if api_key then
        table.insert(args, "-H")
        table.insert(args, "Authorization: Bearer " .. api_key)
      end
      table.insert(args, url)
      return args
    end

    local function invoke_model(model, prompt, opts)
      return function()
        dingllm.invoke_llm_and_stream_into_editor({
          url = "https://openrouter.ai/api/v1/chat/completions",
          api_key_name = "OPEN_ROUTER_API_KEY",
          max_tokens = "128",
          replace = false,
          model = model,
          system_prompt = prompt,
          table.unpack(opts),
        }, send_message, handle_response)
      end
    end

    local anthropic_explain = invoke_model("anthropic/claude-3.5-sonnet", helpful_prompt)
    local anthropic_generate = invoke_model("anthropic/claude-3.5-sonnet", system_prompt, { replace = true })
    local openai_explain = invoke_model("openai/gpt-4o-mini-2024-07-18", helpful_prompt)
    local openai_generate = invoke_model("openai/gpt-4o-mini-2024-07-18", system_prompt, { replace = true })

    local whichkey = require("which-key")
    whichkey.add({
      { "<leader>a", desc = "AI (LLM)" },
      { "<leader>ag", desc = "generate" },
      { "<leader>ae", desc = "explain" },
    })

    vim.keymap.set({ "n", "v" }, "<leader>aeo", openai_explain, { desc = "openai explain" })
    vim.keymap.set({ "n", "v" }, "<leader>ago", openai_generate, { desc = "openai generate" })
    vim.keymap.set({ "n", "v" }, "<leader>aea", anthropic_explain, { desc = " anthropic explain" })
    vim.keymap.set({ "n", "v" }, "<leader>aga", anthropic_generate, { desc = " anthropic generate" })
  end,
}

-- 10 reasons why nvim is better than vscode
