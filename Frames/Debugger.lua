function BuildDebuggerFrame(opts)

    local options = opts or {
        Debug = true,
        OnStartLootSession = function()end,
    }

    local frame = CreateFrame("Frame", "LOOT_DEBUGGER_FRAME", UIParent)
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

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetFrameStrata("BACKGROUND")
    frame:SetWidth(256)
    frame:SetHeight(128)

    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetColorTexture(0, 0, 0, 0.5)
    frame.texture = tex
    
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Loot Debugger")

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 16, -32)
    title:SetText("Tools to help with the loot debugging.")

    local btn = frame.BuildButton(frame, "LOOT_DEBUGGER_START_LOOT_SESSION_BUTTON")
    btn:SetText("Start test session")
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -50)
    btn:SetWidth(224)
    btn:SetHeight(30)

    btn:SetScript("OnClick", function()
        options.OnStartLootSession(self)
    end)

    local btn = frame.BuildButton(frame, "LOOT_DEBUGGER_WHISPER_RANDOM_ITEM_BUTTON")
    btn:SetText("Whisper random item from bags")
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -85)
    btn:SetWidth(224)
    btn:SetHeight(30)

    btn:SetScript("OnClick", function()
        local itemLink
        repeat
            itemLink = GetContainerItemLink(random(0,4), random(0,30))
        until(itemLink)
        SendChatMessage(itemLink, "WHISPER", nil, GetUnitName("PLAYER"))
    end)

    frame:SetPoint("TOPLEFT", 100, -100)
    frame:Hide()

    frame:SetScript("OnEvent", function(self, event, msg, ...)
        self[event](self, msg, ...)
    end)

    if options.Debug then
        frame:Show()
    end

    return frame

end