local LootAddOn_Version = "0.0.1"

LootAddOn = {}
LootAddOn.__index = LootAddOn
function LootAddOn:new(opts)
    opts = opts or {}
    addon = {}
    setmetatable(addon, self)
    addon.debug = opts["debug"] or false
    addon.version = opts["version"] or "0.0.0"
    frame = CreateFrame("Frame", "LOOT_ADDON_FRAME", UIParent)
    frame:SetScript("OnEvent", function(self, event, msg, ...) self[event](self, msg, ...) end)

    local this = self

    function frame:PLAYER_LOGIN()
        addon:Start()
    end

    function frame:RAID_INSTANCE_WELCOME()
        if IsInRaid() then
            addon.startupDialogueFrame:Show()
        end
    end

    function frame:PLAYER_ENTERING_WORLD()
        addon.startupDialogueFrame:Show()
    end

    function frame:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
        addon.state["is_in_raid_combat"] = true
    end

    function frame:PLAYER_REGEN_ENABLED()
        if addon.state["is_in_raid_combat"] and addon.state["has_enabled_addon_for_session"] then
            addon:OpenLootSessionManager()
        end
        addon.state["is_in_raid_combat"] = false
    end

    addon.frame = frame
    addon.state = {
        ["is_in_raid_combat"] = false,
        ["has_chosen_to_enable_or_disable"] = false,
        ["has_enabled_addon_for_session"] = false,
    }

    return addon
end

function LootAddOn:Load()
    self.frame:RegisterEvent("PLAYER_LOGIN")
    self.frame:RegisterEvent("RAID_INSTANCE_WELCOME")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function LootAddOn:Unload()
    self.frame:UnregisterEvent("PLAYER_LOGIN")
    self.frame:UnregisterEvent("RAID_INSTANCE_WELCOME")
    self.frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

function LootAddOn:Start()
    print(format("|cFFFF0000Loaded Loot (|cFFFFFFFF%s|cFFFF0000)", self.version))

    self.startupDialogueFrame = BuildStartupDialogueFrame({
        Debug = self.debug,
        OnCancel = function()
            self:DisableForSession()
        end,
        OnStart = function()
            self:EnableForSession()
        end,
    })

    self.lootSessionManagerFrame = BuildLootSessionManagerFrame({
        Debug = self.debug,
        State = self.state,
    })

    self.debuggerFrame = BuildDebuggerFrame({
        Debug = self.debug,
        OnStartLootSession = function()
            self:OpenLootSessionManager()
        end,
    })

end

function LootAddOn:EnableForSession()
    self.state["has_chosen_to_enable_or_disable"] = true
    self.state["has_enabled_addon_for_session"] = true
end

function LootAddOn:DisableForSession()
    self.state["has_chosen_to_enable_or_disable"] = true
    self.state["has_enabled_addon_for_session"] = false
end

function LootAddOn:OpenLootSessionManager()
    print("opening manager")
    self.lootSessionManagerFrame:Show()
end

function LootAddOn:CloseLootSessionManager()
    self.lootSessionManagerFrame:Hide()
end

local addon = LootAddOn:new({
    version = LootAddOn_Version,
    debug = false
})

addon:Load()