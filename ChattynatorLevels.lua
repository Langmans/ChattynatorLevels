local addonName = ...

local tostring = tostring
local gsub = string.gsub
local format = string.format
local rawset = rawset
local wipe = table.wipe

local DLAPI = DLAPI

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
local GetUnitName = function(unit)
    local name, realm = UnitName(unit)
    if not name then
        return nil
    end
    if not realm or realm == "" then
        realm = thisRealm
    end
    return name .. "-" .. realm
end

---@type function(any, ...): void
local function Debug(...)
    if DLAPI then
        DLAPI.DebugLog(addonName, ...)
    end
end

local playerLevels = {}
local coloredLevels = setmetatable({},{
    __index = function(tbl, level)
        -- Fetch the difficulty color
        local c = GetQuestDifficultyColor(level)
        -- Create a color object (ColorMixin) and wrap level text
        local wrapped = CreateColor(c.r, c.g, c.b):WrapTextInColorCode(tostring(level))
        Debug('level=%q, wrapped=%q', level, wrapped)
        -- Cache it
        rawset(tbl, level, wrapped)
        return wrapped
    end
})

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
    if not name or not level then
        --Debug('Unit=%q name=%s level=%s', unit, tostring(name), tostring(level))
        return
    end

    playerLevels[name] = level
    Debug('Scanned %q: %q %q', unit, name, level)
end

--[[
local onUnitEvent = function(_, unit)
    ScanUnit(unit)
end
]]

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    EventRegistry:RegisterFrameEventAndCallback("GUILD_ROSTER_UPDATE", function()
        local numGuildMembers = GetNumGuildMembers()
        --Debug('Guild roster update, numGuildMembers: %d', numGuildMembers)
        for i = 1, numGuildMembers do
            local name, _, _, level = GetGuildRosterInfo(i)
            if name and level then
                playerLevels[name] = level
                Debug('Guild member:%q %q', name, level)
            end
        end
        --Debug('Guild roster updated')
    end)
    EventRegistry:RegisterFrameEventAndCallback("GROUP_ROSTER_UPDATE", function()
        local groupType = IsInRaid() and "raid" or "party"
        local numMembers = GetNumGroupMembers()
        Debug('Group roster update, groupType:%s numMembers:%s', groupType, numMembers)
        for i = 1, numMembers - (groupType == "party" and 1 or 0) do
            local unit = groupType .. i
            ScanUnit(unit)
        end
        Debug('Group roster updated')
    end)
    EventRegistry:RegisterFrameEventAndCallback("PLAYER_LEVEL_UP", function(_, level)
        wipe(coloredLevels)
        Debug('PLAYER_LEVEL_UP %q', level)
        playerLevels[GetUnitName('player')] = level
    end)
    --EventRegistry:RegisterFrameEventAndCallback("UPDATE_MOUSEOVER_UNIT", function()
    --    ScanUnit('mouseover')
    --end)
    --EventRegistry:RegisterFrameEventAndCallback("PLAYER_TARGET_CHANGED", function()
    --    ScanUnit('target')
    --end)
    --EventRegistry:RegisterFrameEventAndCallback("UNIT_TARGET", onUnitEvent)
    --EventRegistry:RegisterFrameEventAndCallback("UNIT_LEVEL", onUnitEvent)
    --EventRegistry:RegisterFrameEventAndCallback("NAME_PLATE_UNIT_ADDED", onUnitEvent)

    GuildRoster()
    thisRealm = GetNormalizedRealmName() or thisRealm
    Debug('logged in, realm=%q', thisRealm)
    ScanUnit('player')
end)

-- Injects level into displayText before the last ']' character if found, otherwise appends the level at the end.
local function injectLevel(displayText, level)
    level = coloredLevels[level] or tostring(level)
    -- Find last ']' position (or nil)
    local pos = displayText:match(".*()]")
    if pos then
        -- Insert ':level' before last ']'
        return displayText:sub(1, pos - 1) .. ":" .. level .. displayText:sub(pos)
    end
    -- Append ':level' if no ']'
    return displayText .. ":" .. level
end

-- |Hplayer:Someguy-SomeServer:529:SAY:|h[|cffc69b6dSomeguy|r]|h says: test
-- ([^:]+) → playerRealm (up to first colon)
-- ([^|]+) → rest (everything until |)
-- (.-) → non-greedy capture of anything up to next |h → this is displayText, including any color codes, brackets, etc.
local pattern = "|Hplayer:([^:]+):([^|]+)|h(.-)|h"
local replace = function(playerRealm, rest, displayText)
    --Debug('replace playerRealm=%q, rest=%q, displayText=%q', playerRealm, rest, displayText)
    local level = playerLevels[playerRealm]
    if level then
        displayText = injectLevel(displayText, level)
    end
    return format("|Hplayer:%s:%s|h%s|h", playerRealm, rest, displayText)
end
Chattynator.API.AddModifier(function(data)
    if data.typeInfo.player and data.typeInfo.player.name and playerLevels[data.typeInfo.player.name] then
        --Debug(gsub(data.text, '|', '||'))

        data.text = gsub(data.text, pattern, replace)
    end
end)