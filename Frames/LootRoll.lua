function BuildLootRollFrame(parentFrame, itemLink, playerName, opts)
    local options = opts or {
        DurationInSeconds = 15,
        OnNoWinners = function()end,
        OnOneWinner = function()end,
        OnMultipleWinners = function()end,
        OnComplete = function()end,
        AllowedRollers = {},
        AllowedRollersN = 0,
    }

    local t = GetTime()
    local frameID = format("LOOT_ROLL_%d", t)
    local frame = CreateFrame("Frame", frameID, parentFrame)

    frame.options = options
    frame.rolls = {}
    frame.counter = nil

    frame:SetScript("OnEvent", function(self, event, msg, ...) self[event](self, msg, ...) end)

    function frame:CHAT_MSG_SYSTEM(msg, ...)
        if msg then
            local name, value, minRoll, maxRoll = msg:match("^(.+) rolls (%d+) %((%d+)%-(%d+)%)$")

            -- Do not allow rolls if there are a whitelist of rollers
            if self.options.AllowedRollersN > 0 and not self.options.AllowedRollers[name] then
                return
            end

            if name and not self.rolls[name] then
                if minRoll == "1" and maxRoll == "100" then
                    self.rolls[name] = tonumber(value)
                end
            end
        end
    end

    function frame:RegisterEvents()
        self:RegisterEvent("CHAT_MSG_SYSTEM")
    end

    function frame:UnregisterEvents()
        self:UnregisterEvent("CHAT_MSG_SYSTEM")
    end

    function frame:Start()
        self:Show()
        self:StartCountdown()
    end

    function frame:Stop()
        self:Hide()
    end

    function frame:StartCountdown()
        self:RegisterEvents()
        self.counter = options.DurationInSeconds

        local ticker = C_Timer.NewTicker(1, function()
            if self.counter then
                self.counter = self.counter - 1
                if self.counter < 6 and self.counter > 0 then
                    local msg = format("%d",self.counter)
                    SendChatMessage(msg, "RAID_WARNING", nil)
                end
            end
            self:UpdateFrame()
        end, options.DurationInSeconds)

        C_Timer.After(options.DurationInSeconds, function()
            self:CountDownFinished()
        end)
    end

    function frame:CountDownFinished()
        self.counter = nil

        self:UnregisterEvents()

        local rolls = {}
        for k, v in pairs(self.rolls) do
            rolls[#rolls+1] = {k,v}
        end

        table.sort(rolls, function(a, b)
            return a[2] > b[2]
        end)

        local winners = {}
        local highestRoll = 0
        
        for k, v in pairs(rolls) do
            local playerName = v[1]
            local roll = v[2]
            if roll >= highestRoll then
                winners[#winners+1] = playerName
                highestRoll = roll
            end
        end
        
        local nWinners = table.getn(winners)
        if nWinners == 0 then
            self.options.OnNoWinners()
        elseif nWinners == 1 then
            self.options.OnOneWinner(winners[1], highestRoll)
        else
            self.options.OnMultipleWinners(winners, highestRoll)
        end

        self.options.OnComplete()

    end

    function frame:UpdateFrame()
        if self.counter then
            frame.countdownTxt:SetText(format("%d", self.counter))
            frame.countdownTxt:Show()
        else
            frame.countdownTxt:Hide()
        end
    end

    local itemName, _, _, _, _, _, _, _, _, iconTexture, _, _, _ = GetItemInfo(itemLink)

    frame:SetFrameStrata("BACKGROUND")

    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetColorTexture(0, 0, 0, 0.5)
    frame.texture = tex

    frame:SetWidth(parentFrame:GetWidth())
    frame:SetHeight(30 + (2 * 16))
    frame:SetPoint("TOP", parentFrame, "BOTTOM", 0, -2)

    local iconFrame = CreateFrame("Frame", nil, frame)
    iconFrame:SetWidth(40)
    iconFrame:SetHeight(40)

    local tex = iconFrame:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(iconFrame)
    tex:SetTexture(iconTexture)
    iconFrame.texture = tex

    iconFrame:SetPoint("LEFT", 16, 0)
    iconFrame:Show()

    iconFrame:SetScript('OnEnter', function()
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Show()
    end)

    iconFrame:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)

    frame.icon = iconFrame

    local txt = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    txt:SetPoint("LEFT", 70, 0)
    txt:SetText(itemLink)
    frame.itemName = txt

    local txt = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    txt:SetPoint("RIGHT", -16, 0)
    txt:SetText("")
    txt:Hide()
    frame.countdownTxt = txt

    frame:UpdateFrame()

    return frame
end