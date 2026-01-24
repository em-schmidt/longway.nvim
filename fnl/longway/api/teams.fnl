;; Teams API module for longway.nvim
;; Handles groups/teams (called "groups" in Shortcut API)

(local client (require :longway.api.client))
(local cache (require :longway.cache.store))

(local M {})

(fn M.list []
  "List all teams/groups in the workspace
   Returns: {:ok bool :data [teams] :error string}"
  (client.get "/groups"))

(fn M.get [team-id]
  "Get a specific team by ID
   Returns: {:ok bool :data team :error string}"
  (client.get (string.format "/groups/%s" team-id)))

(fn M.list-cached []
  "Get teams from cache or fetch if needed
   Returns: {:ok bool :data [teams] :error string :from-cache bool}"
  (cache.get-or-fetch :teams M.list))

(fn M.refresh-cache []
  "Force refresh the teams cache
   Returns: {:ok bool :data [teams] :error string}"
  (cache.refresh :teams M.list))

(fn M.find-by-name [name teams]
  "Find a team by name (case-insensitive partial match)
   teams: list of teams (if nil, uses cached)
   Returns: team or nil"
  (let [teams (or teams (let [result (M.list-cached)]
                          (when result.ok result.data)))
        lower-name (string.lower name)]
    (when teams
      (var found nil)
      (each [_ team (ipairs teams) &until found]
        (let [lower-team-name (string.lower (or team.name ""))]
          (when (string.find lower-team-name lower-name 1 true)
            (set found team))))
      found)))

(fn M.find-by-id [id teams]
  "Find a team by ID
   teams: list of teams (if nil, uses cached)
   Returns: team or nil"
  (let [teams (or teams (let [result (M.list-cached)]
                          (when result.ok result.data)))]
    (when teams
      (var found nil)
      (each [_ team (ipairs teams) &until found]
        (when (= team.id id)
          (set found team)))
      found)))

(fn M.get-members [team]
  "Get member IDs from a team
   Returns: [member-ids]"
  (or team.member_ids []))

(fn M.resolve-name [team-id]
  "Resolve a team ID to name using cache
   Returns: string"
  (let [team (M.find-by-id team-id)]
    (if team
        team.name
        (tostring team-id))))

M
