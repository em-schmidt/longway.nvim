-- [nfnl] fnl/longway/sync/diff.fnl
local hash = require("longway.util.hash")
local M = {}
M["first-sync?"] = function(frontmatter)
  local sync_hash = (frontmatter.sync_hash or "")
  return (sync_hash == "")
end
M["compute-section-hashes"] = function(parsed)
  local content_hash = hash["content-hash"]
  return {description = content_hash((parsed.description or "")), tasks = hash["tasks-hash"]((parsed.tasks or {})), comments = hash["comments-hash"]((parsed.comments or {}))}
end
M["detect-local-changes"] = function(parsed)
  local fm = parsed.frontmatter
  local current = M["compute-section-hashes"](parsed)
  local stored_desc = (fm.sync_hash or "")
  local stored_tasks = (fm.tasks_hash or "")
  local stored_comments = (fm.comments_hash or "")
  return {description = (current.description ~= stored_desc), tasks = (current.tasks ~= stored_tasks), comments = (current.comments ~= stored_comments)}
end
M["any-local-change?"] = function(parsed)
  local changes = M["detect-local-changes"](parsed)
  return (changes.description or changes.tasks or changes.comments)
end
M["detect-remote-change"] = function(frontmatter, remote_updated_at)
  local stored = (frontmatter.updated_at or "")
  return ((remote_updated_at ~= nil) and (remote_updated_at ~= "") and (remote_updated_at ~= stored))
end
M.classify = function(parsed, remote_updated_at)
  local fm = parsed.frontmatter
  local local_changes = M["detect-local-changes"](parsed)
  local has_local = (local_changes.description or local_changes.tasks or local_changes.comments)
  local remote_changed = M["detect-remote-change"](fm, remote_updated_at)
  local status
  if (has_local and remote_changed) then
    status = "conflict"
  elseif has_local then
    status = "local-only"
  elseif remote_changed then
    status = "remote-only"
  else
    status = "clean"
  end
  return {status = status, local_changes = local_changes, remote_changed = remote_changed}
end
return M
