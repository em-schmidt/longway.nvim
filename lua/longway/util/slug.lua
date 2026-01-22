-- Slug generation utilities for longway.nvim
-- Compiled from fnl/longway/util/slug.fnl

local config = require("longway.config")

local M = {}

function M.sanitize(text)
  local result = text
  -- Convert to lowercase
  result = result:lower()
  -- Replace spaces and underscores with separator
  result = result:gsub("[%s_]+", "-")
  -- Remove non-alphanumeric characters (except hyphens)
  result = result:gsub("[^%w%-]", "")
  -- Collapse multiple hyphens
  result = result:gsub("%-+", "-")
  -- Remove leading/trailing hyphens
  result = result:gsub("^%-+", "")
  result = result:gsub("%-+$", "")
  return result
end

function M.truncate(text, max_length)
  if #text <= max_length then
    return text
  end
  local truncated = text:sub(1, max_length)
  local last_hyphen = truncated:find("%-[^%-]*$")
  if last_hyphen then
    return truncated:sub(1, last_hyphen - 1)
  else
    return truncated
  end
end

function M.generate(title)
  local cfg = config.get()
  local max_length = cfg.slug_max_length or 50
  local sanitized = M.sanitize(title)
  return M.truncate(sanitized, max_length)
end

function M.make_filename(id, title, item_type)
  local cfg = config.get()
  local slug = M.generate(title)
  local template = cfg.filename_template or "{id}-{slug}"
  local result = template
  result = result:gsub("{id}", tostring(id))
  result = result:gsub("{slug}", slug)
  result = result:gsub("{type}", item_type or "story")
  return result .. ".md"
end

return M
