local ADDON_DB_NAME = "LootDB"
local ADDON_DEFAULTS = {
    profile = {
        enable = true,
        debug = false,
        test = false,
        session = {
            duration = 20, -- 20 seconds by default (This number has been derived from testing in an actual raid setting)
            maxroll = 100,
            minroll = 1,
            selfroll = true
        },
        minimap = {
            hide = false
        },
        windows = {
            main = {},
            session = {}
        },
        encounter = {
            auto = false
        },
        encounters = {
            ["2398"] = { -- Shriekwing
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            },
            ["2418"] = { -- Huntsman Altimor
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            },
            ["2412"] = { -- The Council of Blood
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            },
            ["2406"] = { -- Lady Inerva Darkvein
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            },
            ["2405"] = { -- Artificer Xy'mox
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            },
            ["2402"] = { -- Sun King's Salvation
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            },
            ["2399"] = { -- Sludgefist
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            },
            ["2383"] = { -- Hungering Destroyer
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            },
            ["2417"] = { -- Stone Legion Generals
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            },
            ["2407"] = { -- Sire Denathrius
                ["RAIDFINDER"] = false,
                ["NORMAL"] = true,
                ["HEROIC"] = true,
                ["MYTHIC"] = true
            }
        }
    },
    char = {},
    global = {
        retention = {
            current = {
                hours = 2
            },
            previous = {
                hours = 12
            },
        },
        roll = nil,
        items = {},
        sessions = {}
    }
}

-- Setup a variety of assets being used by this addon.
local ADDON_BROKER_ICON_ACTIVE = "Interface/Icons/INV_Misc_HearthstoneCard_Legendary"
local ADDON_BROKER_ICON_INACTIVE = "Interface/Icons/INV_Misc_HearthstoneCard_Common"

local READY_CHECK_WAITING_TEXTURE = "Interface/RaidFrame/ReadyCheck-Waiting"
local READY_CHECK_READY_TEXTURE = "Interface/RaidFrame/ReadyCheck-Ready"
local READY_CHECK_NOT_READY_TEXTURE = "Interface/RaidFrame/ReadyCheck-NotReady"

-- System events the addon uses to derive information about loot from the game.
local ADDON_EVENTS = {
    "ZONE_CHANGED", -- Used to prompt the addon to collect new information about your instance.
    "RAID_INSTANCE_WELCOME", -- Used to prompt the addon to collect new information about your instance.
    "UPDATE_INSTANCE_INFO", -- Used to collect data about the current instance.
    "BOSS_KILL", -- Used to automatically request loot from people after a boss dies.
    "CHAT_MSG_SYSTEM", -- Used to figure out what person has rolled.
    "CHAT_MSG_LOOT", -- Used to figure out what items has dropped.
    "CHAT_MSG_WHISPER" -- Used to collect eligable loot from other people in the group.
}

-- Message events sent and received internally.
local ADDON_MESSAGES = {
    "ADDON_LOOT_UI_ACTION_WINDOW_OPEN", -- Prompts the addon to show the loot window.
    "ADDON_LOOT_UI_ACTION_WINDOW_CLOSE", -- Prompts the addon to close the loot window.
    "ADDON_LOOT_UI_ACTION_WINDOW_TOGGLE", -- Prompts the addon to toggle the loot window.
    "ADDON_LOOT_UI_ACTION_SHOW_OPTIONS", -- Prompts the addon to show the options window.
    "ADDON_LOOT_UI_ACTION_DISCARD_ITEM", -- Prompts the addon to discard a shared item.
    "ADDON_LOOT_UI_WINDOW_OPEN", -- Happens when the loot window is opened.
    "ADDON_LOOT_UI_WINDOW_CLOSE", -- Happens when the loot window is closed.
    "ADDON_LOOT_PLAYER_ROLL", -- Happens when a player rolls.
    "ADDON_LOOT_PLAYER_ITEM_ACQUIRED", -- Happens when a player loots an item.
    "ADDON_LOOT_PLAYER_ITEM_SHARED", -- Happens when a player shares an item raid by providing it to the loot master (person responsible of the loot sessions).
    "ADDON_LOOT_SESSION_BEGIN", -- Happens at the beginning of a session.
    "ADDON_LOOT_SESSION_TICK", -- Happens at each tick (second) of a loot session's count down.
    "ADDON_LOOT_SESSION_ROLL", -- Happens when a player has joined a loot session with a roll.
    "ADDON_LOOT_SESSION_END", -- Happens at the end of a session.
    "ADDON_LOOT_SESSION_END_ANNOUNCEMENT", -- Happens when a result of a loot session is announced.
    "ADDON_LOOT_ITEM_DISCARDED", -- Happens when an item is discarded from the proposed items.
    "ADDON_LOOT_ITEM_PROPOSED", -- Happens when an item has been proposed to the group for rolling.
}

-- Load the dependencies for this addon.
local AceGUI = LibStub("AceGUI-3.0")
local AceEvent = LibStub("AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")

-- Construct the addon with embeded plugins.
local Addon = LibStub("AceAddon-3.0"):NewAddon("Loot",
    "AceConsole-3.0", -- Used for the slash command
    "AceTimer-3.0", -- Used for the loot rolls
    "AceEvent-3.0" -- Used for internal addon communication
)

-- This function is used to print debug information from the addon when in debug mode.
function Addon:Debug(message, ...)
    if self.db.profile.debug then
        self:Printf(message, ...)
    end
end

function Addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(ADDON_DB_NAME, ADDON_DEFAULTS, true)
    self.icon = LibStub("LibDBIcon-1.0")
    self.broker = LibStub("LibDataBroker-1.1"):NewDataObject("Loot", {
        type = "data source",
        text = "Loot",
        icon = ADDON_BROKER_ICON_INACTIVE,
        OnClick = function(event, button)
            local options = {
                ["LeftButton"] = function() self:SendMessage("ADDON_LOOT_UI_ACTION_WINDOW_TOGGLE") end,
                ["RightButton"] = function() self:SendMessage("ADDON_LOOT_UI_ACTION_SHOW_OPTIONS") end
            }
            if options[button] then options[button]() end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("Loot")
            tooltip:AddLine("Tracking and assisting personal loot sharing", 1, 1, 1)
            tooltip:AddDoubleLine("Left click", "Toggle loot manager window")
            tooltip:AddDoubleLine("Right click", "Open addon configuration")
            tooltip:Show()
        end
    })

    local profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(self.db)
    profiles.order = -1
    profiles.disabled = false

    self.profiles = profiles
    self.options = {
        type = "group",
        name = "Loot",
        args = {
            enable = {
                name = "Enable",
                desc = "Toggle to disable or enable the addon completely",
                descStyle = "inline",
                width = "double",
                type = "toggle",
                order = 1,
                set = function(info, val)
                    self.db.profile.enable = val
                    if val then
                        self:Enable()
                    else
                        self:Disable()
                    end
                end,
                get = function(info)
                    return self.db.profile.enable
                end
            },
            debug = {
                name = "Debug",
                desc = "Toggle to disable or enable debug messages in the chat window",
                descStyle = "inline",
                width = "double",
                type = "toggle",
                order = 2,
                set = function(info, val) self.db.profile.debug = val end,
                get = function(info) return self.db.profile.debug end,
                disabled = function(options) return not self.db.profile.enable end
            },
            icon = {
                name = "Hide Minimap Icon",
                desc = "Toggle the visibility of the addon map icon",
                descStyle = "inline",
                width = "double",
                type = "toggle",
                order = 3,
                set = function(info, val)
                    self.db.profile.minimap.hide = val
                    if val then
                        self.icon:Hide("Loot")
                    elseif self.db.profile.enable then
                        self.icon:Show("Loot")
                    end
                end,
                get = function(info)
                    return self.db.profile.minimap.hide
                end,
                disabled = function(options) return not self.db.profile.enable end
            },
            test = {
                name = "Activate Test Mode",
                desc = "Toggle the test mode on or off, this will cause items from your bags to all appear in the UI",
                descStyle = "inline",
                width = "double",
                type = "toggle",
                order = 4,
                set = function(info, val) self.db.profile.test = val end,
                get = function(info) return self.db.profile.test end,
                disabled = function(options) return not self.db.profile.enable end
            }
        }
    }

    self.sessionconfig = {
        type = "group",
        name = "Roll Sessions",
        args = {
            selfroll = {
                name = "Allow rolling for own items",
                desc = "Toggle on or off to enable the person to roll for their own items",
                descStyle = "inline",
                width = "double",
                type = "toggle",
                order = 1,
                set = function(info, val) self.db.profile.session.selfroll = val end,
                get = function(info) return self.db.profile.session.selfroll end
            },
            duration = {
                name = "Time to roll in seconds",
                desc = "How many seconds a player has to roll after loot has been proposed to the raid.",
                width = "double",
                type = "range",
                order = 2,
                step = 1,
                min = 5,
                max = 60,
                set = function(info, val) self.db.profile.session.duration = val end,
                get = function(info) return self.db.profile.session.duration end,
            },
            minroll = {
                name = "Minimum roll number",
                desc = "The smallest value that can be rolled by players.",
                width = "double",
                type = "range",
                order = 3,
                step = 1,
                min = 0,
                max = 99,
                validate = function(info, val)
                    if val >= self.db.profile.session.maxroll then
                        return "Minimum roll number needs to be smaller than the maximum one"
                    end
                    return true
                end,
                set = function(info, val) self.db.profile.session.minroll = val end,
                get = function(info) return self.db.profile.session.minroll end,
            },
            maxroll = {
                name = "Maximum roll number",
                desc = "The largest value that can be rolled by players.",
                width = "double",
                type = "range",
                order = 4,
                step = 1,
                min = 1,
                max = 100,
                validate = function(info, val)
                    if val <= self.db.profile.session.minroll then
                        return "Maximum roll number needs to be larger than the minimum one"
                    end
                    return true
                end,
                set = function(info, val) self.db.profile.session.maxroll = val end,
                get = function(info) return self.db.profile.session.maxroll end,
            }
        },
    }

    self.retentionconfig = {
        type = "group",
        name = "Data Retention",
        args = {
            proposed = {
                name = "Currently Proposed Items",
                desc = "The amount of hours currently proposed items should be kept",
                width = "double",
                type = "range",
                order = 4,
                step = 1,
                min = 1,
                max = 48,
                set = function(info, val) self.db.global.retention.current.hours = val end,
                get = function(info) return self.db.global.retention.current.hours end,
            },
            previous = {
                name = "Previous Roll Results",
                desc = "The amount of hours previous roll results should be kept",
                width = "double",
                type = "range",
                order = 4,
                step = 1,
                min = 1,
                max = 48,
                set = function(info, val) self.db.global.retention.previous.hours = val end,
                get = function(info) return self.db.global.retention.previous.hours end,
            }
        }
    }

    local getEncounterState = function(encounterID, difficulty)
        local encounter = self.db.profile.encounters[encounterID] or {}
        return encounter[difficulty] or false
    end
    local setEncounterState = function(encounterID, difficulty, value)
        if not self.db.profile.encounter.auto then
            return nil
        end
        local encounter = self.db.profile.encounters[encounterID] or {}
        encounter[difficulty] = value
        self.db.profile.encounters[encounterID] = encounter
    end

    local instances = {
        auto = {
            name = "Enable automatic sessions on boss kills",
            desc = "Automatically start a loot session after a raid encounter has been successfully completed. This will open the loot window and announce to the raid that loot can be whispered to you.",
            descStyle = "inline",
            width = "full",
            type = "toggle",
            order = 1,
            set = function(options, value) self.db.profile.encounter.auto = value end,
            get = function(options) return self.db.profile.encounter.auto end
        }
    }
    for i, instance in ipairs(RAID_INSTANCES) do
        local encounters = {}
        for j, encounter in ipairs(instance.encounters) do
            local difficulties = {}
            for k, difficulty in ipairs(encounter.difficulties) do
                difficulties[difficulty] = {
                    name = RAID_DIFFICULTIES[difficulty],
                    width = "half",
                    type = "toggle",
                    order = k+1,
                    disabled = function(options) return not self.db.profile.encounter.auto end,
                    set = function(options, value) return setEncounterState(encounter.id, difficulty, value) end,
                    get = function(options) return getEncounterState(encounter.id, difficulty) end
                }
            end

            encounters[encounter.id] = {
                type = "group",
                name = encounter.name,
                order = j+1,
                inline = true,
                args = difficulties
            }
        end
    
        instances[instance.id] = {
            type = "group",
            name = instance.name,
            order = i+2,
            args = encounters
        }
    end

    self.encounters = {
        type = "group",
        name = "Raid Encounters",
        descStyle = "inline",
        args = instances
    }

    -- Set up some common state variables
    self.is_in_party_or_raid = false
    self.current_difficulty = "NORMAL"

    -- Setup the items cache
    self.items = {}

    -- Register a blizzard addon configuration frame for general addon configuration.
    AceConfig:RegisterOptionsTable("LootOptions", self.options, {"lc"})
    self.optionsframe = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LootOptions", "Loot", nil)

    -- Register a blizzard addon configuration frame for enabling different encounters.
    AceConfig:RegisterOptionsTable("LootSession", self.sessionconfig, {"lcs"})
    self.sessionconfigframe = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LootSession", "Roll Sessions", "Loot")

    -- Register a blizzard addon configuration frame for enabling different encounters.
    AceConfig:RegisterOptionsTable("LootRetention", self.retentionconfig, {"lch"})
    self.retentionconfigframe = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LootRetention", "Data Rentention", "Loot")

    -- Register a blizzard addon configuration frame for enabling different encounters.
    AceConfig:RegisterOptionsTable("LootEncounters", self.encounters, {"lce"})
    self.encountersframe = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LootEncounters", "Raid Encounters", "Loot")

    -- Register a blizzard addon configuration frame for switching profiles.
    AceConfig:RegisterOptionsTable("LootProfiles", self.profiles, {"lcp"})
    self.profileframe = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LootProfiles", "Profiles", "Loot")
    
    -- Register "loot" and "l" as commands to use in the WoW chat to display the loot window.
    self:RegisterChatCommand("l", function() self:SendMessage("ADDON_LOOT_UI_ACTION_WINDOW_OPEN") end)
    self:RegisterChatCommand("loot", function() self:SendMessage("ADDON_LOOT_UI_ACTION_WINDOW_OPEN") end)

    self.icon:Register("Loot", self.broker, self.db.profile.minimap)
end

function Addon:OnEnable()
    -- Iterate over all bags and add the contents to the items array.
    self.items = {}
    if self.db.profile.test then
        self.items = GenerateTestItems()
    end

    -- Clear out all sessions older than a set amount of hours when adodn loads.
    -- TODO: Replace this with a losely coupled list of session IDs in sequential order that can be stored individually.
    local t = time() -- Curent time in unix seconds
    local maxlife = self.db.global.retention.previous.hours * 3600 -- Number of seconds since the oldest session allowed.
    local sessions = {}
    for id, sess in pairs(self.db.global.sessions) do
        if (id+maxlife) > t then
            sessions[id] = sess
        end
    end
    self.db.global.sessions = sessions -- Write the pruned sessions to the database.

    -- Make sure to show the minimap icon when the addon is enabled.
    if not self.db.profile.minimap.hide then
        self.icon:Show("Loot")
    else
        self.icon:Hide("Loot") -- Clean up just in case we have gotten ourselves into a dirty state
    end

    -- Register all events
    for _, event in ipairs(ADDON_EVENTS) do
        self:RegisterEvent(event)    
    end

    -- Register internal messagess
    for _, message in ipairs(ADDON_MESSAGES) do
        self:RegisterMessage(message)    
    end

    -- Request raid info to make sure we will know what instance we're in
    RequestRaidInfo()

    self:Debug("addon enabled")
end

function Addon:OnDisable()
    -- Hide the main addon window.
    if self.window ~= nil then
        AceGUI:Release(self.window)
    end

    -- Make sure to always hide the minimap icon when the addon is disabled.
    if self.icon ~= nil then
        self.icon:Hide("Loot")
    end

    -- Unregister all system events being listened to. 
    for _, event in ipairs(ADDON_EVENTS) do
        self:UnregisterEvent(event)    
    end

    -- Unregister all internal messages.
    for _, message in ipairs(ADDON_MESSAGES) do
        self:UnregisterMessage(message)    
    end

    self:Debug("addon disabled")
end

function Addon:Announce(message)
    ableToRaidWarn = IsInRaid() and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player"))
    ableToRaidChat = IsInRaid()
    ableToPartyChat = UnitInParty("player")

    if ableToRaidWarn then
        SendChatMessage(message, "RAID_WARNING", nil)
    elseif ableToRaidChat then
        SendChatMessage(message, "RAID", nil)
    elseif ableToPartyChat then
        SendChatMessage(message, "PARTY", nil)
    else
        print(message)
    end
end

function Addon:ZONE_CHANGED(event, ...)
    -- Request raid info as soon as we enter the intance to make sure we know where we are by the end of an encounter.
    RequestRaidInfo()
end

function Addon:RAID_INSTANCE_WELCOME(event, ...)
    -- Request raid info as soon as we enter the intance to make sure we know where we are by the end of an encounter.
    RequestRaidInfo()
end

function Addon:UPDATE_INSTANCE_INFO(event, ...)
    -- Check if the current zone is somewhere we should start loot sessions.
    local info = {GetInstanceInfo()}
    local itype = info[2]
    local difficultyID = info[3]
    local raid = itype == "raid"
    local party = itype == "party"

    self.is_in_party_or_raid = (raid or party)
    self.current_difficulty = Difficulty:LookupID(difficultyID)
    
    self:Debug("updating instance info")
end

function Addon:BOSS_KILL(event, encounterID, encounterName)
    self:Debug(string.format("defeated %s (%s)", encounterName, encounterID))
    local encounter = self.db.profile.encounters[encounterID]

    -- Only open the loot window if we're in a party or raid or if the encounter exists in the configuration.
    if self.is_in_party_or_raid and (encounter ~= nil) then
        if encounter[self.current_difficulty] then
            self:Debug("encounter configured to trigger loot sessions")
            self:SendMessage("ADDON_LOOT_UI_ACTION_WINDOW_OPEN")
        else
            self:Debug("encounter not configured to trigger loot sessions (ignoring)")
        end
    else
        self:Debug("criteria for opening loot window not met (ignoring)")
    end
end

function Addon:CHAT_MSG_SYSTEM(event, msg)
    local ok, roll = ChatMessages:ParseRoll(msg)
    if not ok then
        self:Debug("cannot parse roll for: %s", msg)
        return
    end
    local ok, player = Player:LookupByName(roll.name)
    if not ok then
        self:Debug("cannot get info for player from roll: %s", roll.name)
        return
    end
    self:SendMessage("ADDON_LOOT_PLAYER_ROLL", player, roll)
end

function Addon:CHAT_MSG_LOOT(event, msg, name)
    local ok, link = ChatMessages:ParseItemLink(msg)
    if not ok then
        self:Debug("could not parse link from loot drop: %s", msg)
        return
    end
    local ok, player = Player:LookupByName(name)
    if not ok then
        self:Debug("cannot get info for player: %s", name)
        return
    end
    self:SendMessage("ADDON_LOOT_PLAYER_ITEM_ACQUIRED", LootItem:new(player, link))
end

function Addon:CHAT_MSG_WHISPER(event, msg, name)
    local ok, link = ChatMessages:ParseItemLink(msg)
    if not ok then
        self:Debug("could not parse link from whisper: %s", msg)
        return
    end
    local ok, player = Player:LookupByName(name)
    if not ok then
        self:Debug("cannot get info for player: %s", name)
        return
    end
    self:SendMessage("ADDON_LOOT_PLAYER_ITEM_SHARED", LootItem:new(player, link))
end

-- Used to show the main frame of the addon window.
function Addon:ADDON_LOOT_UI_ACTION_WINDOW_OPEN(event)
    if self.window == nil then
        self:Debug("ui action to display main window")
        self.window = self:CreateLootWindow()
        self.window:Show()
        self:SendMessage("ADDON_LOOT_UI_WINDOW_OPEN", self.window)
        _G["AddonLootWindow"] = self.window.frame
        tinsert(UISpecialFrames, "AddonLootWindow")
    else
        self:Debug("ui action to display main window failed because the frame has not been constructed")
    end
end

function Addon:ADDON_LOOT_UI_ACTION_WINDOW_CLOSE(event)
    if self.window ~= nil then
        self:Debug("ui action to close main window")
        self.window:Hide()
    else
        self:Debug("ui action to close main window failed because the frame has not been constructed")
    end
end

function Addon:ADDON_LOOT_UI_ACTION_WINDOW_TOGGLE(event)
    if self.window == nil then
        self:SendMessage("ADDON_LOOT_UI_ACTION_WINDOW_OPEN")
    else
        self:SendMessage("ADDON_LOOT_UI_ACTION_WINDOW_CLOSE")
    end
end

function Addon:ADDON_LOOT_UI_ACTION_SHOW_OPTIONS(event)
    -- Needs to be called twice due to blizzard interface bug.
    -- TODO: find out a more elegant way to get around this.
    if self.optionsframe ~= nil then
        self:Debug("ui action to display options window")
        InterfaceOptionsFrame_OpenToCategory(self.optionsframe)
        InterfaceOptionsFrame_OpenToCategory(self.optionsframe)
    else
        self:Debug("ui action to display options window failed because the frame has not been constructed")
    end
end

-- Supposed to happen when an action is taken by the user to discard an item from the current list of shared items.
function Addon:ADDON_LOOT_UI_ACTION_DISCARD_ITEM(event, item)
    self:Debug("ui action to discard item %s (%d) from player %s ", item.link, item.id, item.player.fqname)
    for idx, itm in ipairs(self.items) do
        if itm.id == item.id then
            table.remove(self.items, idx)
            self:SendMessage("ADDON_LOOT_ITEM_DISCARDED", item)
            break
        end
    end
end

-- Happens when the primary loot window opens.
function Addon:ADDON_LOOT_UI_WINDOW_OPEN(event, window)
    self:Debug("window is opening")
    self.broker.icon = ADDON_BROKER_ICON_ACTIVE
end

-- Happens when the primary window for the loot addon is closed.
function Addon:ADDON_LOOT_UI_WINDOW_CLOSE(window)
    self:Debug("window is closing")
    if self.window ~= nil then
        AceGUI:Release(self.window)
    end
    self.window = nil
    self.broker.icon = ADDON_BROKER_ICON_INACTIVE
end

function Addon:ADDON_LOOT_PLAYER_ROLL(event, player, roll)
    if self.session == nil then
        self:Debug("player %s rolled %d min() max(): loot session not active", player.fqname, roll.val, roll.min, roll.max)
        return
    end
    if (player.fqname == self.session.item.player.fqname) and not self.db.profile.session.selfroll then
        self:Debug("player %s rolled %d min(%d) max(%d): rolling for your own item is not allowed", player.fqname, roll.val, roll.min, roll.max)
        return
    end
    local min, max = self.db.profile.session.minroll, self.db.profile.session.maxroll
    if roll.max ~= max and roll.min ~= min then
        self:Debug("player %s rolled %d min(%d) max(%d): roll does not match rules min(%d) max(%d)", player.fqname, roll.val, roll.min, roll.max, min, max)
        return
    end
    self:Debug("player %s rolled %d min(%d) max(%d)", player.fqname, roll.val, roll.min, roll.max)
    self.session:AddRoll(player, roll.val)
end

function Addon:ADDON_LOOT_PLAYER_ITEM_ACQUIRED(event, item)
    self:Debug("player %s acquired %s (%d)", item.player.fqname, item.link, item.id)
end

function Addon:ADDON_LOOT_PLAYER_ITEM_SHARED(event, item)
    self:Debug("player %s shared %s (%d)", item.player.fqname, item.link, item.id)
    table.insert(self.items, item)
end

function Addon:ADDON_LOOT_SESSION_BEGIN(event, session, players)
    self:Debug("session (%d) started (%d seconds) for %s from %s (%d)", session.id, session.duration, session.item.link, session.item.player.fqname, session.item.id)
    self:Debug("session whitelist: %s", dump(players))
    self:CreateSessionWindow(session)
    self:Announce( string.format("Roll for %s ending in %d seconds", session.item.link, session.duration) )
    if players ~= nil and table.getn(players) > 0 then
        local names = {}
        for _, player in ipairs(players) do
            table.insert(names, player.name)
        end
        self:Announce( string.format("Only %s are able to roll", table.concat(names, " & ")) )
    end
end

function Addon:ADDON_LOOT_SESSION_TICK(event, session)
    self:Debug("session (%d) ticked (%d/%d seconds) for %s from %s (%d)", session.id, session.tick, session.duration, session.item.link, session.item.player.fqname, session.item.id)
    local counter = session.duration - session.tick
    if (counter < 6 and counter > 0) or ((counter % 10) == 0) then
        self:Announce( string.format("%d seconds remain", counter) )
    end
end

function Addon:ADDON_LOOT_SESSION_ROLL(event, session, player, value)
    self:Debug("session (%d) for %s from %s (%d) received roll by %s (%d)", session.id, session.item.link, session.item.player.fqname, session.item.id, player.fqname, value)
end

function Addon:ADDON_LOOT_SESSION_END(event, session, winners)
    self.db.global.sessions[session.id] = session
    self:SendMessage("ADDON_LOOT_SESSION_END_ANNOUNCEMENT", session, winners)
end

function Addon:ADDON_LOOT_SESSION_END_ANNOUNCEMENT(event, session, winners)
    local n = table.getn(winners)
    local names = {}
    for _, winner in pairs(winners) do
        table.insert(names, winner.player.name)
    end

    local link = session.item.link
    local giver = session.item.player.name
    local receiver = table.concat(names, " & ")
    if (n < 1) or (giver == receiver) then
        self:Announce( string.format("%s keeps %s", giver, link) )
    elseif n == 1 then
        self:Announce( string.format("%s gives %s to %s", giver, link, receiver) )
    elseif n > 1 then
        self:Announce( string.format("There's a draw between %s", receiver) )
        self:Announce( string.format("%s hold on to %s while they reroll", giver, link) )
    end
end

function Addon:ADDON_LOOT_ITEM_DISCARDED(event, item)
    self:Debug("item %s from player %s discarded (%d)", item.link, item.player.fqname, item.id)
end

function Addon:ADDON_LOOT_ITEM_PROPOSED(event, item, players)
    self:Debug("item %s from player %s is being proposed to the group (%d)", item.link, item.player.fqname, item.id)
    if self.session then
        self:Debug("cannot start a new session while one is active")
        return
    end
    self.session = LootSession:new(item, self.db.profile.session.duration, players)
    self.session:OnRoll(function(session, player, value)
        self:SendMessage("ADDON_LOOT_SESSION_ROLL", session, player, value)
    end)   
    self.session:OnBegin(function(session, whitelist)
        self:SendMessage("ADDON_LOOT_SESSION_BEGIN", self.session, whitelist)
    end)
    self.session:OnEverySecond(function()
        self:SendMessage("ADDON_LOOT_SESSION_TICK", self.session)
    end)
    self.session:OnDone(function(session, winners)
        self:SendMessage("ADDON_LOOT_SESSION_END", session, winners)
        self.session = nil
    end)
    self.session:Begin()
end

function Addon:CreateItemGroup(item)
    local grp = AceGUI:Create("SimpleGroup")
    AceEvent:Embed(grp)

    grp:SetLayout("Flow")
    grp:SetFullWidth(true)

    grp:SetCallback("OnRelease", function(event)
        grp:UnregisterAllMessages()
    end)

    local tex = select(10, GetItemInfo(item.link))
    local ico = AceGUI:Create("Icon")
    ico:SetWidth(50)
    ico:SetImage(tex)
    ico:SetImageSize(30, 30)
    grp:AddChild(ico)

    ItemTooltip:Embed(ico.frame, item.link)

    local lbl = AceGUI:Create("Label")
    lbl:SetText(item.link)
    lbl:SetFontObject(GameFontHighlight)
    lbl:SetWidth(260)
    grp:AddChild(lbl)

    ItemTooltip:Embed(lbl.frame, item.link)

    local giver = item.player:NameWithClassColor()
    local lbl = AceGUI:Create("Label")
    lbl:SetText(giver)
    lbl:SetFontObject(GameFontHighlight)
    grp:AddChild(lbl)
    lbl:SetWidth(120)
    lbl:ClearAllPoints()
    lbl:SetPoint("TOPRIGHT", grp.frame, "TOPLEFT")

    grp:AddChild(self:CreateItemRollButton(item))
    grp:AddChild(self:CreateItemDiscardButton(item))

    grp:RegisterMessage("ADDON_LOOT_ITEM_DISCARDED", function(event, itm)
        if itm.id == item.id then
            grp:SendMessage("ADDON_LOOT_UI_ITEM_GROUP_RELEASED", grp)
        end
    end)
    
    return grp
end

function Addon:CreatePastLootSessionListGroup(id, session)
    local grp = AceGUI:Create("SimpleGroup")
    AceEvent:Embed(grp)

    grp:SetLayout("Flow")
    grp:SetFullWidth(true)

    grp:SetCallback("OnRelease", function(event)
        grp:UnregisterAllMessages()
    end)

    local item = session.item
    local tex = select(10, GetItemInfo(item.link))
    local ico = AceGUI:Create("Icon")
    ico:SetWidth(50)
    ico:SetImage(tex)
    ico:SetImageSize(30, 30)
    grp:AddChild(ico)

    ItemTooltip:Embed(ico.frame, item.link)

    local lbl = AceGUI:Create("Label")
    lbl:SetText(item.link)
    lbl:SetFontObject(GameFontHighlight)
    lbl:SetWidth(260)
    grp:AddChild(lbl)

    ItemTooltip:Embed(lbl.frame, item.link)

    local winners = session:GetWinners()
    local n = table.getn(winners)

    local selfroll = false
    local names = {}
    for _, winner in pairs(winners) do
        if winner.player.fqname == session.item.player.fqname then
            selfroll = true
            break
        end
        local name = winner.player:NameWithClassColor()
        table.insert(names, name)
    end
    local giver = session.item.player:NameWithClassColor()
    local receiver = table.concat(names, " & ")
    local lbl = AceGUI:Create("Label")
    if (n < 1) or (selfroll) then
        lbl:SetText(string.format("%s keeps item", giver))
    elseif n == 1 then
        lbl:SetText(string.format("%s gives item to %s", giver, receiver))
    elseif n > 1 then
        lbl:SetText(string.format("Draw between %s", receiver))
    end
    
    lbl:SetFontObject(GameFontHighlight)
    lbl.frame:SetScript('OnEnter', function()
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        local iter = function(a, b) return a > b end
        for _, result in Iterators:PairsByKeys(session:GetAllResults(), iter) do
            GameTooltip:AddLine( string.format("%d %s", result.value, result.player:NameWithClassColor()), 255, 255, 255, true)
        end
        GameTooltip:Show()
    end)
    lbl.frame:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    lbl:SetCallback("OnRelease", function(event)
        lbl.frame:SetScript('OnEnter', function() end)
        lbl.frame:SetScript('OnLeave', function() end)
    end)

    grp:AddChild(lbl)

    return grp
end

function Addon:CreateItemRollButton(item)
    local btn = AceGUI:Create("Button")
    AceEvent:Embed(btn)

    btn:SetText("Roll")
    btn:SetWidth(90)
    btn:SetDisabled(self.session ~= nil)

    btn:SetCallback("OnRelease", function(event)
        btn:UnregisterAllMessages()
    end)

    btn:SetCallback("OnClick", function(event)
        btn:SendMessage("ADDON_LOOT_ITEM_PROPOSED", item, nil)
        btn:SendMessage("ADDON_LOOT_UI_ACTION_DISCARD_ITEM", item)
    end)

    btn:RegisterMessage("ADDON_LOOT_SESSION_BEGIN", function(event, session, players)
        btn:SetDisabled(true)
    end)

    btn:RegisterMessage("ADDON_LOOT_SESSION_END", function(event, session, winners)
        btn:SetDisabled(false)
    end)

    return btn
end

function Addon:CreateItemDiscardButton(item)
    local btn = AceGUI:Create("Button")
    AceEvent:Embed(btn)

    btn:SetText("Discard")
    btn:SetWidth(90)

    btn:SetCallback("OnRelease", function(event)
        btn:UnregisterAllMessages()
    end)

    btn:SetCallback("OnClick", function(event)
        btn:SendMessage("ADDON_LOOT_UI_ACTION_DISCARD_ITEM", item)
    end)

    return btn
end

function Addon:CreateSessionHistoryScrollFrame()
    local scr = AceGUI:Create("ScrollFrame")
    AceEvent:Embed(scr)

    scr:SetLayout("List")

    for id, session in Iterators:PairsByKeys(self.db.global.sessions, function(a, b)
        return a > b
    end) do
        scr:AddChild(self:CreatePastLootSessionListGroup(id, LootSession:load(session)))
    end

    scr:SetCallback("OnRelease", function(event)
        scr:UnregisterAllMessages()
    end)

    return scr
end

function Addon:CreateItemScrollFrame()
    local widget = AceGUI:Create("ScrollFrame")
    AceEvent:Embed(widget)

    widget:SetLayout("List")
    widget:PauseLayout()

    local children = {}
    for _, item in pairs(self.items) do
        table.insert(children, self:CreateItemGroup(item))
    end
    widget:AddChildren(unpack(children))

    widget:ResumeLayout()
    widget:PerformLayout()

    widget:SetCallback("OnRelease", function(event)
        widget:UnregisterAllMessages()
    end)

    widget:RegisterMessage("ADDON_LOOT_PLAYER_ITEM_SHARED", function(event, item)
        widget:PauseLayout()
        widget:AddChild(self:CreateItemGroup(item))
        widget:ResumeLayout()
        widget:PerformLayout()
        widget:FixScroll()
    end)

    widget:RegisterMessage("ADDON_LOOT_UI_ITEM_GROUP_RELEASED", function(event, grp)
        local status = widget.status or widget.localstatus
        local cur = status.scrollvalue

        local children = {}
        for i, child in ipairs(widget.children) do
            if child == grp then
                AceGUI:Release(child)
            else
                table.insert(children, child)
            end
            widget.children[i] = nil
        end

        widget:AddChildren(unpack(children))
        widget:FixScroll()
    end)

    return widget
end

function Addon:CreateLootWindow()
    local w = AceGUI:Create("Window")
    w:SetTitle("Loot")
    w:SetStatusTable(self.db.profile.windows.main)
    w:EnableResize(false)
    w:SetLayout("Fill")
    w:SetHeight(500)

    w:SetCallback("OnClose", function(widget) self:SendMessage("ADDON_LOOT_UI_WINDOW_CLOSE", widget) end)

    local tab =  AceGUI:Create("TabGroup")
    tab:SetLayout("Fill")
    tab:SetTabs({
        {
            text = "Looted Items",
            value = "items"
        },
        {
            text = "Previous Rolls",
            value = "sessions"
        }
    })

    tab:SetCallback("OnGroupSelected", function(widget, event, group)
        widget:PauseLayout()
        widget:ReleaseChildren()

        if group == "items" then
            local itemstab = self:CreateItemScrollFrame()
            widget:AddChild(itemstab)
        elseif group == "sessions" then
            local sessionstab = self:CreateSessionHistoryScrollFrame()
            widget:AddChild(sessionstab)
        end

        widget:ResumeLayout()
        widget:PerformLayout()
    end)

    tab:SelectTab("items")
    
    w:AddChild(tab)
    
    return w
end

function Addon:CreateSessionRollGroup(player, value)
    local grp = AceGUI:Create("SimpleGroup")
    AceEvent:Embed(grp)
    
    grp:SetLayout("Flow")
    grp:SetFullWidth(true)

    local icon = AceGUI:Create("Icon")
    icon:SetImage(READY_CHECK_WAITING_TEXTURE)
    icon:SetImageSize(14, 14)
    icon:SetWidth(30)
    icon:SetHeight(24)
    icon.frame:SetScript('OnEnter', function() end)
    icon.frame:SetScript('OnLeave', function() end)
    grp:AddChild(icon)

    local lbl1 = AceGUI:Create("Label")
    lbl1:SetText(string.format("%s", value))
    lbl1:SetFontObject(GameFontNormal)
    lbl1:SetWidth(32)
    lbl1:SetJustifyH("MIDDLE")
    lbl1.frame:SetScript('OnEnter', function() end)
    lbl1.frame:SetScript('OnLeave', function() end)
    grp:AddChild(lbl1)

    local r, g, b, hex = GetClassColor(player.class)
    local lbl2 = AceGUI:Create("Label")
    lbl2:SetText(player.name)
    lbl2:SetColor(r, g, b)
    lbl2:SetFontObject(GameFontNormal)
    lbl2:SetWidth(160)
    lbl2.frame:SetScript('OnEnter', function() end)
    lbl2.frame:SetScript('OnLeave', function() end)
    grp:AddChild(lbl2)

    grp:RegisterMessage("ADDON_LOOT_SESSION_END", function(event, session, winners)
        local found = false
        for _, winner in pairs(winners) do
            if winner.player.fqname == player.fqname then
                found = true
                break
            end
        end
        if found then
            icon:SetImage(READY_CHECK_READY_TEXTURE)
        else
            icon:SetImage(READY_CHECK_NOT_READY_TEXTURE)
        end
    end)

    grp:SetCallback("OnRelease", function(event)
        grp:UnregisterAllMessages()
    end)

    return grp
end

function Addon:CreateSessionStatusButton(session)
    local btn = AceGUI:Create("Button")
    AceEvent:Embed(btn)

    btn:SetText(string.format("%s sec", session.duration))
    btn:SetWidth(120)
    btn:SetDisabled(true)

    btn:SetCallback("OnRelease", function(event)
        btn:UnregisterAllMessages()
    end)

    btn:SetCallback("OnClick", function(event) end)

    btn:RegisterMessage("ADDON_LOOT_SESSION_TICK", function(event, sess)
        if session.id == sess.id then
            local second = sess.duration - sess.tick
            btn:SetText(string.format("%s sec", second))
        end
    end)
    
    btn:RegisterMessage("ADDON_LOOT_SESSION_END", function(event, sess, winners)
        if session.id == sess.id then
            -- When there are no winners
            if table.getn(winners) < 1 then
                btn:SetText("Reroll")
                btn:SetDisabled(false)
                btn:SetCallback("OnClick", function(event)
                    btn:SendMessage("ADDON_LOOT_ITEM_PROPOSED", sess.item, nil)
                end)
            end

            -- When there's a clear winner
            if table.getn(winners) == 1 then
                btn:SetText("Announce")
                btn:SetDisabled(false)
                btn:SetCallback("OnClick", function(event)
                    btn:SendMessage("ADDON_LOOT_SESSION_END_ANNOUNCEMENT", sess, winners)
                end)
            end

            -- When there's a draw
            if table.getn(winners) > 1 then
                btn:SetText("Reroll")
                btn:SetDisabled(false)
                btn:SetCallback("OnClick", function(event)
                    local players = {}
                    for _, winner in ipairs(winners) do
                        table.insert(players, winner.player)
                    end
                    btn:SendMessage("ADDON_LOOT_ITEM_PROPOSED", sess.item, players)
                end)
            end
        end
    end)

    return btn
end

function Addon:CreateSessionWindow(session)
    if self.sessionwindow then
        self.sessionwindow:Release()
    end

    local w = AceGUI:Create("Window")
    AceEvent:Embed(w)

    local item = session.item
    local info = {GetItemInfo(item.link)}

    w:SetTitle(info[1]) -- item name
    w:SetStatusTable(self.db.profile.windows.session)
    w:EnableResize(false)
    w:SetLayout("Fill")
    w:SetWidth(440)
    w:SetHeight(500)

    local scr = AceGUI:Create("ScrollFrame")
    scr:SetFullWidth(true)
    scr:SetLayout("List")
    w:AddChild(scr)

    local grp = AceGUI:Create("SimpleGroup")
    grp:SetLayout("Flow")
    grp:SetFullWidth(true)
    scr:AddChild(grp)

    local ico = AceGUI:Create("Icon")
    ico:SetWidth(50)
    ico:SetHeight(50)
    ico:SetImage(info[10]) -- item icon texture
    ico:SetImageSize(30, 30)
    ItemTooltip:Embed(ico.frame, item.link)
    grp:AddChild(ico)

    local lbl = AceGUI:Create("Label")
    lbl:SetText(item.link)
    lbl:SetFontObject(GameFontHighlight)
    lbl:SetWidth(220)
    ItemTooltip:Embed(lbl.frame, item.link)
    grp:AddChild(lbl)

    grp:AddChild(self:CreateSessionStatusButton(session))

    w:SetCallback("OnRelease", function(event)
        w:UnregisterAllMessages()
    end)

    w:RegisterMessage("ADDON_LOOT_SESSION_ROLL", function(event, sess, player, value)
        if session.id == sess.id then
            scr:AddChild(self:CreateSessionRollGroup(player, value))
        end
    end)

    w:Show()
    self.sessionwindow = w
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- Generate test items to be used during addon testing based on what's in the player's backpack.
function GenerateTestItems()
    local items = {}
    local player = Player:GetCurrent()
    local i1 = 0
    for i = 4, 0, -1 do
        for i2 = GetContainerNumSlots(i), 0, -1 do
            local link = select(7, GetContainerItemInfo(i,i2))
            if link and (i1 < 100) then
                local item = LootItem:new(player, link)
                table.insert(items, item)
                i1 = i1+1
            end
        end
    end
    return items
end