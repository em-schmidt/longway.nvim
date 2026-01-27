-- [nfnl] Compiled from fnl/longway/ui/picker.fnl by https://github.com/Olical/nfnl, do not edit.
local config = require("longway.config")
local notify = require("longway.ui.notify")
local M = {}
M["check-snacks"] = function()
  local ok, _ = pcall(require, "snacks")
  if not ok then
    notify.error("snacks.nvim is required for :LongwayPicker. Install folke/snacks.nvim")
  else
  end
  return ok
end
M["find-local-file"] = function(shortcut_id, shortcut_type)
  local dir
  if (shortcut_type == "epic") then
    dir = config["get-epics-dir"]()
  else
    dir = config["get-stories-dir"]()
  end
  local pattern = (dir .. "/" .. tostring(shortcut_id) .. "-*.md")
  local matches = vim.fn.glob(pattern, false, true)
  if (#matches > 0) then
    return matches[1]
  else
    return nil
  end
end
M["build-picker-layout"] = function()
  local cfg = config.get()
  local picker_cfg = (cfg.picker or {})
  local _4_
  if (picker_cfg.preview == false) then
    _4_ = false
  else
    _4_ = true
  end
  return {preset = (picker_cfg.layout or "default"), preview = _4_}
end
M.truncate = function(s, max_len)
  if (not s or (#s <= max_len)) then
    return (s or "")
  else
    return (string.sub(s, 1, (max_len - 3)) .. "...")
  end
end
M["first-line"] = function(s)
  if not s then
    return ""
  else
    local line = string.match(s, "^%s*(.-)%s*$")
    return (string.match(line, "^([^\n]+)") or "")
  end
end
M["pick-stories"] = function(opts)
  local Snacks = require("snacks")
  local search_api = require("longway.api.search")
  local opts0 = (opts or {})
  local query
  local or_8_ = opts0.query
  if not or_8_ then
    if opts0.preset then
      local preset = config["get-preset"](opts0.preset)
      if preset then
        or_8_ = preset.query
      else
        or_8_ = nil
      end
    else
      or_8_ = nil
    end
  end
  if not or_8_ then
    local default = config["get-default-preset"]()
    if default then
      local preset = config["get-preset"](default)
      if preset then
        or_8_ = preset.query
      else
        or_8_ = nil
      end
    else
      or_8_ = nil
    end
  end
  query = (or_8_ or "")
  local function _16_(finder_opts, ctx)
    local result = search_api["search-stories-all"](query, {max_results = 100})
    local items = {}
    if result.ok then
      for i, story in ipairs((result.data or {})) do
        local file = M["find-local-file"](story.id, "story")
        local state = (story.workflow_state_name or "")
        local owner_names
        do
          local names = {}
          for _, o in ipairs((story.owners or {})) do
            if o.profile then
              table.insert(names, (o.profile.name or o.profile.mention_name or ""))
            else
            end
          end
          owner_names = table.concat(names, ", ")
        end
        local text = string.format("%s %s [%s] @%s", tostring(story.id), (story.name or ""), state, owner_names)
        table.insert(items, {text = text, idx = i, id = story.id, name = (story.name or ""), state = state, story_type = (story.story_type or ""), owners = owner_names, estimate = story.estimate, file = file, preview = {text = (story.description or "No description"), ft = "markdown"}})
      end
    else
    end
    return items
  end
  local function _19_(item, picker)
    local ret = {}
    table.insert(ret, {tostring((item.id or "")), "Number"})
    table.insert(ret, {" ", {virtual = true}})
    table.insert(ret, {(item.name or ""), "SnacksPickerLabel"})
    table.insert(ret, {(" [" .. (item.state or "") .. "]"), "Type"})
    if (item.owners and (#item.owners > 0)) then
      table.insert(ret, {(" @" .. item.owners), "Comment"})
    else
    end
    if item.file then
      table.insert(ret, {" (local)", "Special"})
    else
    end
    return ret
  end
  local function _22_(picker, item)
    picker:close()
    if item then
      if item.file then
        return vim.cmd(("edit " .. item.file))
      else
        local pull = require("longway.sync.pull")
        return pull["pull-story-to-buffer"](item.id)
      end
    else
      return nil
    end
  end
  return Snacks.picker({source = "longway_stories", title = "Longway Stories", layout = M["build-picker-layout"](), finder = _16_, format = _19_, confirm = _22_})
end
M["pick-epics"] = function(opts)
  local Snacks = require("snacks")
  local epics_api = require("longway.api.epics")
  local function _25_(finder_opts, ctx)
    local result = epics_api.list()
    local items = {}
    if result.ok then
      for i, epic in ipairs((result.data or {})) do
        local file = M["find-local-file"](epic.id, "epic")
        local state = (epic.state or "")
        local stats = (epic.stats or {})
        local done = (stats.num_stories_done or 0)
        local total_stories = (stats.num_stories or 0)
        local text = string.format("%s %s [%s] (%d/%d stories)", tostring(epic.id), (epic.name or ""), state, done, total_stories)
        table.insert(items, {text = text, idx = i, id = epic.id, name = (epic.name or ""), state = state, done = done, total_stories = total_stories, file = file, preview = {text = (epic.description or "No description"), ft = "markdown"}})
      end
    else
    end
    return items
  end
  local function _27_(item, picker)
    local ret = {}
    table.insert(ret, {tostring((item.id or "")), "Number"})
    table.insert(ret, {" ", {virtual = true}})
    table.insert(ret, {(item.name or ""), "SnacksPickerLabel"})
    table.insert(ret, {(" [" .. (item.state or "") .. "]"), "Type"})
    table.insert(ret, {string.format(" (%d/%d stories)", (item.done or 0), (item.total_stories or 0)), "Comment"})
    if item.file then
      table.insert(ret, {" (local)", "Special"})
    else
    end
    return ret
  end
  local function _29_(picker, item)
    picker:close()
    if item then
      if item.file then
        return vim.cmd(("edit " .. item.file))
      else
        local pull = require("longway.sync.pull")
        return pull["pull-epic-to-buffer"](item.id)
      end
    else
      return nil
    end
  end
  return Snacks.picker({source = "longway_epics", title = "Longway Epics", layout = M["build-picker-layout"](), finder = _25_, format = _27_, confirm = _29_})
end
M["pick-presets"] = function()
  local Snacks = require("snacks")
  local presets = config["get-presets"]()
  local default_preset = config["get-default-preset"]()
  local items = {}
  local idx = 0
  for name, preset in pairs(presets) do
    idx = (idx + 1)
    local is_default = (name == default_preset)
    local desc = (preset.description or preset.query or "")
    local text
    local _32_
    if is_default then
      _32_ = " (default)"
    else
      _32_ = ""
    end
    text = (name .. ": " .. desc .. _32_)
    local function _34_()
      if is_default then
        return "\n(default preset)"
      else
        return ""
      end
    end
    table.insert(items, {text = text, idx = idx, name = name, query = (preset.query or ""), description = desc, is_default = is_default, preview = {text = string.format("Preset: %s\nQuery: %s\nDescription: %s%s", name, (preset.query or ""), (preset.description or ""), _34_()), ft = "yaml"}})
  end
  if (#items == 0) then
    return notify.warn("No presets configured")
  else
    local function _35_(item, picker)
      local ret = {}
      table.insert(ret, {(item.name or ""), "SnacksPickerLabel"})
      table.insert(ret, {(" \226\128\148 " .. (item.description or "")), "Comment"})
      if item.is_default then
        table.insert(ret, {" (default)", "Special"})
      else
      end
      return ret
    end
    local function _37_(picker, item)
      picker:close()
      if item then
        local core = require("longway.core")
        return core.sync(item.name)
      else
        return nil
      end
    end
    return Snacks.picker({source = "longway_presets", title = "Longway Presets", layout = M["build-picker-layout"](), items = items, format = _35_, confirm = _37_})
  end
end
M["pick-modified"] = function(opts)
  local Snacks = require("snacks")
  local parser = require("longway.markdown.parser")
  local diff = require("longway.sync.diff")
  local stories_dir = config["get-stories-dir"]()
  local epics_dir = config["get-epics-dir"]()
  local function _40_(finder_opts, ctx)
    local items = {}
    local story_files = vim.fn.glob((stories_dir .. "/*.md"), false, true)
    local epic_files = vim.fn.glob((epics_dir .. "/*.md"), false, true)
    local all_files = vim.list_extend((story_files or {}), (epic_files or {}))
    local idx = 0
    for _, filepath in ipairs(all_files) do
      local ok, content
      local function _41_()
        local f = io.open(filepath, "r")
        if f then
          local c = f:read("*a")
          f:close()
          return c
        else
          return nil
        end
      end
      ok, content = pcall(_41_)
      if (ok and content) then
        local parsed = parser.parse(content)
        local fm = parsed.frontmatter
        local shortcut_id = fm.shortcut_id
        if (shortcut_id and not diff["first-sync?"](fm) and diff["any-local-change?"](parsed)) then
          local changes = diff["detect-local-changes"](parsed)
          local sections = {}
          local _0
          do
            if changes.description then
              table.insert(sections, "description")
            else
            end
            if changes.tasks then
              table.insert(sections, "tasks")
            else
            end
            if changes.comments then
              _0 = table.insert(sections, "comments")
            else
              _0 = nil
            end
          end
          local has_conflict = (fm.conflict_sections ~= nil)
          local name = (fm.title or string.match(content, "# ([^\n]+)") or tostring(shortcut_id))
          idx = (idx + 1)
          table.insert(items, {text = string.format("%s %s (%s)", tostring(shortcut_id), name, table.concat(sections, ", ")), idx = idx, id = shortcut_id, name = name, file = filepath, changed_sections = sections, has_conflict = has_conflict, preview = {text = content, ft = "markdown"}})
        else
        end
      else
      end
    end
    return items
  end
  local function _48_(item, picker)
    local ret = {}
    table.insert(ret, {tostring((item.id or "")), "Number"})
    table.insert(ret, {" ", {virtual = true}})
    table.insert(ret, {(item.name or ""), "SnacksPickerLabel"})
    table.insert(ret, {(" (" .. table.concat((item.changed_sections or {}), ", ") .. ")"), "WarningMsg"})
    if item.has_conflict then
      table.insert(ret, {" CONFLICT", "ErrorMsg"})
    else
    end
    return ret
  end
  local function _50_(picker)
    local item = picker:current()
    local push_mod = require("longway.sync.push")
    if (item and item.file) then
      vim.cmd(("edit " .. item.file))
      return push_mod["push-current-buffer"]()
    else
      return nil
    end
  end
  local function _52_(picker, item)
    picker:close()
    if (item and item.file) then
      return vim.cmd(("edit " .. item.file))
    else
      return nil
    end
  end
  return Snacks.picker({source = "longway_modified", title = "Longway Modified Files", layout = M["build-picker-layout"](), finder = _40_, format = _48_, win = {input = {keys = {["<C-p>"] = {fn = _50_, mode = {"n", "i"}, desc = "Push selected file"}}}}, confirm = _52_})
end
M["pick-comments"] = function(opts)
  local Snacks = require("snacks")
  local comments_api = require("longway.api.comments")
  local members = require("longway.api.members")
  local parser = require("longway.markdown.parser")
  local opts0 = (opts or {})
  local bufnr = (opts0.bufnr or vim.api.nvim_get_current_buf())
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local parsed = parser.parse(content)
  local shortcut_id = parsed.frontmatter.shortcut_id
  if not shortcut_id then
    return notify.error("Not a longway-managed file")
  else
    local function _54_(finder_opts, ctx)
      local result = comments_api.list(shortcut_id)
      local items = {}
      if result.ok then
        for i, cmt in ipairs((result.data or {})) do
          local author_name = (members["resolve-name"](cmt.author_id) or "Unknown")
          local timestamp = (cmt.created_at or "")
          local body = (cmt.text or "")
          local fl = M["first-line"](body)
          local text = string.format("%s \226\128\148 %s", author_name, M.truncate(fl, 60))
          table.insert(items, {text = text, idx = i, id = cmt.id, author = author_name, created_at = timestamp, body = body, preview = {text = string.format("**%s** \194\183 %s\n\n%s", author_name, timestamp, body), ft = "markdown"}})
        end
      else
      end
      return items
    end
    local function _56_(item, picker)
      local ret = {}
      table.insert(ret, {(item.author or ""), "SnacksPickerLabel"})
      table.insert(ret, {(" \194\183 " .. M.truncate((item.created_at or ""), 16)), "Comment"})
      table.insert(ret, {(" \226\128\148 " .. M.truncate(M["first-line"]((item.body or "")), 50)), "Normal"})
      return ret
    end
    local function _57_(picker, item)
      picker:close()
      if item then
        local marker = ("comment:" .. tostring(item.id))
        local lines0 = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local found = false
        for i, line in ipairs(lines0) do
          if found then break end
          if string.find(line, marker, 1, true) then
            found = true
            vim.api.nvim_win_set_cursor(0, {i, 0})
          else
          end
        end
        return nil
      else
        return nil
      end
    end
    return Snacks.picker({source = "longway_comments", title = string.format("Comments \226\128\148 Story %s", tostring(shortcut_id)), layout = M["build-picker-layout"](), finder = _54_, format = _56_, confirm = _57_})
  end
end
return M