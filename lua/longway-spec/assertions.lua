-- [nfnl] fnl/longway-spec/assertions.fnl
local say = require("say")
local assert = require("luassert")
local function has_substring(state, args)
  local haystack = args[1]
  local needle = args[2]
  return (haystack and needle and (nil ~= string.find(haystack, needle, 1, true)))
end
say:set("assertion.has_substring.positive", "Expected string to contain substring.\nString: %s\nSubstring: %s")
say:set("assertion.has_substring.negative", "Expected string NOT to contain substring.\nString: %s\nSubstring: %s")
assert:register("assertion", "has_substring", has_substring, "assertion.has_substring.positive", "assertion.has_substring.negative")
local function is_valid_slug(state, args)
  local slug = args[1]
  return ((type(slug) == "string") and (#slug > 0) and not string.find(slug, "[^a-z0-9%-]") and not string.match(slug, "^%-") and not string.match(slug, "%-$"))
end
say:set("assertion.is_valid_slug.positive", "Expected '%s' to be a valid slug (lowercase alphanumeric with hyphens, no leading/trailing hyphens)")
say:set("assertion.is_valid_slug.negative", "Expected '%s' NOT to be a valid slug")
assert:register("assertion", "is_valid_slug", is_valid_slug, "assertion.is_valid_slug.positive", "assertion.is_valid_slug.negative")
local function is_valid_hash(state, args)
  local hash = args[1]
  return ((type(hash) == "string") and (#hash == 8) and string.match(hash, "^%x+$"))
end
say:set("assertion.is_valid_hash.positive", "Expected '%s' to be a valid 8-character hex hash")
say:set("assertion.is_valid_hash.negative", "Expected '%s' NOT to be a valid hash")
assert:register("assertion", "is_valid_hash", is_valid_hash, "assertion.is_valid_hash.positive", "assertion.is_valid_hash.negative")
local function has_frontmatter(state, args)
  local content = args[1]
  return (content and string.match(content, "^%-%-%-\n") and string.find(content, "\n%-%-%-\n", 4))
end
say:set("assertion.has_frontmatter.positive", "Expected content to have valid YAML frontmatter")
say:set("assertion.has_frontmatter.negative", "Expected content NOT to have frontmatter")
assert:register("assertion", "has_frontmatter", has_frontmatter, "assertion.has_frontmatter.positive", "assertion.has_frontmatter.negative")
local function has_sync_section(state, args)
  local content = args[1]
  local section_name = args[2]
  local start_marker = ("<!-- BEGIN SHORTCUT SYNC:" .. section_name .. " -->")
  local end_marker = ("<!-- END SHORTCUT SYNC:" .. section_name .. " -->")
  return (content and string.find(content, start_marker, 1, true) and string.find(content, end_marker, 1, true))
end
say:set("assertion.has_sync_section.positive", "Expected content to have sync section '%s'")
say:set("assertion.has_sync_section.negative", "Expected content NOT to have sync section '%s'")
assert:register("assertion", "has_sync_section", has_sync_section, "assertion.has_sync_section.positive", "assertion.has_sync_section.negative")
return {["has-substring"] = has_substring, ["is-valid-slug"] = is_valid_slug, ["is-valid-hash"] = is_valid_hash, ["has-frontmatter"] = has_frontmatter, ["has-sync-section"] = has_sync_section}
