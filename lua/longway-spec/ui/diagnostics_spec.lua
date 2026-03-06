-- [nfnl] fnl/longway-spec/ui/diagnostics_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local diagnostics = require("longway.ui.diagnostics")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local bufnr = vim.api.nvim_create_buf(false, true)
      local lines = {"---", "shortcut_id: 12345", "shortcut_type: story", "---", "", "# Title", "", "## Description", "", "Some text", "", "## CustomHeader", "", "Bad content", "", "## Tasks", "", "- [ ] task"}
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      diagnostics.check(bufnr)
      do
        local diags = vim.diagnostic.get(bufnr)
        assert.equals(1, #diags)
        assert.equals(vim.diagnostic.severity.WARN, diags[1].severity)
        assert.equals(11, diags[1].lnum)
      end
      return vim.api.nvim_buf_delete(bufnr, {force = true})
    end
    it("sets warnings for unknown ## headers in longway files", _4_)
    local function _5_()
      local bufnr = vim.api.nvim_create_buf(false, true)
      local lines = {"---", "shortcut_id: 12345", "shortcut_type: story", "---", "", "# Title", "", "## Description", "", "Desc", "", "## Tasks", "", "## Comments", "", "## Local Notes"}
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      diagnostics.check(bufnr)
      do
        local diags = vim.diagnostic.get(bufnr)
        assert.equals(0, #diags)
      end
      return vim.api.nvim_buf_delete(bufnr, {force = true})
    end
    it("does not warn for known section headers", _5_)
    local function _6_()
      local bufnr = vim.api.nvim_create_buf(false, true)
      local lines = {"---", "shortcut_id: 12345", "shortcut_type: story", "---", "", "# Title", "", "## Description", "", "### Subheading", "", "Details here"}
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      diagnostics.check(bufnr)
      do
        local diags = vim.diagnostic.get(bufnr)
        assert.equals(0, #diags)
      end
      return vim.api.nvim_buf_delete(bufnr, {force = true})
    end
    it("does not warn for ### subheadings", _6_)
    local function _7_()
      local bufnr = vim.api.nvim_create_buf(false, true)
      local lines = {"---", "shortcut_id: 12345", "shortcut_type: story", "---", "", "# Title", "", "## Description", "", "# Bad H1 Header", "", "Content"}
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      diagnostics.check(bufnr)
      do
        local diags = vim.diagnostic.get(bufnr)
        assert.equals(1, #diags)
        assert.equals(9, diags[1].lnum)
      end
      return vim.api.nvim_buf_delete(bufnr, {force = true})
    end
    it("warns for # (h1) headers after the title", _7_)
    local function _8_()
      local bufnr = vim.api.nvim_create_buf(false, true)
      local lines = {"# Regular File", "", "## Some Heading", "", "Content"}
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      diagnostics.check(bufnr)
      do
        local diags = vim.diagnostic.get(bufnr)
        assert.equals(0, #diags)
      end
      return vim.api.nvim_buf_delete(bufnr, {force = true})
    end
    return it("does not set diagnostics for non-longway files", _8_)
  end
  return describe("check", _3_)
end
return describe("longway.ui.diagnostics", _1_)
