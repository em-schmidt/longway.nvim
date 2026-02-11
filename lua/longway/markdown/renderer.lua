-- [nfnl] fnl/longway/markdown/renderer.fnl
local config = require("longway.config")
local frontmatter = require("longway.markdown.frontmatter")
local hash = require("longway.util.hash")
local slug = require("longway.util.slug")
local tasks_md = require("longway.markdown.tasks")
local comments_md = require("longway.markdown.comments")
local M = {}
local MAX_COL_WIDTH = 35
local function nil_safe(value, fallback)
  if ((value == nil) or ((type(value) == "userdata") and (value == vim.NIL))) then
    return fallback
  else
    return value
  end
end
local function truncate(text, max_len)
  if (not text or (#text <= max_len)) then
    return text
  else
    return (string.sub(text, 1, (max_len - 3)) .. "...")
  end
end
local function generate_story_filename(story)
  return slug["make-filename"](story.id, story.name, "story")
end
local function build_story_frontmatter(story)
  local fm = {shortcut_id = story.id, shortcut_type = "story", shortcut_url = nil_safe(story.app_url), story_type = nil_safe(story.story_type), state = nil_safe(story.workflow_state_name), created_at = nil_safe(story.created_at), updated_at = nil_safe(story.updated_at)}
  do
    local epic_id = nil_safe(story.epic_id)
    local iteration_id = nil_safe(story.iteration_id)
    local group_id = nil_safe(story.group_id)
    local estimate = nil_safe(story.estimate)
    if epic_id then
      fm.epic_id = epic_id
    else
    end
    if iteration_id then
      fm.iteration_id = iteration_id
    else
    end
    if group_id then
      fm.team_id = group_id
    else
    end
    if estimate then
      fm.estimate = estimate
    else
    end
  end
  if (story.owners and (type(story.owners) ~= "userdata") and (#story.owners > 0)) then
    fm.owners = {}
    for _, owner in ipairs(story.owners) do
      table.insert(fm.owners, {name = nil_safe(owner.profile.name, "Unknown"), id = owner.id})
    end
  else
  end
  if (story.labels and (type(story.labels) ~= "userdata") and (#story.labels > 0)) then
    fm.labels = {}
    for _, label in ipairs(story.labels) do
      table.insert(fm.labels, label.name)
    end
  else
  end
  fm.sync_hash = ""
  fm.tasks_hash = ""
  fm.comments_hash = ""
  fm.local_updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
  return fm
end
local function render_sync_section(section_name, content)
  local cfg = config.get()
  local start_marker = string.gsub(cfg.sync_start_marker, "{section}", section_name)
  local end_marker = string.gsub(cfg.sync_end_marker, "{section}", section_name)
  return (start_marker .. "\n" .. content .. "\n" .. end_marker)
end
local function render_description(description)
  local desc = (description or "")
  return render_sync_section("description", desc)
end
local function render_tasks(tasks)
  if (not tasks or (#tasks == 0)) then
    return render_sync_section("tasks", "")
  else
    local formatted = tasks_md["format-api-tasks"](tasks)
    local content = tasks_md["render-tasks"](formatted)
    return render_sync_section("tasks", content)
  end
end
local function render_comments(comments)
  if (not comments or (#comments == 0)) then
    return render_sync_section("comments", "")
  else
    local content = comments_md["render-comments"](comments)
    return render_sync_section("comments", content)
  end
end
M["render-local-notes"] = function()
  return table.concat({"## Local Notes", "", "<!-- This section is NOT synced to Shortcut -->", ""}, "\n")
end
M["render-story"] = function(story)
  local cfg = config.get()
  local fm_data = build_story_frontmatter(story)
  local sections = {("# " .. story.name), "", "## Description", "", render_description(story.description)}
  if cfg.sync_sections.tasks then
    table.insert(sections, "")
    table.insert(sections, "## Tasks")
    table.insert(sections, "")
    table.insert(sections, render_tasks(story.tasks))
  else
  end
  if cfg.sync_sections.comments then
    table.insert(sections, "")
    table.insert(sections, "## Comments")
    table.insert(sections, "")
    table.insert(sections, render_comments(story.comments))
  else
  end
  table.insert(sections, "")
  table.insert(sections, M["render-local-notes"]())
  local body = table.concat(sections, "\n")
  local full_content = (frontmatter.generate(fm_data) .. "\n\n" .. body)
  local parser = require("longway.markdown.parser")
  local re_parsed = parser.parse(full_content)
  fm_data.sync_hash = hash["content-hash"]((re_parsed.description or ""))
  fm_data.tasks_hash = hash["tasks-hash"]((re_parsed.tasks or {}))
  fm_data.comments_hash = hash["comments-hash"]((re_parsed.comments or {}))
  return (frontmatter.generate(fm_data) .. "\n\n" .. body)
end
local function build_epic_frontmatter(epic)
  local stats = nil_safe(epic.stats, {})
  return {shortcut_id = epic.id, shortcut_type = "epic", shortcut_url = nil_safe(epic.app_url), state = nil_safe(epic.state), planned_start_date = nil_safe(epic.planned_start_date), deadline = nil_safe(epic.deadline), created_at = nil_safe(epic.created_at), updated_at = nil_safe(epic.updated_at), sync_hash = "", local_updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"), stats = stats}
end
local function render_story_link(story)
  local filename = generate_story_filename(story)
  local display_name = truncate(story.name, MAX_COL_WIDTH)
  return string.format("[%s](../stories/%s)", display_name, filename)
end
local function render_story_state_badge(story)
  local state = nil_safe(story.workflow_state_name, "Unknown")
  if string.find(string.lower(state), "done") then
    return ("\226\156\147 " .. state)
  elseif string.find(string.lower(state), "progress") then
    return ("\226\134\146 " .. state)
  else
    return state
  end
end
local function render_epic_stats(epic)
  local stats = nil_safe(epic.stats, {})
  local num_done = nil_safe(stats.num_stories_done, 0)
  local num_total = nil_safe(stats.num_stories, 0)
  local function _14_()
    if (num_total and (num_total > 0)) then
      return math.floor(((num_done / num_total) * 100))
    else
      return 0
    end
  end
  return string.format("**Progress:** %d/%d stories done (%d%%)", num_done, num_total, _14_())
end
M["render-epic"] = function(epic, stories)
  local fm_data = build_epic_frontmatter(epic)
  local sections = {("# " .. epic.name), "", render_epic_stats(epic), "", "## Description", "", render_sync_section("description", (epic.description or ""))}
  if (stories and (#stories > 0)) then
    table.insert(sections, "")
    table.insert(sections, "## Stories")
    table.insert(sections, "")
    table.insert(sections, "| Status | Title | State | Owner | Points |")
    table.insert(sections, "|:------:|-------|-------|-------|-------:|")
    for _, story in ipairs(stories) do
      local owners = nil_safe(story.owners)
      local owner_name
      if (owners and (#owners > 0)) then
        owner_name = nil_safe(owners[1].profile.name, "-")
      else
        owner_name = "-"
      end
      local points = nil_safe(story.estimate, "-")
      local completed = nil_safe(story.completed)
      local started = nil_safe(story.started)
      local status_icon
      if completed then
        status_icon = "\226\156\147"
      elseif started then
        status_icon = "\226\134\146"
      else
        status_icon = "\226\151\139"
      end
      local story_link = render_story_link(story)
      table.insert(sections, string.format("| %s | %s | %s | %s | %s |", status_icon, story_link, truncate(nil_safe(story.workflow_state_name, "-"), MAX_COL_WIDTH), truncate(owner_name, MAX_COL_WIDTH), points))
    end
  else
  end
  if nil_safe(epic.milestone_id) then
    table.insert(sections, "")
    table.insert(sections, string.format("**Milestone:** %s", nil_safe(epic.milestone_id, "-")))
  else
  end
  table.insert(sections, "")
  table.insert(sections, M["render-local-notes"]())
  local body = table.concat(sections, "\n")
  local full_content = (frontmatter.generate(fm_data) .. "\n\n" .. body)
  local parser = require("longway.markdown.parser")
  local re_parsed = parser.parse(full_content)
  fm_data.sync_hash = hash["content-hash"]((re_parsed.description or ""))
  return (frontmatter.generate(fm_data) .. "\n\n" .. body)
end
return M
