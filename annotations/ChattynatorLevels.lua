---@meta
-- Types for the editor and the WoW Lua LS: the other addons this one talks to.

---@class ChattynatorPlayer
---@field name string? "Name-Realm", or "Name" for a player on the own realm

---@class ChattynatorTypeInfo
---@field player ChattynatorPlayer?

---@class ChattynatorMessage
---@field text string
---@field typeInfo ChattynatorTypeInfo

---@class ChattynatorAPI
---@field AddModifier fun(modifier: fun(data: ChattynatorMessage))

---@class Chattynator
---@field API ChattynatorAPI
Chattynator = {}

---@class LibGuildRosterMember
---@field name string "Name-Realm"
---@field level number? 0 or nil while the library does not know it

---LibGuildRoster-1.0 (the standalone GuildRoster addon), the part this addon uses.
---@class LibGuildRoster
local LibGuildRoster = {}

---@param name string short name or "Name-Realm"
---@return LibGuildRosterMember?
function LibGuildRoster:GetMember(name) end

---Keep guild members' levels current while held.
---@param owner any
---@return boolean
function LibGuildRoster:RequestLevelRefresh(owner) end

---@class DLAPI _DebugLog
---@field DebugLog fun(category: string, ...: any)
DLAPI = {}
