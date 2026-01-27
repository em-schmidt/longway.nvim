-- [nfnl] fnl/longway/ui/picker.fnl
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
local function item_preview(ctx)
  local preview_mod = require("snacks.picker.preview")
  local item = ctx.item
  if (item and item.file) then
    return preview_mod.file(ctx)
  else
    return preview_mod.preview(ctx)
  end
end
M["pick-stories"] = function(opts)
  local Snacks = require("snacks")
  local search_api = require("longway.api.search")
  local stories_api = require("longway.api.stories")
  local opts0 = (opts or {})
  local query
  local or_9_ = opts0.query
  if not or_9_ then
    if opts0.preset then
      local preset = config["get-preset"](opts0.preset)
      if preset then
        or_9_ = preset.query
      else
        or_9_ = nil
      end
    else
      or_9_ = nil
    end
  end
  if not or_9_ then
    local default = config["get-default-preset"]()
    if default then
      local preset = config["get-preset"](default)
      if preset then
        or_9_ = preset.query
      else
        or_9_ = nil
      end
    else
      or_9_ = nil
    end
  end
  query = or_9_
  local function _17_(finder_opts, ctx)
    local result
    if query then
      result = search_api["search-stories-all"](query, {max_results = 100})
    else
      result = stories_api.query({archived = false})
    end
    local items = {}
    if result.ok then
      for i, story in ipairs((result.data or {})) do
        local file = M["find-local-file"](story.id, "story")
        local state = (story.workflow_state_name or "")
        local story_type = (story.story_type or "")
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
        local label_names
        do
          local names = {}
          for _, lbl in ipairs((story.labels or {})) do
            table.insert(names, (lbl.name or ""))
          end
          label_names = table.concat(names, ", ")
        end
        local preview_text
        if story.description then
          preview_text = story.description
        else
          local _20_
          if (#owner_names > 0) then
            _20_ = ("\n**Owners:** " .. owner_names)
          else
            _20_ = ""
          end
          local _22_
          if (story.estimate and (story.estimate ~= vim.NIL)) then
            _22_ = ("\n**Estimate:** " .. tostring(story.estimate))
          else
            _22_ = ""
          end
          local function _24_()
            if (#label_names > 0) then
              return ("\n**Labels:** " .. label_names)
            else
              return ""
            end
          end
          preview_text = string.format("# %s\n\n**State:** %s\n**Type:** %s%s%s%s", (story.name or ""), state, story_type, _20_, _22_, _24_())
        end
        local text = string.format("%s %s [%s] @%s", tostring(story.id), (story.name or ""), state, owner_names)
        local _26_
        if file then
          _26_ = "file"
        else
          _26_ = {text = preview_text, ft = "markdown"}
        end
        table.insert(items, {text = text, idx = i, id = story.id, name = (story.name or ""), state = state, story_type = story_type, owners = owner_names, estimate = story.estimate, file = file, preview = _26_})
      end
    else
    end
    return items
  end
  local function _29_(item, picker)
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
  local function _32_(picker, item)
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
  return Snacks.picker({source = "longway_stories", title = "Longway Stories", layout = M["build-picker-layout"](), preview = item_preview, finder = _17_, format = _29_, confirm = _32_})
end
M["pick-epics"] = function(opts)
  local Snacks = require("snacks")
  local epics_api = require("longway.api.epics")
  local function _35_(finder_opts, ctx)
    local result = epics_api.list()
    local items = {}
    if result.ok then
      for i, epic in ipairs((result.data or {})) do
        local file = M["find-local-file"](epic.id, "epic")
        local state = (epic.state or "")
        local stats = (epic.stats or {})
        local done = (stats.num_stories_done or 0)
        local total_stories = (stats.num_stories or 0)
        local started = (stats.num_stories_started or 0)
        local unstarted = (stats.num_stories_unstarted or 0)
        local points_done = (stats.num_points_done or 0)
        local points_total = (stats.num_points or 0)
        local label_names
        do
          local names = {}
          for _, lbl in ipairs((epic.labels or {})) do
            table.insert(names, (lbl.name or ""))
          end
          label_names = table.concat(names, ", ")
        end
        local preview_text
        if epic.description then
          preview_text = epic.description
        else
          local _36_
          if (epic.planned_start_date and (epic.planned_start_date ~= vim.NIL)) then
            _36_ = ("\n**Start:** " .. epic.planned_start_date)
          else
            _36_ = ""
          end
          local _38_
          if (epic.deadline and (epic.deadline ~= vim.NIL)) then
            _38_ = ("\n**Deadline:** " .. epic.deadline)
          else
            _38_ = ""
          end
          local function _40_()
            if (#label_names > 0) then
              return ("\n**Labels:** " .. label_names)
            else
              return ""
            end
          end
          preview_text = string.format("# %s\n\n**State:** %s\n**Stories:** %d/%d done (%d started, %d unstarted)\n**Points:** %d/%d%s%s%s", (epic.name or ""), state, done, total_stories, started, unstarted, points_done, points_total, _36_, _38_, _40_())
        end
        local text = string.format("%s %s [%s] (%d/%d stories)", tostring(epic.id), (epic.name or ""), state, done, total_stories)
        local _42_
        if file then
          _42_ = "file"
        else
          _42_ = {text = preview_text, ft = "markdown"}
        end
        table.insert(items, {text = text, idx = i, id = epic.id, name = (epic.name or ""), state = state, done = done, total_stories = total_stories, file = file, preview = _42_})
      end
    else
    end
    return items
  end
  local function _45_(item, picker)
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
  local function _47_(picker, item)
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
  return Snacks.picker({source = "longway_epics", title = "Longway Epics", layout = M["build-picker-layout"](), preview = item_preview, finder = _35_, format = _45_, confirm = _47_})
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
    local _50_
    if is_default then
      _50_ = " (default)"
    else
      _50_ = ""
    end
    text = (name .. ": " .. desc .. _50_)
    local function _52_()
      if is_default then
        return "\n(default preset)"
      else
        return ""
      end
    end
    table.insert(items, {text = text, idx = idx, name = name, query = (preset.query or ""), description = desc, is_default = is_default, preview = {text = string.format("Preset: %s\nQuery: %s\nDescription: %s%s", name, (preset.query or ""), (preset.description or ""), _52_()), ft = "yaml"}})
  end
  if (#items == 0) then
    return notify.warn("No presets configured")
  else
    local function _53_(item, picker)
      local ret = {}
      table.insert(ret, {(item.name or ""), "SnacksPickerLabel"})
      table.insert(ret, {(" \226\128\148 " .. (item.description or "")), "Comment"})
      if item.is_default then
        table.insert(ret, {" (default)", "Special"})
      else
      end
      return ret
    end
    local function _55_(picker, item)
      picker:close()
      if item then
        local core = require("longway.core")
        return core.sync(item.name)
      else
        return nil
      end
    end
    return Snacks.picker({source = "longway_presets", title = "Longway Presets", layout = M["build-picker-layout"](), preview = item_preview, items = items, format = _53_, confirm = _55_})
  end
end
M["pick-modified"] = function(opts)
  local Snacks = require("snacks")
  local parser = require("longway.markdown.parser")
  local diff = require("longway.sync.diff")
  local stories_dir = config["get-stories-dir"]()
  local epics_dir = config["get-epics-dir"]()
  local function _58_(finder_opts, ctx)
    local items = {}
    local story_files = vim.fn.glob((stories_dir .. "/*.md"), false, true)
    local epic_files = vim.fn.glob((epics_dir .. "/*.md"), false, true)
    local all_files = vim.list_extend((story_files or {}), (epic_files or {}))
    local idx = 0
    for _, filepath in ipairs(all_files) do
      local ok, content
      local function _59_()
        local f = io.open(filepath, "r")
        if f then
          local c = f:read("*a")
          f:close()
          return c
        else
          return nil
        end
      end
      ok, content = pcall(_59_)
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
          table.insert(items, {text = string.format("%s %s (%s)", tostring(shortcut_id), name, table.concat(sections, ", ")), idx = idx, id = shortcut_id, name = name, file = filepath, changed_sections = sections, has_conflict = has_conflict, preview = "file"})
        else
        end
      else
      end
    end
    return items
  end
  local function _66_(item, picker)
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
  local _68_
  do
    local keymap = {mode = {"n", "i"}, desc = "Push selected file"}
    local function _69_(picker)
      local item = picker:current()
      local push_mod = require("longway.sync.push")
      if (item and item.file) then
        vim.cmd(("edit " .. item.file))
        return push_mod["push-current-buffer"]()
      else
        return nil
      end
    end
    keymap[1] = _69_
    _68_ = keymap
  end
  local function _71_(picker, item)
    picker:close()
    if (item and item.file) then
      return vim.cmd(("edit " .. item.file))
    else
      return nil
    end
  end
  return Snacks.picker({source = "longway_modified", title = "Longway Modified Files", layout = M["build-picker-layout"](), preview = item_preview, finder = _58_, format = _66_, win = {input = {keys = {["<C-p>"] = _68_}}}, confirm = _71_})
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
    local function _73_(finder_opts, ctx)
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
    local function _75_(item, picker)
      local ret = {}
      table.insert(ret, {(item.author or ""), "SnacksPickerLabel"})
      table.insert(ret, {(" \194\183 " .. M.truncate((item.created_at or ""), 16)), "Comment"})
      table.insert(ret, {(" \226\128\148 " .. M.truncate(M["first-line"]((item.body or "")), 50)), "Normal"})
      return ret
    end
    local function _76_(picker, item)
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
    return Snacks.picker({source = "longway_comments", title = string.format("Comments \226\128\148 Story %s", tostring(shortcut_id)), layout = M["build-picker-layout"](), preview = item_preview, finder = _73_, format = _75_, confirm = _76_})
  end
end
return M
