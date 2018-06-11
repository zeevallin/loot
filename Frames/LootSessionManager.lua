function BuildLootSessionManagerFrame()
    local frame = CreateFrame("Frame", "LOOT_SESSION_MANAGER_FRAME", UIParent)
    frame.lootSessions = {}

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

    function frame:ArchiveSession()
        if self.lootSession then
            self.lootSession.Frame:StopSession()
            self.lootSessions[#self.lootSessions+1] = self.lootSession
            self.lootSession = nil
        end
    end

    function frame:NewSession()
        self.lootSession = {
            Frame = BuildLootSessionFrame(self)
        }
        self.lootSession.Frame:StartSession()
    end

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetFrameStrata("BACKGROUND")

    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetColorTexture(0, 0, 0, 0.5)
    frame.texture = tex
    
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Loot distribution")

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 16, -32)
    title:SetText("Request whispers from other raid members.")

    local btnWidth = 100
    local btn = frame.BuildButton(frame, "LOOT_MANAGER_START_SESSION_BUTTON")
    btn:SetText("Start session")
    btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(16 + btnWidth + 5), -16)
    btn:SetWidth(btnWidth)
    btn:SetHeight(30)

    btn:SetScript("OnClick", function()
        frame:ArchiveSession()
        frame:NewSession()
    end)

    frame.startButton = btn

    local btn = frame.BuildButton(frame, "LOOT_MANAGER_SKIP_BUTTON")
    btn:SetText("Skip")
    btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -16)
    btn:SetWidth(btnWidth)
    btn:SetHeight(30)

    btn:SetScript("OnClick", function()
        frame:ArchiveSession()
        frame:Hide()
    end)

    frame.skipButton = btn

    frame:SetWidth(512)
    frame:SetHeight(30 + (2 * 16))
    frame:SetPoint("CENTER", 0, 0)
    frame:Hide()

    frame:SetScript("OnEvent", function(self, event, msg, ...)
        self[event](self, msg, ...)
    end)

    return frame
end
