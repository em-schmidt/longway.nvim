;; Members API module for longway.nvim
;; Handles workspace members/users

(local client (require :longway.api.client))
(local cache (require :longway.cache.store))

(local M {})

(fn M.list []
  "List all members in the workspace
   Returns: {:ok bool :data [members] :error string}"
  (client.get "/members"))

(fn M.get-current []
  "Get the current authenticated member
   Returns: {:ok bool :data member :error string}"
  (client.get "/member"))

(fn M.get [member-id]
  "Get a specific member by ID
   Returns: {:ok bool :data member :error string}"
  (client.get (string.format "/members/%s" member-id)))

(fn M.list-cached []
  "Get members from cache or fetch if needed
   Returns: {:ok bool :data [members] :error string :from-cache bool}"
  (cache.get-or-fetch :members M.list))

(fn M.refresh-cache []
  "Force refresh the members cache
   Returns: {:ok bool :data [members] :error string}"
  (cache.refresh :members M.list))

(fn M.find-by-name [name members]
  "Find a member by display name (case-insensitive partial match)
   members: list of members (if nil, uses cached members)
   Returns: member or nil"
  (let [members (or members (let [result (M.list-cached)]
                              (when result.ok result.data)))
        lower-name (string.lower name)]
    (when members
      (var found nil)
      (each [_ member (ipairs members) &until found]
        (let [profile (or member.profile {})
              display-name (or profile.name profile.mention_name member.id "")
              lower-display (string.lower display-name)]
          (when (string.find lower-display lower-name 1 true)
            (set found member))))
      found)))

(fn M.find-by-id [id members]
  "Find a member by ID
   members: list of members (if nil, uses cached members)
   Returns: member or nil"
  (let [members (or members (let [result (M.list-cached)]
                              (when result.ok result.data)))]
    (when members
      (var found nil)
      (each [_ member (ipairs members) &until found]
        (when (= member.id id)
          (set found member)))
      found)))

(fn M.get-display-name [member]
  "Get the display name for a member
   Returns: string"
  (let [profile (or member.profile {})]
    (or profile.name
        profile.mention_name
        member.id
        "Unknown")))

(fn M.resolve-name [member-id]
  "Resolve a member ID to display name using cache
   Returns: string"
  (let [member (M.find-by-id member-id)]
    (if member
        (M.get-display-name member)
        member-id)))

M
