-- [nfnl] fnl/longway/markdown/renderer.fnl
local config = require("longway.config")
local frontmatter = require("longway.markdown.frontmatter")
local hash = require("longway.util.hash")
local slug = require("longway.util.slug")
local M = {}
local function generate_story_filename(story)
  return slug["make-filename"](story.id, story.name, "story")
end
local function build_story_frontmatter(story)
  local fm = {shortcut_id = story.id, shortcut_type = "story", shortcut_url = story.app_url, story_type = story.story_type, state = story.workflow_state_name, created_at = story.created_at, updated_at = story.updated_at}
  if story.epic_id then
    fm.epic_id = story.epic_id
  else
  end
  if story.iteration_id then
    fm.iteration_id = story.iteration_id
  else
  end
  if story.group_id then
    fm.team_id = story.group_id
  else
  end
  if story.estimate then
    fm.estimate = story.estimate
  else
  end
  if (story.owners and (#story.owners > 0)) then
    fm.owners = {}
    for _, owner in ipairs(story.owners) do
      table.insert(fm.owners, {name = owner.profile.name, id = owner.id})
    end
  else
  end
  if (story.labels and (#story.labels > 0)) then
    fm.labels = {}
    for _, label in ipairs(story.labels) do
      table.insert(fm.labels, label.name)
    end
  else
  end
  fm.sync_hash = ""
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
local function render_task(task, cfg)
  local checkbox
  if task.complete then
    checkbox = "[x]"
  else
    checkbox = "[ ]"
  end
  local owner_mention
  if (cfg.tasks.show_owners and task.owner_ids and (#task.owner_ids > 0)) then
    owner_mention = (" @" .. task.owner_ids[1])
  else
    owner_mention = ""
  end
  local metadata
  local function _9_()
    if task.complete then
      return "true"
    else
      return "false"
    end
  end
  metadata = string.format("<!-- task:%s%s complete:%s -->", tostring(task.id), owner_mention, _9_())
  return string.format("- %s %s %s", checkbox, task.description, metadata)
end
local function render_tasks(tasks)
  local cfg = config.get()
  if (not tasks or (#tasks == 0)) then
    return render_sync_section("tasks", "")
  else
    local lines = {}
    for _, task in ipairs(tasks) do
      table.insert(lines, render_task(task, cfg))
    end
    return render_sync_section("tasks", table.concat(lines, "\n"))
  end
end
local function render_comment(cmt)
  local author_name = ((cmt.author and cmt.author.profile and cmt.author.profile.name) or "Unknown")
  local timestamp
  if cmt.created_at then
    timestamp = string.sub(cmt.created_at, 1, 16)
  else
    timestamp = ""
  end
  local formatted_time = string.gsub(timestamp, "T", " ")
  local metadata = string.format("<!-- comment:%s -->", tostring(cmt.id))
  return table.concat({"---", string.format("**%s** \194\183 %s %s", author_name, formatted_time, metadata), "", (cmt.text or "")}, "\n")
end
local function render_comments(comments)
  if (not comments or (#comments == 0)) then
    return render_sync_section("comments", "")
  else
    local lines = {}
    for _, cmt in ipairs(comments) do
      table.insert(lines, render_comment(cmt))
    end
    return render_sync_section("comments", table.concat(lines, "\n\n"))
  end
end
local function render_local_notes()
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
  table.insert(sections, render_local_notes())
  local body = table.concat(sections, "\n")
  local full_content = (frontmatter.generate(fm_data) .. "\n\n" .. body)
  fm_data.sync_hash = hash["content-hash"](story.description)
  return (frontmatter.generate(fm_data) .. "\n\n" .. body)
end
local function build_epic_frontmatter(epic)
  return {shortcut_id = epic.id, shortcut_type = "epic", shortcut_url = epic.app_url, state = epic.state, planned_start_date = epic.planned_start_date, deadline = epic.deadline, created_at = epic.created_at, updated_at = epic.updated_at, sync_hash = "", local_updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"), stats = (epic.stats or {})}
end
local function render_story_link(story)
  local filename = generate_story_filename(story)
  return string.format("[%s](../stories/%s)", story.name, filename)
end
local function render_story_state_badge(story)
  local state = (story.workflow_state_name or "Unknown")
  if string.find(string.lower(state), "done") then
    return ("\226\156\147 " .. state)
  elseif string.find(string.lower(state), "progress") then
    return ("\226\134\146 " .. state)
  else
    return state
  end
end
local function render_epic_stats(epic)
  local stats = (epic.stats or {})
  local function _16_()
    if (stats.num_stories and (stats.num_stories > 0)) then
      return math.floor((((stats.num_stories_done or 0) / stats.num_stories) * 100))
    else
      return 0
    end
  end
  return string.format("**Progress:** %d/%d stories done (%d%%)", (stats.num_stories_done or 0), (stats.num_stories or 0), _16_())
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
      local owner_name
      if (story.owners and (#story.owners > 0)) then
        owner_name = story.owners[1].profile.name
      else
        owner_name = "-"
      end
      local points = (story.estimate or "-")
      local status_icon
      if story.completed then
        status_icon = "\226\156\147"
      elseif story.started then
        status_icon = "\226\134\146"
      else
        status_icon = "\226\151\139"
      end
      local story_link = render_story_link(story)
      table.insert(sections, string.format("| %s | %s | %s | %s | %s |", status_icon, story_link, (story.workflow_state_name or "-"), owner_name, points))
    end
  else
  end
  if epic.milestone_id then
    table.insert(sections, "")
    table.insert(sections, string.format("**Milestone:** %s", (epic.milestone_id or "-")))
  else
  end
  table.insert(sections, "")
  table.insert(sections, render_local_notes())
  local body = table.concat(sections, "\n")
  fm_data.sync_hash = hash["content-hash"]((epic.description or ""))
  return (frontmatter.generate(fm_data) .. "\n\n" .. body)
end
return M
