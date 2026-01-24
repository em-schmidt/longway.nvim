-- [nfnl] fnl/longway/util/slug.fnl
local config = require("longway.config")
local M = {}
M.sanitize = function(text)
  return string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.lower(text), "[%s_]+", "-"), "[^%w%-]", ""), "%-+", "-"), "^%-+", ""), "%-+$", "")
end
M.truncate = function(text, max_length)
  if (#text <= max_length) then
    return text
  else
    local truncated = string.sub(text, 1, max_length)
    local last_hyphen = string.find(truncated, "%-[^%-]*$")
    if last_hyphen then
      return string.sub(truncated, 1, (last_hyphen - 1))
    else
      return truncated
    end
  end
end
M.generate = function(title)
  local cfg = config.get()
  local max_length = (cfg.slug_max_length or 50)
  local sanitized = M.sanitize(title)
  return M.truncate(sanitized, max_length)
end
M["make-filename"] = function(id, title, type)
  local cfg = config.get()
  local slug = M.generate(title)
  local template = (cfg.filename_template or "{id}-{slug}")
  return (string.gsub(string.gsub(string.gsub(template, "{id}", tostring(id)), "{slug}", slug), "{type}", (type or "story")) .. ".md")
end
return M
