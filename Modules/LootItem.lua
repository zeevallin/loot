LootItem = {}
LootItem.__index = LootItem

-- Construct the table type for loot item based on a player and item link.
function LootItem:new(player, link)
    local self = {}
    setmetatable(self, LootItem)
    self.id = generateItemID(player.fqname, link)
    self.player = Player:load(player)
    self.link = link
    return self
end

-- Load the prototype for a loot item table.
function LootItem:load(item)
    local self = {}
    setmetatable(self, LootItem)
    for k, v in pairs(item) do
        self[k] = v
    end
    self.player = Player:load(self.player or {})
    return self
end

-- Hashing function used to turn a player name and an item link into an integer id.
-- This is useful for determining if an item is the same as one emitted from another event.
function generateItemID(player, link)
    return hashStringToInt(string.format("%s|%s", player, link))
end

-- Deterministically hashes a string into an integer.
function hashStringToInt(text)
    local counter = 1
    local len = string.len(text)
    for i = 1, len, 3 do 
        counter = math.fmod(counter*8161, 4294967279) +  -- 2^32 - 17: Prime!
            (string.byte(text,i)*16776193) +
            ((string.byte(text,i+1) or (len-i+256))*8372226) +
            ((string.byte(text,i+2) or (len-i+256))*3932164)
    end
    return math.fmod(counter, 4294967291)/10 -- 2^32 - 5: Prime (and different from the prime in the loop)
end
