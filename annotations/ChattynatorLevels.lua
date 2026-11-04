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

---@class DLAPI _DebugLog
---@field DebugLog fun(category: string, ...: any)
DLAPI = {}
