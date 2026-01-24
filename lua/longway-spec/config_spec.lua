-- [nfnl] fnl/longway-spec/config_spec.fnl
local config = require("longway.config")
local function _1_()
  local function _2_()
    local function _3_()
      config.setup({workspace_dir = "/custom/path"})
      local cfg = config.get()
      assert.equals("/custom/path", cfg.workspace_dir)
      return assert.equals("stories", cfg.stories_subdir)
    end
    it("merges user config with defaults", _3_)
    local function _4_()
      config.setup({})
      local cfg = config.get()
      return assert.is_not_nil(cfg.workspace_dir)
    end
    it("handles empty config", _4_)
    local function _5_()
      config.setup(nil)
      local cfg = config.get()
      return assert.is_not_nil(cfg)
    end
    it("handles nil config", _5_)
    local function _6_()
      config.setup({sync_sections = {tasks = false}})
      local cfg = config.get()
      assert.is_false(cfg.sync_sections.tasks)
      return assert.is_true(cfg.sync_sections.description)
    end
    return it("deep merges nested config", _6_)
  end
  describe("setup", _2_)
  local function _7_()
    local function _8_()
      config.setup({debug = true})
      local cfg = config.get()
      return assert.is_true(cfg.debug)
    end
    it("returns current configuration", _8_)
    local function _9_()
      config.setup({})
      local cfg = config.get()
      assert.is_not_nil(cfg.workspace_dir)
      assert.is_not_nil(cfg.sync_start_marker)
      return assert.is_not_nil(cfg.sync_end_marker)
    end
    return it("returns table with expected keys", _9_)
  end
  describe("get", _7_)
  local function _10_()
    local function _11_()
      config.setup({workspace_dir = "/test/path"})
      local result = config["get-workspace-dir"]()
      return assert.equals("/test/path", result)
    end
    it("returns expanded workspace directory", _11_)
    local function _12_()
      config.setup({workspace_dir = "~/shortcut"})
      local result = config["get-workspace-dir"]()
      return assert.is_nil(string.match(result, "^~"))
    end
    return it("expands home directory", _12_)
  end
  describe("get-workspace-dir", _10_)
  local function _13_()
    local function _14_()
      config.setup({workspace_dir = "/test", stories_subdir = "stories"})
      local result = config["get-stories-dir"]()
      return assert.equals("/test/stories", result)
    end
    return it("combines workspace dir and stories subdir", _14_)
  end
  describe("get-stories-dir", _13_)
  local function _15_()
    local function _16_()
      config.setup({workspace_dir = "/test", epics_subdir = "epics"})
      local result = config["get-epics-dir"]()
      return assert.equals("/test/epics", result)
    end
    return it("combines workspace dir and epics subdir", _16_)
  end
  describe("get-epics-dir", _15_)
  local function _17_()
    local function _18_()
      config.setup({token = "test-token"})
      return assert.is_true(config["is-configured"]())
    end
    it("returns true when token is set", _18_)
    local function _19_()
      config.setup({})
      local result = config["is-configured"]()
      return assert.is_boolean(result)
    end
    return it("returns false when no token", _19_)
  end
  return describe("is-configured", _17_)
end
return describe("longway.config", _1_)
