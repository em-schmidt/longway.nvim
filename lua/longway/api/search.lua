-- [nfnl] fnl/longway/api/search.fnl
local client = require("longway.api.client")
local M = {}
local QUERY_FIELDS = {owner = "owner_id", owner_id = "owner_id", state = "workflow_state_id", state_id = "workflow_state_id", workflow_state = "workflow_state_id", iteration = "iteration_id", iteration_id = "iteration_id", sprint = "iteration_id", team = "group_id", team_id = "group_id", group = "group_id", group_id = "group_id", epic = "epic_id", epic_id = "epic_id", type = "story_type", story_type = "story_type", label = "label_id", label_id = "label_id", project = "project_id", project_id = "project_id", archived = "archived", completed = "completed", started = "started"}
local SPECIAL_VALUES = {me = "current-member", current = "current-iteration", backlog = "backlog-iteration"}
local function parse_query_string(query_str)
  local params = {}
  if (query_str and (#query_str > 0)) then
    for key, value in string.gmatch(query_str, "(%w+):([^%s]+)") do
      local api_field = QUERY_FIELDS[key]
      if api_field then
        params[api_field] = value
      else
        params[key] = value
      end
    end
  else
  end
  return params
end
M["search-stories"] = function(query, opts)
  local search_params = {query = (query or "")}
  local opts0 = (opts or {})
  if opts0.page_size then
    search_params["page_size"] = opts0.page_size
  else
  end
  if opts0.next then
    search_params["next"] = opts0.next
  else
  end
  if opts0.params then
    for k, v in pairs(opts0.params) do
      search_params[k] = v
    end
  else
  end
  return client.get("/search/stories", {query = search_params})
end
M["search-stories-all"] = function(query, opts)
  local opts0 = (opts or {})
  local max_results = (opts0.max_results or 500)
  local all_stories = {}
  local page_size = 25
  local cursor = nil
  local done = false
  local error = nil
  while (not done and not error and (#all_stories < max_results)) do
    local result = M["search-stories"](query, {page_size = page_size, next = cursor, params = opts0.params})
    if not result.ok then
      error = result.error
    else
      local data = result.data
      local stories = (data.data or {})
      for _, story in ipairs(stories) do
        if (#all_stories < max_results) then
          table.insert(all_stories, story)
        else
        end
      end
      if (data.next and (#stories > 0)) then
        cursor = data.next
      else
        done = true
      end
    end
  end
  if error then
    return {error = error, ok = false}
  else
    return {ok = true, data = all_stories}
  end
end
M["search-epics"] = function(query, opts)
  local search_params = {query = (query or "")}
  local opts0 = (opts or {})
  if opts0.page_size then
    search_params["page_size"] = opts0.page_size
  else
  end
  if opts0.next then
    search_params["next"] = opts0.next
  else
  end
  return client.get("/search/epics", {query = search_params})
end
M["build-query"] = function(filters)
  local parts = {}
  for field, value in pairs(filters) do
    if (value and (value ~= "")) then
      if ((field == "archived") or (field == "completed") or (field == "started")) then
        if value then
          local _12_
          if value then
            _12_ = "true"
          else
            _12_ = "false"
          end
          table.insert(parts, (field .. ":" .. _12_))
        else
        end
      else
        if string.find(value, " ") then
          table.insert(parts, (field .. ":\"" .. value .. "\""))
        else
          table.insert(parts, (field .. ":" .. value))
        end
      end
    else
    end
  end
  return table.concat(parts, " ")
end
M["parse-query"] = function(query_str)
  local params = parse_query_string(query_str)
  local remaining_text = string.gsub(query_str, "%w+:[^%s]+", "")
  local trimmed_text = string.gsub(string.gsub(remaining_text, "^%s+", ""), "%s+$", "")
  return {query = trimmed_text, params = params}
end
return M
