-- [nfnl] fnl/longway/sync/comments.fnl
local comments_api = require("longway.api.comments")
local comments_md = require("longway.markdown.comments")
local config = require("longway.config")
local notify = require("longway.ui.notify")
local M = {}
local function build_remote_comment_map(remote_comments)
  local comment_map = {}
  for _, cmt in ipairs((remote_comments or {})) do
    if cmt.id then
      comment_map[cmt.id] = cmt
    else
    end
  end
  return comment_map
end
M.diff = function(local_comments, remote_comments)
  local remote_map = build_remote_comment_map(remote_comments)
  local seen_ids = {}
  local created = {}
  local deleted = {}
  local edited = {}
  local unchanged = {}
  for _, local_cmt in ipairs((local_comments or {})) do
    if local_cmt.is_new then
      table.insert(created, local_cmt)
    else
      if local_cmt.id then
        seen_ids[local_cmt.id] = true
        local remote_cmt = remote_map[local_cmt.id]
        if not remote_cmt then
          local_cmt.is_new = true
          local_cmt.id = nil
          table.insert(created, local_cmt)
        else
          if comments_md["comment-changed?"](local_cmt, remote_cmt) then
            table.insert(edited, local_cmt)
          else
            table.insert(unchanged, local_cmt)
          end
        end
      else
      end
    end
  end
  for _, remote_cmt in ipairs((remote_comments or {})) do
    if (remote_cmt.id and not seen_ids[remote_cmt.id]) then
      table.insert(deleted, remote_cmt.id)
    else
    end
  end
  return {created = created, deleted = deleted, edited = edited, unchanged = unchanged}
end
M["has-changes?"] = function(diff)
  return ((#diff.created > 0) or (#diff.deleted > 0))
end
local function push_created_comments(story_id, comments)
  local result_comments = {}
  local errors = {}
  for _, cmt in ipairs(comments) do
    local result = comments_api.create(story_id, {text = cmt.text})
    if result.ok then
      cmt.id = result.data.id
      cmt.is_new = false
      if result.data.created_at then
        cmt.timestamp = comments_md["format-timestamp"](result.data.created_at)
      else
      end
      table.insert(result_comments, cmt)
    else
      table.insert(errors, string.format("Create comment: %s", (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), comments = result_comments, errors = errors}
end
local function push_deleted_comments(story_id, comment_ids)
  local deleted = {}
  local errors = {}
  for _, comment_id in ipairs(comment_ids) do
    local result = comments_api.delete(story_id, comment_id)
    if result.ok then
      table.insert(deleted, comment_id)
    else
      table.insert(errors, string.format("Delete comment %s: %s", tostring(comment_id), (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), deleted = deleted, errors = errors}
end
M.push = function(story_id, local_comments, remote_comments, opts)
  local opts0 = (opts or {})
  local diff = M.diff(local_comments, remote_comments)
  local all_errors = {}
  local result_comments = {}
  if not M["has-changes?"](diff) then
    if (#diff.edited > 0) then
      notify.warn(string.format("%d comment(s) edited locally. Shortcut does not support comment editing \226\128\148 changes will not sync.", #diff.edited))
    else
    end
    return {ok = true, created = 0, deleted = 0, warned = #diff.edited, errors = {}, comments = local_comments}
  else
  end
  if (#diff.created > 0) then
    notify.info(string.format("Creating %d new comment(s)...", #diff.created))
    local create_result = push_created_comments(story_id, diff.created)
    for _, cmt in ipairs(create_result.comments) do
      table.insert(result_comments, cmt)
    end
    for _, err in ipairs(create_result.errors) do
      table.insert(all_errors, err)
    end
  else
  end
  for _, cmt in ipairs(diff.unchanged) do
    table.insert(result_comments, cmt)
  end
  if (#diff.edited > 0) then
    notify.warn(string.format("%d comment(s) edited locally. Shortcut does not support comment editing \226\128\148 changes will not sync.", #diff.edited))
    for _, cmt in ipairs(diff.edited) do
      table.insert(result_comments, cmt)
    end
  else
  end
  local deleted_count = 0
  if ((#diff.deleted > 0) and not opts0.skip_delete) then
    notify.info(string.format("Deleting %d comment(s)...", #diff.deleted))
    local delete_result = push_deleted_comments(story_id, diff.deleted)
    deleted_count = #delete_result.deleted
    for _, err in ipairs(delete_result.errors) do
      table.insert(all_errors, err)
    end
  else
  end
  local created_count = #diff.created
  local warned_count = #diff.edited
  if (#all_errors == 0) then
    notify.info(string.format("Comments synced: %d created, %d deleted", created_count, deleted_count))
  else
    notify.warn(string.format("Comment sync completed with %d error(s)", #all_errors))
  end
  return {ok = (#all_errors == 0), created = created_count, deleted = deleted_count, warned = warned_count, errors = all_errors, comments = result_comments}
end
M.pull = function(story_id)
  local cfg = config.get()
  local result = comments_api.list(story_id)
  if not result.ok then
    return {error = result.error, comments = {}, ok = false}
  else
    local raw_comments = (result.data or {})
    local limited
    if (cfg.comments.max_pull and (#raw_comments > cfg.comments.max_pull)) then
      local trimmed = {}
      for i = 1, cfg.comments.max_pull do
        table.insert(trimmed, raw_comments[i])
      end
      limited = trimmed
    else
      limited = raw_comments
    end
    local formatted = comments_md["format-api-comments"](limited)
    return {ok = true, comments = formatted}
  end
end
M.merge = function(local_comments, remote_comments, previous_comments)
  local prev_map = build_remote_comment_map(previous_comments)
  local remote_map = build_remote_comment_map(remote_comments)
  local local_map = build_remote_comment_map(local_comments)
  local merged = {}
  local conflicts = {}
  local remote_added = {}
  local remote_deleted = {}
  for _, cmt in ipairs(local_comments) do
    if cmt.is_new then
      table.insert(merged, cmt)
    else
      if cmt.id then
        local remote = remote_map[cmt.id]
        local prev = prev_map[cmt.id]
        if not remote then
          if prev then
            table.insert(remote_deleted, cmt.id)
          else
            table.insert(merged, cmt)
          end
        else
          local local_changed = (prev and comments_md["comment-changed?"](cmt, prev))
          local remote_changed = (prev and comments_md["comment-changed?"](remote, prev))
          if (local_changed and remote_changed) then
            table.insert(conflicts, cmt.id)
            table.insert(merged, cmt)
          else
            table.insert(merged, cmt)
          end
        end
      else
      end
    end
  end
  for _, remote_cmt in ipairs(remote_comments) do
    if not local_map[remote_cmt.id] then
      if prev_map[remote_cmt.id] then
      else
        table.insert(remote_added, remote_cmt)
        table.insert(merged, {id = remote_cmt.id, author = remote_cmt.author, timestamp = remote_cmt.timestamp, text = (remote_cmt.text or ""), is_new = false})
      end
    else
    end
  end
  return {comments = merged, conflicts = conflicts, remote_added = remote_added, remote_deleted = remote_deleted}
end
return M
