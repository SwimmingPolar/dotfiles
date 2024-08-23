return {
  "stevearc/resession.nvim",
  config = function()
    local resession = require("resession")
    resession.setup({})

    -- Get session name
    local function get_session_name()
      local is_git_repo = vim.trim(vim.fn.system("git rev-parse --is-inside-work-tree"))

      if is_git_repo == "true" then
        return vim.trim(vim.fn.system("git rev-parse --show-toplevel"))
      else
        return vim.trim(vim.fn.getcwd())
      end
    end

    -- Save session
    local function save_session()
      require("resession").save(get_session_name(), { dir = "dirsession", notify = false })
    end

    -- Load session
    ---@class LoadSessionOption
    ---@field name string?
    ---@param load_session_opts LoadSessionOption?
    local function load_session(load_session_opts)
      local session = load_session_opts and load_session_opts.name or nil

      -- load session
      local ok = pcall(function()
        resession.load(session or get_session_name(), { dir = "dirsession", notify = false })
      end)

      -- if didn't load, like in new session, instead save session
      if not ok then
        save_session()
      end

      -- @NOTE: might be a bug
      -- reload buffer because ts won't update highlight when session changes
      vim.cmd("silent! :e")
    end

    -- Delete session
    local function delete_session()
      pcall(function()
        resession.delete(get_session_name(), { dir = "dirsession" })
      end)
    end

    -- Show sessions list
    local function show_sessions()
      -- get sessions list
      local session_list = resession.list({ dir = "dirsession" })

      -- rename session names with "/" instead of "_"
      local new_session_list = vim.tbl_map(function(session)
        local name = string.gsub(session, "_", "/")
        return name
      end, session_list)

      -- show sessions a list
      vim.ui.select(new_session_list, {
        prompt = "Select Session",
        telescope = require("telescope.themes").get_dropdown({
          initial_mode = "normal",
        }),
      }, function(selected)
        if selected == nil then
          return
        end

        -- sync selected session and current session name to the same separator("/")
        local selected_session_name = selected and string.gsub(selected, "/", "_") or ""
        local current_session_name = require("resession").get_current()
        current_session_name = current_session_name and string.gsub(current_session_name, "/", "_") or ""

        -- do nothing if same session is selected
        if selected_session_name == current_session_name then
          return
        end

        -- write changes to the files that been modified before session changes
        vim.cmd("silent! :bufdo update!")
        -- before loading a new session, save the current session
        save_session()

        load_session({
          name = selected,
        })
      end)
    end

    vim.keymap.set("n", "<leader>qs", save_session, { desc = "save session" })
    vim.keymap.set("n", "<leader>ql", show_sessions, { desc = "show sessions" })
    vim.keymap.set("n", "<leader>qd", delete_session, { desc = "delete session" })

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- Only load the session if nvim was started with no args
        if vim.fn.argc(-1) == 0 then
          load_session({})
        end
      end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        -- save_session()
        resession.save_all()
      end,
    })
  end,
}
