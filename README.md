# ChattynatorLevels

[![Release](https://img.shields.io/github/v/release/Langmans/ChattynatorLevels?include_prereleases&sort=semver)](https://github.com/Langmans/ChattynatorLevels/releases)
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

***

### Technical Summary

For developers or those interested in the "under the hood" mechanics:

* **API Integration:** Uses the **Chattynator API** to intercept and rewrite chat strings via a custom modifier function.
* **Pattern Matching:** Employs a specific Lua `gsub` pattern to identify `|Hplayer` links and inject colored level data before the final bracket.
* **Performance Optimization:** Features a caching system using a Lua `setmetatable` to store color-wrapped level strings, ensuring minimal CPU impact during heavy chat activity.
* **Event-Driven:** Listens for `GUILD_ROSTER_UPDATE`, `GROUP_ROSTER_UPDATE`, and `PLAYER_LEVEL_UP` to maintain an accurate internal level database without constant polling.

***

> **Note:** For the best experience, ensure your Chattynator is up to date to allow proper API access for the race data modifier.

> **Note 2:** No AI was used while programming this addon. Just above description was generated.