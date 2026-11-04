-- A simulated client: the parts of the game and Chattynator the addon touches. NewClient() resets
-- the globals, loads the .toc's files and logs in.
--
-- The player is "Me" on "Argent Dawn" (normalized "ArgentDawn"). A level's colour is "ff" plus
-- the level as two digits and the player's level as two more, so a test can read which levels
-- went into it: level 10 seen by a level 20 player is "|cff1020ff10|r".

---@class TestMember
---@field unit string "party1", "raid3"
---@field name string? the unit's name, nil while the client does not know it yet
---@field realm string? the unit's realm, nil on the player's own
---@field level number
---@field isPlayer boolean? default true
---@field secret boolean? the client hides name and level (Forever and Retail, in combat)

---@class TestGuildMember
---@field name string "Name-Realm", as the roster has it
---@field level number

---@class TestClientOptions
---@field level number? the player's level, default 20
---@field guild TestGuildMember[]? default none
---@field group TestMember[]? default none
---@field raid boolean? the group is a raid
---@field debugLog boolean? _DebugLog is loaded
---@field noGuildInfo boolean? the client has the old global GuildRoster, not C_GuildInfo's
---@field guildRosterLib table<string, number>? LibGuildRoster is installed, with these
---  "Name-Realm" -> level members (0 = a level it does not know yet)

---@param options TestClientOptions?
function NewClient(options)
    options = options or {}
    local client = {
        level = options.level or 20,
        guild = options.guild or {},
        group = options.group or {},
        raid = options.raid or false,
        events = {},
        modifiers = {},
        rosterRequests = 0,
        logged = {},
    }

    ---@param event string
    function client:Fire(event, ...)
        for _, callback in ipairs(self.events[event] or {}) do
            callback("owner", ...)
        end
    end

    ---The text Chattynator shows for a line, after the modifiers. name is what Chattynator puts in
    ---typeInfo.player.name: Ambiguate(sender, "none"), without the realm for the player's own realm.
    ---@param name string
    ---@param text string? default a guild line from name, linked as the chat event names it
    ---@return string
    function client:Chat(name, text)
        local data = {
            text = text or ("|Hplayer:%s:1:GUILD|h[|cffc69b6d%s|r]|h: hello"):format(name, name:match("^[^-]+")),
            typeInfo = { player = { name = name } },
        }
        for _, modifier in ipairs(self.modifiers) do
            modifier(data)
        end
        return data.text
    end

    local function member(unit)
        for _, m in ipairs(client.group) do
            if m.unit == unit then return m end
        end
    end

    _G.EventRegistry = {
        RegisterFrameEventAndCallback = function(_, event, callback)
            client.events[event] = client.events[event] or {}
            table.insert(client.events[event], callback)
        end,
    }
    _G.Chattynator = {
        API = {
            AddModifier = function(modifier)
                table.insert(client.modifiers, modifier)
            end,
        },
    }
    _G.DLAPI = options.debugLog
            and {
                DebugLog = function(_, ...)
                    table.insert(client.logged, (select(1, ...)))
                end,
            }
        or nil
    table.wipe = function(t)
        for k in pairs(t) do
            t[k] = nil
        end
        return t
    end
    _G.GetRealmName = function()
        return "Argent Dawn"
    end
    _G.GetNormalizedRealmName = function()
        return "ArgentDawn"
    end
    _G.C_GuildInfo = not options.noGuildInfo
            and {
                GuildRoster = function()
                    client.rosterRequests = client.rosterRequests + 1
                end,
            }
        or nil
    _G.GuildRoster = function()
        client.rosterRequests = client.rosterRequests + 1
    end
    _G.GetNumGuildMembers = function()
        return #client.guild
    end
    _G.GetGuildRosterInfo = function(i)
        local m = client.guild[i]
        return m.name, "Rank", 1, m.level
    end
    _G.GetNumGroupMembers = function()
        return #client.group > 0 and #client.group + 1 or 0
    end
    _G.IsInRaid = function()
        return client.raid
    end
    _G.UnitExists = function(unit)
        return unit == "player" or member(unit) ~= nil
    end
    _G.UnitIsPlayer = function(unit)
        return unit == "player" or member(unit).isPlayer ~= false
    end
    -- A hidden value: joining it into a string errors, as using one does in the client.
    local SECRET = setmetatable({}, {
        __concat = function()
            error("used a secret value")
        end,
    })
    _G.canaccessvalue = function(value)
        return not rawequal(value, SECRET)
    end
    _G.UnitName = function(unit)
        if unit == "player" then return "Me", nil end
        local m = member(unit)
        if m.secret then return SECRET, SECRET end
        return m.name, m.realm
    end
    _G.UnitLevel = function(unit)
        if unit == "player" then return client.level end
        local m = member(unit)
        return m.secret and SECRET or m.level
    end
    _G.GetQuestDifficultyColor = function(level)
        return { r = level, g = client.level, b = 255 }
    end
    _G.CreateColor = function(r, g, b)
        return {
            WrapTextInColorCode = function(_, text)
                return ("|cff%02d%02d%02x%s|r"):format(r, g, b, text)
            end,
        }
    end

    -- LibStub exists only when an addon brings it; here, the standalone LibGuildRoster.
    _G.LibStub = nil
    if options.guildRosterLib then
        local members = options.guildRosterLib
        local lib = { refreshHolders = {} }
        client.guildRosterLib = lib
        function lib:GetMember(name)
            if not name:find("-", 1, true) then name = name .. "-ArgentDawn" end
            return members[name] and { name = name, level = members[name] }
        end
        function lib:RequestLevelRefresh(owner)
            self.refreshHolders[owner] = true
            return true
        end
        _G.LibStub = setmetatable({}, {
            __call = function(_, major, silent)
                assert(major == "LibGuildRoster-1.0" and silent, "asked LibStub for " .. tostring(major))
                return lib
            end,
        })
    end

    for _, file in ipairs(TOC_FILES) do
        assert(loadfile(file))("ChattynatorLevels", {})
    end
    client:Fire("PLAYER_LOGIN")
    return client
end
