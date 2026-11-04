-- Which level a player gets in Chattynator, and where the addon learns it.
-- Colours are readable codes, see tests/wow.lua: "|cff1020ff10|r" is level 10 seen at level 20.

local function guildLine(link, display)
    return ("|Hplayer:%s:1:GUILD|h[|cffc69b6d%s|r]|h: hello"):format(link, display)
end

describe("a chat line", function()
    it("shows the player's own level, under the name Chattynator gives without the realm", function()
        local client = NewClient()
        assert.equal(guildLine("Me", "Me|r:|cff2020ff20"), client:Chat("Me"))
    end)

    it("shows the player's own level when the link names the realm", function()
        local client = NewClient()
        local text = guildLine("Me-ArgentDawn", "Me")
        assert.equal(guildLine("Me-ArgentDawn", "Me|r:|cff2020ff20"), client:Chat("Me", text))
    end)

    it("shows a guild member's level from the player's own realm", function()
        local client = NewClient({ guild = { { name = "Bob-ArgentDawn", level = 10 } } })
        client:Fire("GUILD_ROSTER_UPDATE")
        assert.equal(guildLine("Bob", "Bob|r:|cff1020ff10"), client:Chat("Bob"))
    end)

    it("shows a guild member's level from another realm", function()
        local client = NewClient({ guild = { { name = "Ann-Other", level = 60 } } })
        client:Fire("GUILD_ROSTER_UPDATE")
        assert.equal(guildLine("Ann-Other", "Ann|r:|cff6020ff60"), client:Chat("Ann-Other"))
    end)

    it("puts the level at the end of a link without brackets", function()
        local client = NewClient({ guild = { { name = "Ann-Other", level = 60 } } })
        client:Fire("GUILD_ROSTER_UPDATE")
        local text = "|Hplayer:Ann-Other:1:SAY|hAnn|h says: hi"
        assert.equal("|Hplayer:Ann-Other:1:SAY|hAnn:|cff6020ff60|r|h says: hi", client:Chat("Ann-Other", text))
    end)

    it("gives each linked player their own level, and leaves unknown ones alone", function()
        local client =
            NewClient({ guild = { { name = "Ann-Other", level = 60 }, { name = "Bob-ArgentDawn", level = 10 } } })
        client:Fire("GUILD_ROSTER_UPDATE")
        local text = "|Hplayer:Ann-Other:1|h[Ann]|h to |Hplayer:Bob:2|h[Bob]|h and |Hplayer:Cid:3|h[Cid]|h"
        assert.equal(
            "|Hplayer:Ann-Other:1|h[Ann:|cff6020ff60|r]|h to |Hplayer:Bob:2|h[Bob:|cff1020ff10|r]|h and |Hplayer:Cid:3|h[Cid]|h",
            client:Chat("Ann-Other", text)
        )
    end)

    it("stays as it is from a player without a known level", function()
        local client = NewClient()
        assert.equal(guildLine("Cid", "Cid"), client:Chat("Cid"))
    end)

    it("stays as it is without a player", function()
        local client = NewClient()
        local data = { text = "System message", typeInfo = {} }
        client.modifiers[1](data)
        assert.equal("System message", data.text)
    end)
end)

describe("levels are learned", function()
    it("from the guild roster, which the addon asks for at login", function()
        local client = NewClient()
        assert.equal(1, client.rosterRequests)
    end)

    it("from the guild roster again when the server says it changed, as Blizzard's UI asks", function()
        local ann = { name = "Ann-Other", level = 10 }
        local client = NewClient({ guild = { ann } })
        client:Fire("GUILD_ROSTER_UPDATE", false)
        assert.equal(1, client.rosterRequests)
        ann.level = 11
        client:Fire("GUILD_ROSTER_UPDATE", true)
        assert.equal(2, client.rosterRequests)
        client:Fire("GUILD_ROSTER_UPDATE", false)
        assert.equal(2, client.rosterRequests)
        assert.equal(guildLine("Ann-Other", "Ann|r:|cff1120ff11"), client:Chat("Ann-Other"))
    end)

    it("from the guild roster on clients with the old global GuildRoster", function()
        local client = NewClient({ noGuildInfo = true })
        assert.equal(1, client.rosterRequests)
    end)

    it("from party members, realm or not", function()
        local client = NewClient({
            group = {
                { unit = "party1", name = "Bob", level = 12 },
                { unit = "party2", name = "Ann", realm = "Other", level = 61 },
            },
        })
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.equal(guildLine("Bob", "Bob|r:|cff1220ff12"), client:Chat("Bob"))
        assert.equal(guildLine("Ann-Other", "Ann|r:|cff6120ff61"), client:Chat("Ann-Other"))
    end)

    it("from a group member's level-up, without a roster change", function()
        local bob = { unit = "party1", name = "Bob", level = 12 }
        local client = NewClient({ group = { bob } })
        client:Fire("GROUP_ROSTER_UPDATE")
        bob.level = 13
        client:Fire("UNIT_LEVEL", "party1")
        assert.equal(guildLine("Bob", "Bob|r:|cff1320ff13"), client:Chat("Bob"))
    end)

    it("from raid members", function()
        local client = NewClient({ group = { { unit = "raid1", name = "Bob", level = 12 } }, raid = true })
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.equal(guildLine("Bob", "Bob|r:|cff1220ff12"), client:Chat("Bob"))
    end)

    it("not from units that are no players", function()
        local client = NewClient({ group = { { unit = "party1", name = "Wolf", level = 5, isPlayer = false } } })
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.equal(guildLine("Wolf", "Wolf"), client:Chat("Wolf"))
    end)

    it("not from a member whose name the client does not know yet, until it does", function()
        local bob = { unit = "party1", level = 12 }
        local client = NewClient({ group = { bob } })
        client:Fire("GROUP_ROSTER_UPDATE")
        bob.name = "Bob"
        assert.equal(guildLine("Bob", "Bob"), client:Chat("Bob"))
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.equal(guildLine("Bob", "Bob|r:|cff1220ff12"), client:Chat("Bob"))
    end)

    it("not from a member whose name the client keeps secret, without an error", function()
        local client = NewClient({ group = { { unit = "party1", name = "Bob", level = 12, secret = true } } })
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.equal(guildLine("Bob", "Bob"), client:Chat("Bob"))
    end)

    it("from the player's level-up, which recolours everyone's", function()
        local client = NewClient({ guild = { { name = "Ann-Other", level = 10 } } })
        client:Fire("GUILD_ROSTER_UPDATE")
        client.level = 21
        client:Fire("PLAYER_LEVEL_UP", 21)
        assert.equal(guildLine("Me", "Me|r:|cff2121ff21"), client:Chat("Me"))
        assert.equal(guildLine("Ann-Other", "Ann|r:|cff1021ff10"), client:Chat("Ann-Other"))
    end)
end)

describe("with LibGuildRoster installed", function()
    it("takes guild members' levels from it, own realm or not", function()
        local client = NewClient({ guildRosterLib = { ["Bob-ArgentDawn"] = 10, ["Ann-Other"] = 60 } })
        assert.equal(guildLine("Bob", "Bob|r:|cff1020ff10"), client:Chat("Bob"))
        assert.equal(guildLine("Ann-Other", "Ann|r:|cff6020ff60"), client:Chat("Ann-Other"))
    end)

    it("asks it to keep the levels current, and leaves the roster requests to it", function()
        local client = NewClient({ guildRosterLib = {} })
        assert.is_true(client.guildRosterLib.refreshHolders.ChattynatorLevels)
        client:Fire("GUILD_ROSTER_UPDATE", true)
        assert.equal(0, client.rosterRequests)
    end)

    it("shows no level for a member whose level it does not know yet", function()
        local client = NewClient({ guildRosterLib = { ["Bob-ArgentDawn"] = 0 } })
        assert.equal(guildLine("Bob", "Bob"), client:Chat("Bob"))
    end)

    it("still shows group members' levels, read from the units", function()
        local client = NewClient({ guildRosterLib = {}, group = { { unit = "party1", name = "Cid", level = 7 } } })
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.equal(guildLine("Cid", "Cid|r:|cff0720ff7"), client:Chat("Cid"))
    end)
end)

describe("_DebugLog", function()
    it("gets the levels the addon learns when it is loaded", function()
        local client = NewClient({ debugLog = true })
        assert.is_true(#client.logged > 0)
    end)
end)
