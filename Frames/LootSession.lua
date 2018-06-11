function BuildLootSessionFrame(parentFrame)
    local t = GetTime()
    local frameID = format("LOOT_SESSION_%d", t)
    local frame = CreateFrame("Frame", frameID, parentFrame)
    frame.items = {}
    frame.itemFrames = {}
    frame.itemHeight = 48

    function frame:RenderItem(itemLink, playerName, time)
        local name, _, _, _, _, _, _, _, _, iconTexture, _, _, _ = GetItemInfo(itemLink)

        local frame = CreateFrame("Frame", nil, self)
        frame.allowedRollers = {}
        frame.allowedRollersN = 0
        frame.winningRoll = 0
        frame.disabled = false
        frame.rolling = false
        frame.itemLink = itemLink
        frame.playerName = playerName

        function frame:BuildButton(name)
            local button = CreateFrame("Button", name, self)
            
            button:SetDisabledFontObject(GameFontDisable)
            button:SetHighlightFontObject(GameFontHighlight)
            button:SetNormalFontObject(GameFontNormal)
        
            local ntex = button:CreateTexture()
            ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
            ntex:SetTexCoord(0, 0.625, 0, 0.6875)
            ntex:SetAllPoints()	
            button:SetNormalTexture(ntex)
            
            local htex = button:CreateTexture()
            htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
            htex:SetTexCoord(0, 0.625, 0, 0.6875)
            htex:SetAllPoints()
            button:SetHighlightTexture(htex)
            
            local ptex = button:CreateTexture()
            ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
            ptex:SetTexCoord(0, 0.625, 0, 0.6875)
            ptex:SetAllPoints()
            button:SetPushedTexture(ptex)
            
            return button
        end

        function frame:WaitForRoll()
            self.rolling = true
            self:UpdateFrame()
        end

        function frame:ReadyForRoll()
            self.rolling = false
            self:UpdateFrame()
        end

        function frame:Disable()
            self.disabled = true
            self:UpdateFrame()
        end

        function frame:Enable()
            self.disabled = false
            self:UpdateFrame()
        end

        function frame:OnNoWinners()
            self.complete = true

            local msg = format("Nobody rolled for %s, %s keeps it", self.itemLink, self.playerName)
            SendChatMessage(msg, "RAID_WARNING", nil)

            self:UpdateFrame()
        end

        function frame:OnOneWinner(winner, roll)
            self.complete = true
            self.winner = winner
            self.winningRoll = roll

            local msg = format("%s wins the roll with %d for %s, please trade %s", self.winner, self.winningRoll, self.itemLink, self.playerName)
            SendChatMessage(msg, "RAID_WARNING", nil)

            self:UpdateFrame()
        end

        function frame:OnMultipleWinners(winners, roll)
            self.complete = true
            self.winningRoll = roll

            self.allowedRollersN = 0
            self.allowedRollers = {}
            for k, name in pairs(winners) do
                self.allowedRollers[name] = true
            end
            self.allowedRollersN = table.getn(winners)

            winnersList = table.concat(winners, ", ")

            local msg = format("Roll tied with %d for %s, can %s roll again please", self.winningRoll, self.itemLink, winnersList)
            SendChatMessage(msg, "RAID_WARNING", nil)

            self:UpdateFrame()
        end

        function frame:UpdateFrame()
            if self.disabled then
                self.rollBtn:Disable()
            else
                self.rollBtn:Enable()
            end

            if self.rolling then
                self.rollStatusTxt:SetText("Rolling...")
                self.rollStatusTxt:Show()
                self.rollBtn:Hide()
            elseif self.winner and self.complete then
                self.rollStatusTxt:SetText(format("%s wins (%d)", self.winner, self.winningRoll))
                self.rollStatusTxt:Show()
                self.rollBtn:Hide()
            elseif self.allowedRollersN > 0 and self.complete then
                self.rollStatusTxt:Hide()
                self.rollBtn:SetText("Start reroll")
                self.rollBtn:Show()
            elseif not self.winner and self.complete then
                self.rollStatusTxt:SetText("Nobody wins")
                self.rollStatusTxt:Show()
                self.rollBtn:Hide()
            else 
                self.rollBtn:SetText("Start roll")
            end
        end

        frame:SetWidth(480)
        frame:SetHeight(self.itemHeight)

        local tex = frame:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints(frame)
        tex:SetColorTexture(1, 1, 1, 0.1)
        frame.texture = tex

        local iconFrame = CreateFrame("Frame", nil, frame)
        iconFrame:SetWidth(40)
        iconFrame:SetHeight(40)

        local tex = iconFrame:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(iconFrame)
        tex:SetTexture(iconTexture)
        iconFrame.texture = tex

        iconFrame:SetPoint("TOPLEFT", 4, -4)
        iconFrame:Show()

        iconFrame:SetScript('OnEnter', function()
            GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()
        end)

        iconFrame:SetScript('OnLeave', function()
            GameTooltip:Hide()
        end)

        local txt = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        txt:SetPoint("TOPLEFT", 48, -4)
        txt:SetText(itemLink)
        frame.itemName = txt

        local txt = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        txt:SetPoint("TOPLEFT", 48, -22)
        txt:SetText(playerName)
        frame.ownerName = txt

        local btnWidth = 100
        local btn = frame.BuildButton(frame, nil)
        btn:SetText("Start roll")
        btn:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
        btn:SetWidth(btnWidth)
        btn:SetHeight(30)
    
        btn:SetScript("OnClick", function()
            self:StartRoll(frame, itemLink, playerName, frame.allowedRollers, frame.allowedRollersN)
        end)

        frame.rollBtn = btn

        local txt = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
        txt:SetText("")
        txt:Hide()
        frame.rollStatusTxt = txt

        frame:UpdateFrame()

        return frame
    end

    function frame:EnableAll()
        for k, f in pairs(frame.itemFrames) do
            f:Enable()
        end
    end

    function frame:DisableAll()
        for k, f in pairs(frame.itemFrames) do
            f:Disable()
        end
    end

    function frame:StartRoll(originFrame, itemLink, playerName, allowedRollers, allowedRollersN)

        local msg = format("Rolling for %s", itemLink)
        SendChatMessage(msg, "RAID_WARNING", nil)

        self:DisableAll()
        originFrame:WaitForRoll()

        if self.lootRoll then
            self.lootRoll:Stop()
            self.lootRoll = nil
        end

        self.lootRoll = BuildLootRollFrame(self, itemLink, playerName, {
            DurationInSeconds = 15,
            OnNoWinners = function()
                originFrame:OnNoWinners()
            end,
            OnOneWinner = function(winner, roll)
                originFrame:OnOneWinner(winner, roll)
            end,
            OnMultipleWinners = function(winners, roll)
                originFrame:OnMultipleWinners(winners, roll)
            end,
            OnComplete = function()
                self:EnableAll()
                originFrame:ReadyForRoll()
                self.lootRoll:Stop()
                self.lootRoll = nil
            end,
            AllowedRollers = allowedRollers,
            AllowedRollersN = allowedRollersN,
        })

        self.lootRoll:Start()
    end

    function frame:StartSession()

        local msg = format("Loot session has started, whisper %s items you don't need", GetUnitName("player", false))
        SendChatMessage(msg, "RAID_WARNING", nil)

        self:RegisterEvent("CHAT_MSG_WHISPER")
        self:Show()
    end

    function frame:StopSession()

        local msg = format("No more loot, session has ended!")
        SendChatMessage(msg, "RAID_WARNING", nil)

        self:UnregisterEvent("CHAT_MSG_WHISPER")
        self:Hide()
    end

    function frame:UpdateFrame()
        local count = table.getn(self.itemFrames)
        if count <= 0 then
            self.waitingText:Show()
            self:SetHeight(16 * 2 + (self.waitingText:GetHeight()))
        end

        if count > 0 then
            self.waitingText:Hide()
            self:SetHeight(16 * 2 + ((self.itemHeight + 2) * count))
        end

        for key, itemFrame in pairs(self.itemFrames) do
            local topOffset = -(16 + ((key - 1) * (48 + 2)))
            itemFrame:SetPoint("TOPLEFT", 16, topOffset)
            itemFrame:Show()
        end
    end

    function frame:AddItem(itemLink, playerName, time)
        local item = {itemLink, playerName, time}
        self.items[#frame.items+1] = item
        local idx = table.getn(self.items)
        local itemFrame = self:RenderItem(itemLink, playerName, time)
        self.itemFrames[#self.itemFrames+1] = itemFrame
        self:UpdateFrame()
    end

    function frame:CHAT_MSG_WHISPER(msg, ...)
        local t = format("%d", GetTime())
        local itemLink = msg:match("|%x+|Hitem:.-|h.-|h|r")

        local playerName = string.match(select(1, ...), "(.*)%-.*")

        if itemLink then
            self:AddItem(itemLink, playerName, time)
        end
    end

    frame:SetScript("OnEvent", function(self, event, msg, ...)
        self[event](self, msg, ...)
    end)

    frame:SetFrameStrata("BACKGROUND")

    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetColorTexture(0, 0, 0, 0.5)
    frame.texture = tex

    local txt = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    txt:SetPoint("TOPLEFT", 16, -16)
    txt:SetText("Waiting for whispers...")
    frame.waitingText = txt

    frame:SetWidth(parentFrame:GetWidth())
    frame:SetPoint("TOP", parentFrame, "BOTTOM", 0, -2)

    frame:UpdateFrame()

    return frame
end
