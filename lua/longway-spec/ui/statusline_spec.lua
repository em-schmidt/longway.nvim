-- [nfnl] Compiled from fnl/longway-spec/ui/statusline_spec.fnl by https://github.com/Olical/nfnl, do not edit.
local t = require("longway-spec.init")
require("longway-spec.assertions")
local statusline = require("longway.ui.statusline")
local function _1_()
  local function _2_()
    t["setup-test-config"]({})
    statusline.teardown()
    local bufnr = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_buf_del_var, bufnr, "longway_id")
    pcall(vim.api.nvim_buf_del_var, bufnr, "longway_type")
    pcall(vim.api.nvim_buf_del_var, bufnr, "longway_state")
    pcall(vim.api.nvim_buf_del_var, bufnr, "longway_sync_status")
    pcall(vim.api.nvim_buf_del_var, bufnr, "longway_conflict")
    pcall(vim.api.nvim_buf_del_var, bufnr, "longway_changed_sections")
    return pcall(vim.api.nvim_buf_del_var, bufnr, "longway_conflict_sections")
  end
  before_each(_2_)
  local function _3_()
    return statusline.teardown()
  end
  after_each(_3_)
  local function _4_()
    local function _5_()
      local is_longway_buffer = statusline["is-longway-buffer"]
      return assert.is_function(is_longway_buffer)
    end
    it("exports is-longway-buffer function", _5_)
    local function _6_()
      local get_status = statusline["get-status"]
      return assert.is_function(get_status)
    end
    it("exports get-status function", _6_)
    local function _7_()
      local get_status_data = statusline["get-status-data"]
      return assert.is_function(get_status_data)
    end
    it("exports get-status-data function", _7_)
    local function _8_()
      local lualine_component = statusline["lualine-component"]
      return assert.is_function(lualine_component)
    end
    it("exports lualine-component function", _8_)
    local function _9_()
      return assert.is_function(statusline.setup)
    end
    it("exports setup function", _9_)
    local function _10_()
      return assert.is_function(statusline.teardown)
    end
    return it("exports teardown function", _10_)
  end
  describe("module structure", _4_)
  local function _11_()
    local function _12_()
      local is_longway_buffer = statusline["is-longway-buffer"]
      return assert.is_false(is_longway_buffer())
    end
    it("returns false for a non-longway buffer", _12_)
    local function _13_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 12345)
      return assert.is_true(statusline["is-longway-buffer"]())
    end
    return it("returns true when longway_id is set", _13_)
  end
  describe("is-longway-buffer", _11_)
  local function _14_()
    local function _15_()
      local get_status = statusline["get-status"]
      return assert.is_nil(get_status())
    end
    it("returns nil for non-longway buffer", _15_)
    local function _16_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 12345)
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "synced")
      local status = statusline["get-status"]()
      assert.is_not_nil(status)
      assert.has_substring(status, "SC:12345")
      return assert.has_substring(status, "[synced]")
    end
    it("returns correct string for synced buffer", _16_)
    local function _17_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 67890)
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "modified")
      local status = statusline["get-status"]()
      assert.has_substring(status, "SC:67890")
      return assert.has_substring(status, "[modified]")
    end
    it("returns modified indicator when sync_status is modified", _17_)
    local function _18_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 11111)
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "conflict")
      local status = statusline["get-status"]()
      assert.has_substring(status, "SC:11111")
      return assert.has_substring(status, "[CONFLICT]")
    end
    it("returns CONFLICT indicator when sync_status is conflict", _18_)
    local function _19_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 99999)
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "new")
      local status = statusline["get-status"]()
      assert.has_substring(status, "SC:99999")
      return assert.has_substring(status, "[new]")
    end
    return it("returns new indicator when sync_status is new", _19_)
  end
  describe("get-status", _14_)
  local function _20_()
    local function _21_()
      local get_status_data = statusline["get-status-data"]
      return assert.is_nil(get_status_data())
    end
    it("returns nil for non-longway buffer", _21_)
    local function _22_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 12345)
      vim.api.nvim_buf_set_var(bufnr, "longway_type", "story")
      vim.api.nvim_buf_set_var(bufnr, "longway_state", "In Progress")
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "synced")
      vim.api.nvim_buf_set_var(bufnr, "longway_conflict", false)
      vim.api.nvim_buf_set_var(bufnr, "longway_changed_sections", {})
      vim.api.nvim_buf_set_var(bufnr, "longway_conflict_sections", vim.NIL)
      local data = statusline["get-status-data"]()
      assert.is_not_nil(data)
      assert.equals(12345, data.shortcut_id)
      assert.equals("story", data.shortcut_type)
      assert.equals("In Progress", data.state)
      assert.equals("synced", data.sync_status)
      assert.is_table(data.changed_sections)
      assert.equals(0, #data.changed_sections)
      return assert.is_nil(data.conflict_sections)
    end
    it("returns structured table with all expected fields", _22_)
    local function _23_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 22222)
      vim.api.nvim_buf_set_var(bufnr, "longway_type", "story")
      vim.api.nvim_buf_set_var(bufnr, "longway_state", "Started")
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "modified")
      vim.api.nvim_buf_set_var(bufnr, "longway_changed_sections", {"description", "tasks"})
      vim.api.nvim_buf_set_var(bufnr, "longway_conflict_sections", vim.NIL)
      local data = statusline["get-status-data"]()
      assert.equals("modified", data.sync_status)
      assert.is_table(data.changed_sections)
      assert.equals(2, #data.changed_sections)
      assert.equals("description", data.changed_sections[1])
      assert.equals("tasks", data.changed_sections[2])
      return assert.is_nil(data.conflict_sections)
    end
    it("returns changed_sections listing which sections differ", _23_)
    local function _24_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 33333)
      vim.api.nvim_buf_set_var(bufnr, "longway_type", "story")
      vim.api.nvim_buf_set_var(bufnr, "longway_state", "Started")
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "conflict")
      vim.api.nvim_buf_set_var(bufnr, "longway_conflict", true)
      vim.api.nvim_buf_set_var(bufnr, "longway_changed_sections", {"description"})
      vim.api.nvim_buf_set_var(bufnr, "longway_conflict_sections", {"description", "tasks"})
      local data = statusline["get-status-data"]()
      assert.equals("conflict", data.sync_status)
      assert.is_not_nil(data.conflict_sections)
      assert.is_table(data.conflict_sections)
      assert.equals(2, #data.conflict_sections)
      assert.equals("description", data.conflict_sections[1])
      return assert.equals("tasks", data.conflict_sections[2])
    end
    return it("returns conflict_sections when conflicts exist", _24_)
  end
  describe("get-status-data", _20_)
  local function _25_()
    local function _26_()
      local lualine_component = statusline["lualine-component"]
      local component = lualine_component()
      assert.is_table(component)
      assert.is_function(component[1])
      assert.is_function(component.cond)
      return assert.is_function(component.color)
    end
    it("returns a table with expected fields", _26_)
    local function _27_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 55555)
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "synced")
      local component = statusline["lualine-component"]()
      local color = component.color()
      assert.is_table(color)
      return assert.equals("#a6e3a1", color.fg)
    end
    it("color returns green for synced buffers", _27_)
    local function _28_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 55555)
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "modified")
      local component = statusline["lualine-component"]()
      local color = component.color()
      return assert.equals("#f9e2af", color.fg)
    end
    it("color returns yellow for modified buffers", _28_)
    local function _29_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 55555)
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "conflict")
      local component = statusline["lualine-component"]()
      local color = component.color()
      return assert.equals("#f38ba8", color.fg)
    end
    it("color returns red for conflict buffers", _29_)
    local function _30_()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_var(bufnr, "longway_id", 55555)
      vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", "new")
      local component = statusline["lualine-component"]()
      local color = component.color()
      return assert.equals("#89b4fa", color.fg)
    end
    return it("color returns blue for new buffers", _30_)
  end
  describe("lualine-component", _25_)
  local function _31_()
    local function _32_()
      local markdown = "---\nshortcut_id: 44444\nshortcut_type: story\nstate: Started\nsync_hash: oldhash\ntasks_hash: oldhash\ncomments_hash: oldhash\n---\n\n# Test Story\n\n## Description\n\n<!-- BEGIN SHORTCUT SYNC:description -->\nSome content\n<!-- END SHORTCUT SYNC:description -->\n\n## Tasks\n\n<!-- BEGIN SHORTCUT SYNC:tasks -->\n<!-- END SHORTCUT SYNC:tasks -->\n\n## Comments\n\n<!-- BEGIN SHORTCUT SYNC:comments -->\n<!-- END SHORTCUT SYNC:comments -->\n"
      local tmpfile = "/tmp/longway-test-autocmd-refresh.md"
      do
        local f = io.open(tmpfile, "w")
        f:write(markdown)
        f:close()
      end
      vim.cmd(("edit " .. tmpfile))
      do
        local bufnr = vim.api.nvim_get_current_buf()
        local lines = vim.split(markdown, "\n", {plain = true})
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        statusline.setup()
        vim.cmd("doautocmd BufEnter")
        do
          local id = vim.api.nvim_buf_get_var(bufnr, "longway_id")
          assert.equals(44444, id)
        end
        do
          local sync_status = vim.api.nvim_buf_get_var(bufnr, "longway_sync_status")
          assert.equals("modified", sync_status)
        end
        local changed_sections = vim.api.nvim_buf_get_var(bufnr, "longway_changed_sections")
        assert.is_table(changed_sections)
        local found_desc = false
        for _, s in ipairs(changed_sections) do
          if (s == "description") then
            found_desc = true
          else
          end
        end
        assert.is_true(found_desc)
      end
      vim.cmd("bdelete!")
      return os.remove(tmpfile)
    end
    it("sets buffer variables for longway markdown files on BufEnter", _32_)
    local function _34_()
      local markdown = "---\nshortcut_id: 55555\nshortcut_type: story\nstate: Started\nsync_hash: abc\nconflict_sections:\n  - description\n---\n\n# Conflict Story\n\n## Description\n\n<!-- BEGIN SHORTCUT SYNC:description -->\nContent\n<!-- END SHORTCUT SYNC:description -->\n"
      local tmpfile = "/tmp/longway-test-autocmd-conflict.md"
      do
        local f = io.open(tmpfile, "w")
        f:write(markdown)
        f:close()
      end
      vim.cmd(("edit " .. tmpfile))
      do
        local bufnr = vim.api.nvim_get_current_buf()
        local lines = vim.split(markdown, "\n", {plain = true})
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        statusline.setup()
        vim.cmd("doautocmd BufEnter")
        do
          local sync_status = vim.api.nvim_buf_get_var(bufnr, "longway_sync_status")
          assert.equals("conflict", sync_status)
        end
        local conflict = vim.api.nvim_buf_get_var(bufnr, "longway_conflict")
        assert.is_true(conflict)
      end
      vim.cmd("bdelete!")
      return os.remove(tmpfile)
    end
    it("sets conflict status when conflict_sections is present", _34_)
    local function _35_()
      local markdown = "# Just a regular markdown file\n\nNo frontmatter here.\n"
      local tmpfile = "/tmp/longway-test-autocmd-nonlongway.md"
      do
        local f = io.open(tmpfile, "w")
        f:write(markdown)
        f:close()
      end
      vim.cmd(("edit " .. tmpfile))
      do
        local bufnr = vim.api.nvim_get_current_buf()
        local lines = vim.split(markdown, "\n", {plain = true})
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        statusline.setup()
        vim.cmd("doautocmd BufEnter")
        assert.is_false(statusline["is-longway-buffer"]())
        assert.is_nil(statusline["get-status"]())
      end
      vim.cmd("bdelete!")
      return os.remove(tmpfile)
    end
    return it("marks non-longway markdown files as non-longway", _35_)
  end
  describe("autocmd refresh", _31_)
  local function _36_()
    local function _37_()
      statusline.setup()
      local autocmds = vim.api.nvim_get_autocmds({group = "longway_statusline"})
      return assert.is_true((#autocmds >= 1))
    end
    it("creates augroup", _37_)
    local function _38_()
      statusline.setup()
      local enter_cmds = vim.api.nvim_get_autocmds({group = "longway_statusline", event = "BufEnter"})
      local write_cmds = vim.api.nvim_get_autocmds({group = "longway_statusline", event = "BufWritePost"})
      assert.equals(1, #enter_cmds)
      return assert.equals(1, #write_cmds)
    end
    it("registers BufEnter and BufWritePost autocmds", _38_)
    local function _39_()
      statusline.setup()
      statusline.setup()
      local autocmds = vim.api.nvim_get_autocmds({group = "longway_statusline"})
      return assert.equals(2, #autocmds)
    end
    return it("is idempotent", _39_)
  end
  describe("setup", _36_)
  local function _40_()
    local function _41_()
      statusline.setup()
      statusline.teardown()
      local ok, _ = pcall(vim.api.nvim_get_autocmds, {group = "longway_statusline"})
      return assert.is_false(ok)
    end
    it("removes augroup", _41_)
    local function _42_()
      statusline.teardown()
      return assert.is_true(true)
    end
    return it("is safe to call when not set up", _42_)
  end
  return describe("teardown", _40_)
end
return describe("longway.ui.statusline", _1_)