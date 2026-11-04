# ChattynatorLevels

[![Release](https://img.shields.io/github/v/release/Langmans/ChattynatorLevels?include_prereleases)](https://github.com/Langmans/ChattynatorLevels/releases)
[![Game Version](https://img.shields.io/badge/WoW-12.0.0-blue.svg)](https://worldofwarcraft.com)

**ChattynatorLevels** is a lightweight utility for the **Chattynator** addon designed to seamlessly integrate player levels into your World of Warcraft chat frames. It provides instant visual context to every conversation by injecting level information directly into player name links.

---

### Key Features

* **Levels in Chat:** Automatically appends player levels to names in your chat window (e.g., `[Name:90]`).
* **Smart Color Coding:** Levels are automatically colored (Grey, Green, Yellow, Orange, or Red) based on how they compare to your own character’s level.
* **Zero Manual Input:** The addon automatically scans and remembers levels from **Guild Roster**, **Party and Raid Groups** and **your own level-ups**.

---

### How it Works

The addon maintains a local database of player levels gathered from your social interactions. When a message appears in chat, **ChattynatorLevels** intercepts the text and modifies the player link:

1.  **Scanning:** It monitors game events to build a map of player levels from people you interact with.
2.  **Matching:** It identifies player links in the chat string using a robust pattern matching system.
3.  **Injecting:** It inserts the colored level string inside the brackets of the player's name for a clean, "Blizzard-native" look.

***


### Requirements

*   **Chattynator** addon (Required)

Not for WoW: Forever: Chattynator shows levels itself there (its "show level" option, on by default), for every player instead of only guild and group members.

***

### Technical Summary

For developers or those interested in the "under the hood" mechanics:

* **API Integration:** Uses the **Chattynator API** to intercept and rewrite chat strings via a custom modifier function.
* **Pattern Matching:** Employs a specific Lua `gsub` pattern to identify `|Hplayer` links and inject colored level data before the final bracket.
* **Performance Optimization:** Features a caching system using a Lua `setmetatable` to store color-wrapped level strings, ensuring minimal CPU impact during heavy chat activity.
* **Event-Driven:** Listens for `GUILD_ROSTER_UPDATE`, `GROUP_ROSTER_UPDATE`, `PLAYER_LEVEL_UP` and `UNIT_LEVEL` to maintain an accurate internal level database without constant polling. When `GUILD_ROSTER_UPDATE` says the roster changed on the server (`canRequestRosterUpdate`), the addon asks for it again, as Blizzard's own UI does, so a guildie's level-up arrives with the next update.
* **Names:** Levels are kept per "Name-Realm". Chattynator names a player on your own realm without the realm (`Ambiguate(name, "none")`), and chat links may too, so a name without one gets your realm added before the lookup.
* **Secret values:** On Forever and Retail the client can hide a unit's name and level in combat; those units are skipped (`canaccessvalue`) and picked up on the next roster update.

### Development

Tests and checks run with Lua 5.1 from the repository root:

```
lua tests/check.lua           StyLua, WoW Lua LS, then the tests with coverage
lua tests/check.lua test      the tests only
lua tests/check.lua format    formats all Lua with StyLua
```

`tests/setup-lua.ps1` installs Lua, LuaRocks, the test rocks and StyLua into `.lua\` on Windows. `tests/wow.lua` simulates the client and Chattynator. Every line of the addon must run in a test, and the WoW Lua LS must resolve every symbol's type. CI (`.github/workflows/ci.yml`) runs the same on every push.

***

> **Note:** For the best experience, ensure your Chattynator is up to date to allow proper API access for the race data modifier.

> **Note 2:** No AI was used while programming this addon. Just above description was generated.