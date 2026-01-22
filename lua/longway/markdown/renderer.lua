-- Markdown renderer for longway.nvim
-- Compiled from fnl/longway/markdown/renderer.fnl

local config = require("longway.config")
local frontmatter = require("longway.markdown.frontmatter")
local hash = require("longway.util.hash")

local M = {}

local function build_story_frontmatter(story)
  local fm = {
    shortcut_id = story.id,
    shortcut_type = "story",
    shortcut_url = story.app_url,
    story_type = story.story_type,
    state = story.workflow_state_name,
    created_at = story.created_at,
    updated_at = story.updated_at,
  }

  -- Optional fields
  if story.epic_id then
    fm.epic_id = story.epic_id
  end
  if story.iteration_id then
    fm.iteration_id = story.iteration_id
  end
  if story.group_id then
    fm.team_id = story.group_id
  end
  if story.estimate then
    fm.estimate = story.estimate
  end

  -- Owners
  if story.owners and #story.owners > 0 then
    fm.owners = {}
    for _, owner in ipairs(story.owners) do
      table.insert(fm.owners, { name = owner.profile.name, id = owner.id })
    end
  end

  -- Labels
  if story.labels and #story.labels > 0 then
    fm.labels = {}
    for _, label in ipairs(story.labels) do
      table.insert(fm.labels, label.name)
    end
  end

  -- Sync hashes
  fm.sync_hash = ""
  fm.local_updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ")

  return fm
end

local function render_sync_section(section_name, content)
  local cfg = config.get()
  local start_marker = cfg.sync_start_marker:gsub("{section}", section_name)
  local end_marker = cfg.sync_end_marker:gsub("{section}", section_name)
  return start_marker .. "\n" .. content .. "\n" .. end_marker
end

local function render_description(description)
  return render_sync_section("description", description or "")
end

local function render_task(task, cfg)
  local checkbox = task.complete and "[x]" or "[ ]"
  local owner_mention = ""
  if cfg.tasks.show_owners and task.owner_ids and #task.owner_ids > 0 then
    owner_mention = " @" .. task.owner_ids[1]
  end
  local metadata = string.format("<!-- task:%s%s complete:%s -->",
    tostring(task.id),
    owner_mention,
    task.complete and "true" or "false")
  return string.format("- %s %s %s", checkbox, task.description, metadata)
end

local function render_tasks(tasks)
  local cfg = config.get()
  if not tasks or #tasks == 0 then
    return render_sync_section("tasks", "")
  end

  local lines = {}
  for _, task in ipairs(tasks) do
    table.insert(lines, render_task(task, cfg))
  end
  return render_sync_section("tasks", table.concat(lines, "\n"))
end

local function render_comment(comment)
  local author_name = "Unknown"
  if comment.author and comment.author.profile and comment.author.profile.name then
    author_name = comment.author.profile.name
  end

  local timestamp = ""
  if comment.created_at then
    timestamp = comment.created_at:sub(1, 16)  -- YYYY-MM-DDTHH:MM
  end
  local formatted_time = timestamp:gsub("T", " ")

  local metadata = string.format("<!-- comment:%s -->", tostring(comment.id))

  return table.concat({
    "---",
    string.format("**%s** · %s %s", author_name, formatted_time, metadata),
    "",
    comment.text or "",
  }, "\n")
end

local function render_comments(comments)
  if not comments or #comments == 0 then
    return render_sync_section("comments", "")
  end

  local lines = {}
  for _, comment in ipairs(comments) do
    table.insert(lines, render_comment(comment))
  end
  return render_sync_section("comments", table.concat(lines, "\n\n"))
end

local function render_local_notes()
  return table.concat({
    "## Local Notes",
    "",
    "<!-- This section is NOT synced to Shortcut -->",
    "",
  }, "\n")
end

function M.render_story(story)
  local cfg = config.get()
  local fm_data = build_story_frontmatter(story)

  local sections = {
    "# " .. story.name,
    "",
    "## Description",
    "",
    render_description(story.description),
  }

  -- Tasks section
  if cfg.sync_sections.tasks then
    table.insert(sections, "")
    table.insert(sections, "## Tasks")
    table.insert(sections, "")
    table.insert(sections, render_tasks(story.tasks))
  end

  -- Comments section
  if cfg.sync_sections.comments then
    table.insert(sections, "")
    table.insert(sections, "## Comments")
    table.insert(sections, "")
    table.insert(sections, render_comments(story.comments))
  end

  -- Local notes section
  table.insert(sections, "")
  table.insert(sections, render_local_notes())

  -- Build full content
  local body = table.concat(sections, "\n")

  -- Compute sync hash
  fm_data.sync_hash = hash.content_hash(story.description or "")

  return frontmatter.generate(fm_data) .. "\n\n" .. body
end

local function build_epic_frontmatter(epic)
  return {
    shortcut_id = epic.id,
    shortcut_type = "epic",
    shortcut_url = epic.app_url,
    state = epic.state,
    planned_start_date = epic.planned_start_date,
    deadline = epic.deadline,
    created_at = epic.created_at,
    updated_at = epic.updated_at,
    sync_hash = "",
    local_updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    stats = epic.stats or {},
  }
end

function M.render_epic(epic, stories)
  local fm_data = build_epic_frontmatter(epic)

  local sections = {
    "# " .. epic.name,
    "",
    "## Description",
    "",
    render_sync_section("description", epic.description or ""),
  }

  -- Stories table
  if stories and #stories > 0 then
    table.insert(sections, "")
    table.insert(sections, "## Stories")
    table.insert(sections, "")
    table.insert(sections, "| ID | Title | State | Owner | Points |")
    table.insert(sections, "|----|-------|-------|-------|--------|")

    for _, story in ipairs(stories) do
      local owner_name = "-"
      if story.owners and #story.owners > 0 then
        owner_name = story.owners[1].profile.name
      end
      local points = story.estimate or "-"
      table.insert(sections, string.format("| %s | %s | %s | %s | %s |",
        story.id,
        story.name,
        story.workflow_state_name or "-",
        owner_name,
        points))
    end
  end

  -- Local notes
  table.insert(sections, "")
  table.insert(sections, render_local_notes())

  -- Build full content
  local body = table.concat(sections, "\n")
  fm_data.sync_hash = hash.content_hash(epic.description or "")

  return frontmatter.generate(fm_data) .. "\n\n" .. body
end

return M
