LootSession = {}
LootSession.__index = LootSession

function LootSession:new(item, duration)
    local self = {}
    setmetatable(self, LootSession)
    self.id = time()
    self.item = item
    self.rolls = {}
    self.players = {}
    self.duration = duration
    self.counter = duration
    self.tick = 0
    return self
end

function LootSession:load(session)
    local self = {}
    setmetatable(self, LootSession)
    for k, v in pairs(session) do
        self[k] = v
    end
    self.item = LootItem:load(self.item or {})
    return self
end

function LootSession:OnBegin(func)
    self.onBegin = func
end

function LootSession:OnEverySecond(func)
    self.onEverySecond = func
end

function LootSession:OnDone(func)
    self.onDone = func
end

function LootSession:OnRoll(func)
    self.onRoll = func
end

function LootSession:Begin()
    -- Make sure we escape this function if we've already got a ticker running.
    -- Otherwise we would be creating a race condition.
    if self.ticker then
        return
    end

    self.counter = self.duration

    if self.onBegin then
        self:onBegin()
    end

    self.ticker = C_Timer.NewTicker(1, function()
        self.counter = self.counter - 1
        self.tick = self.duration - self.counter
        if self.onEverySecond then
            self:onEverySecond()
        end
    end, self.duration)

    C_Timer.After(self.duration + 1, function()
        if self.onDone then
            self:onDone(self:GetWinners())
        end
    end)
end

function LootSession:GetWinners()
    local rolls = {}
    -- Turn the name to roll value map into a list
    for k, v in pairs(self.rolls) do
        rolls[#rolls+1] = {k,v}
    end
    -- Sort the list based on the roll value
    table.sort(rolls, function(a, b)
        return a[2] > b[2]
    end)
    -- Determine the highest rollers
    local winners = {}
    local max = 0
    for k, v in pairs(rolls) do
        local fqname = v[1]
        local roll = v[2]
        if roll >= max then
            winners[#winners+1] = {
                ["player"] = Player:load(self.players[fqname] or {}),
                ["value"] = roll,
            }
            max = roll
        end
    end
    return winners
end

function LootSession:AddRoll(player, value)
    if self.rolls[player.fqname] then
        return
    end
    self.players[player.fqname] = player
    self.rolls[player.fqname] = value
    if self.onRoll then
        self:onRoll(player, value)
    end
end
