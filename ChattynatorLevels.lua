local addonName = ... ---@type string

local tostring = tostring
local gsub = string.gsub
local format = string.format
local rawset = rawset
local wipe = table.wipe

local DLAPI = DLAPI ---@type DLAPI?
local Chattynator = Chattynator
local canaccessvalue = canaccessvalue
-- The standalone LibGuildRoster (OptionalDeps: GuildRoster), when installed. LibStub exists only
-- when some addon brings it.
local GuildRosterLib = (LibStub and LibStub("LibGuildRoster-1.0", true)) --[[@as LibGuildRoster?]]

local CreateColor = CreateColor
local EventRegistry = EventRegistry

local GuildRoster = C_GuildInfo and C_GuildInfo.GuildRoster or GuildRoster
local GetNumGuildMembers = GetNumGuildMembers
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumGroupMembers = GetNumGroupMembers
local IsInRaid = IsInRaid

local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitName = UnitName
local GetRealmName = GetRealmName
local GetNormalizedRealmName = GetNormalizedRealmName
local UnitLevel = UnitLevel
local GetQuestDifficultyColor = GetQuestDifficultyColor

local thisRealm = GetRealmName()
thisRealm = gsub(thisRealm or "", "%s+", "") -- Remove spaces from realm name
---"Name-Realm" of a unit; nil while the client does not know the name or keeps it secret
---(Forever and Retail, in combat).
---@param unit string
---@return string?
local GetUnitName = function(unit)
    local name, realm = UnitName(unit)
    if not name or not canaccessvalue(name) or not canaccessvalue(realm) then return nil end
    if not realm or realm == "" then realm = thisRealm end
    return name .. "-" .. realm
end

---"Name-Realm" for a name that may come without its realm. Chattynator gives a player on the own
---realm without it (Ambiguate "none"), and so may a chat link.
---@param name string
---@return string
local function fullName(name)
    if name:find("-", 1, true) then return name end
    return name .. "-" .. thisRealm
end

local function Debug(...)
    if DLAPI then DLAPI.DebugLog(addonName, ...) end
end

---@type table<string, number> level per "Name-Realm"
local playerLevels = {}

---A player's level: read from a unit or the own guild roster, else LibGuildRoster's guild member.
---@param name string "Name-Realm"
---@return number?
local function levelOf(name)
    local level = playerLevels[name]
    if level or not GuildRosterLib then return level end
    local member = GuildRosterLib:GetMember(name)
    -- 0 or nil: a member whose level the library does not know yet.
    return member and member.level and member.level > 0 and member.level or nil
end
---@type table<number, string> coloured level text, per level
local coloredLevels = setmetatable({}, {
    ---@param tbl table<number, string>
    ---@param level number
    ---@return string
    __index = function(tbl, level)
        -- Fetch the difficulty color
        local c = GetQuestDifficultyColor(level) ---@type { r: number, g: number, b: number }
        -- Create a color object (ColorMixin) and wrap level text
        local wrapped = CreateColor(c.r, c.g, c.b):WrapTextInColorCode(tostring(level))
        Debug("level=%q, wrapped=%q", level, wrapped)
        -- Cache it
        rawset(tbl, level, wrapped)
        return wrapped
    end,
})

---@param unit string
local ScanUnit = function(unit)
    --Debug('onScanUnit', unit)
    if not unit or not UnitExists(unit) then
        --Debug('Unit does not exist: %q', unit)
        return
    end

    if not UnitIsPlayer(unit) then
        --Debug('Unit is not a player: %q', unit)
        return
    end

    local name, level = GetUnitName(unit), UnitLevel(unit)
    if not name or not level or not canaccessvalue(level) then
        --Debug('Unit=%q name=%s level=%s', unit, tostring(name), tostring(level))
        return
    end

    playerLevels[name] = level
    Debug("Scanned %q: %q %q", unit, name, level)
end

---A unit's level changed (UNIT_LEVEL): rare, so reading the unit again costs nothing.
---@param owner number EventRegistry's owner ID
---@param unit string
local function onUnitEvent(owner, unit)
    ScanUnit(unit)
end

---GUILD_ROSTER_UPDATE, without LibGuildRoster: on true the roster may be asked for again, which
---Blizzard's own guild and calendar windows do; the update that answers brings the new levels.
---@param owner number EventRegistry's owner ID
---@param canRequestRosterUpdate boolean
local function onGuildRoster(owner, canRequestRosterUpdate)
    if canRequestRosterUpdate then GuildRoster() end
    local numGuildMembers = GetNumGuildMembers()
    Debug("Guild roster update, numGuildMembers: %d", numGuildMembers)
    for i = 1, numGuildMembers do
        local name, _, _, level = GetGuildRosterInfo(i)
        if name and level then
            playerLevels[name] = level
            Debug("Guild member:%q %q", name, level)
        end
    end
    Debug("Guild roster updated")
end

local function onGroupRoster()
    local groupType = IsInRaid() and "raid" or "party"
    local numMembers = GetNumGroupMembers()
    Debug("Group roster update, groupType:%s numMembers:%s", groupType, numMembers)
    for i = 1, numMembers - (groupType == "party" and 1 or 0) do
        local unit = groupType .. i
        ScanUnit(unit)
    end
    Debug("Group roster updated")
end

---@param owner number EventRegistry's owner ID
---@param level number
local function onLevelUp(owner, level)
    wipe(coloredLevels)
    Debug("PLAYER_LEVEL_UP %q", level)
    playerLevels[fullName(UnitName("player"))] = level
end

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    -- LibGuildRoster asks for the roster at most once a minute while someone wants levels.
    if GuildRosterLib then
        GuildRosterLib:RequestLevelRefresh(addonName)
    else
        EventRegistry:RegisterFrameEventAndCallback("GUILD_ROSTER_UPDATE", onGuildRoster)
        GuildRoster()
    end
    EventRegistry:RegisterFrameEventAndCallback("GROUP_ROSTER_UPDATE", onGroupRoster)
    EventRegistry:RegisterFrameEventAndCallback("PLAYER_LEVEL_UP", onLevelUp)
    EventRegistry:RegisterFrameEventAndCallback("UNIT_LEVEL", onUnitEvent)
    --EventRegistry:RegisterFrameEventAndCallback("UPDATE_MOUSEOVER_UNIT", function()
    --    ScanUnit('mouseover')
    --end)
    --EventRegistry:RegisterFrameEventAndCallback("PLAYER_TARGET_CHANGED", function()
    --    ScanUnit('target')
    --end)
    --EventRegistry:RegisterFrameEventAndCallback("UNIT_TARGET", onUnitEvent)
    --EventRegistry:RegisterFrameEventAndCallback("NAME_PLATE_UNIT_ADDED", onUnitEvent)

    thisRealm = GetNormalizedRealmName() or thisRealm
    Debug("logged in, realm=%q", thisRealm)
    ScanUnit("player")
end)

---Injects level into displayText before the last ']' character if found, otherwise appends the level at the end.
---@param displayText string
---@param level number
---@return string
local function injectLevel(displayText, level)
    local text = coloredLevels[level] ---@type string
    -- Find last ']' position (or nil)
    local pos = displayText:match(".*()]") --[[@as integer?]]
    if pos then
        -- Insert ':level' before last ']'
        return displayText:sub(1, pos - 1) .. ":" .. text .. displayText:sub(pos)
    end
    -- Append ':level' if no ']'
    return displayText .. ":" .. text
end

-- |Hplayer:Someguy-SomeServer:529:SAY:|h[|cffc69b6dSomeguy|r]|h says: test
-- ([^:]+) → playerRealm (up to first colon)
-- ([^|]+) → rest (everything until |)
-- (.-) → non-greedy capture of anything up to next |h → this is displayText, including any color codes, brackets, etc.
local pattern = "|Hplayer:([^:]+):([^|]+)|h(.-)|h"
---@param playerRealm string
---@param rest string
---@param displayText string
---@return string
local replace = function(playerRealm, rest, displayText)
    --Debug('replace playerRealm=%q, rest=%q, displayText=%q', playerRealm, rest, displayText)
    local level = levelOf(fullName(playerRealm))
    if level then displayText = injectLevel(displayText, level) end
    return format("|Hplayer:%s:%s|h%s|h", playerRealm, rest, displayText)
end
---@param data ChattynatorMessage
local function addLevels(data)
    local name = data.typeInfo.player and data.typeInfo.player.name
    if name and levelOf(fullName(name)) then
        --Debug(gsub(data.text, '|', '||'))

        data.text = gsub(data.text, pattern, replace)
    end
end
Chattynator.API.AddModifier(addLevels)
