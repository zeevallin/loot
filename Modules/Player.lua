Player = {}
Player.__index = Player

function Player:new(fqname, name, class)
    local self = {}
    setmetatable(self, Player)
    self.fqname = fqname or "N/A"
    self.name = name or "N/A"
    self.class = class or "UNKNOWN"
    return self
end

-- Load the prototype for a loot item table.
function Player:load(player)
    local self = {}
    setmetatable(self, Player)
    for k, v in pairs(player) do
        self[k] = v
    end
    self.fqname = self.fqname or "N/A"
    self.name = self.name or "N/A"
    self.class = self.class or "UNKNOWN"
    return self
end

function Player:ClassColor()
    local color = RAID_CLASS_COLORS[self.class] or {}
    return color.colorStr or "FFFFFFFF"
end

function Player:NameWithClassColor(base)
    if base == nil then
        base = "FFFFFFFF"
    end
    return string.format("|c%s%s|c%s", self:ClassColor(), self.name, base)
end

function Player:FullNameWithClassColor(base)
    if base == nil then
        base = "FFFFFFFF"
    end
    return string.format("|c%s%s|c%s", self:ClassColor(), self.fqname, base)
end

-- To make sure there's consistancy in display and matching between players we strip the server name.
-- The caveat is that two players with the same name will be treated as the same player.
function Player:ParseName(name)
    if not name then
        return false
    end
    local pname = string.match(name, "(.*)%-.*")
    if not pname then
        return true, name
    end
    return true, pname
end

-- Get information for a player from the raid group or party.
function Player:LookupByName(name)
    local ok, pname = Player:ParseName(name) -- excludes the server name
    if not ok then
        return false
    end

    -- If the player is alone, we will not be able to run GetRaidRosterInfo()
    -- We get around this by bailing before we get to that point.
    local n = GetNumGroupMembers()
    if n < 2 then
        return true, Player:GetCurrent()
    end

    -- loop through the raind memebers to get information on a player by their name
    local found, player = false, Player:load({})
    for i = 1, MAX_RAID_MEMBERS do
        local info = {GetRaidRosterInfo(i)}
        local fqname = info[1] -- includes the server name
        if fqname then
            local ok, name = parseName(fqname) -- excludes the server name
            if ok and (name == pname) then
                found = true
                player = Player:new(
                    fqname, -- fully qualified name with server name
                    name, -- short name for pleasurable viewing
                    info[6] -- upper case version of the name
                )
                break
            end
        end
    end
    return found, player
end

-- Get the information for the current player in a format that works just as it would in a raid group.
function Player:GetCurrent()
    local name, realm = UnitFullName("player")
    local _, class, _ = UnitClass("player")
    local fqname = string.format("%s-%s", name, realm)
    return Player:new(
        fqname, -- fully qualified name with server name
        name, -- short name for pleasurable viewing
        class -- upper case version of the name
    )
end