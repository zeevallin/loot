function BuildStartupDialogueFrame(opts)

    local options = opts or {
        Debug = false,
        OnStart = function()end,
        OnCancel = function()end,
    }

    local frame = CreateFrame("Frame", "LOOT_STARTUP_DIALOGUE_FRAME", UIParent)

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
    title:SetText("Loot")

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 16, -32)
    title:SetText("Do you want to distribute loot drops in this raid?")

    local btn = frame.BuildButton(frame, "LOOT_STARTUP_DIALOGUE_START_BUTTON")
    btn:SetText("Ask me when a boss dies")
    btn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 16)
    btn:SetWidth(150)
    btn:SetHeight(30)

    btn:SetScript("OnClick", function()
        options.OnStart(self)
        frame:Hide()
    end)

    local btn = frame.BuildButton(frame, "LOOT_STARTUP_DIALOGUE_CANCEL_BUTTON")
    btn:SetText("Not today")
    btn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 16)
    btn:SetWidth(80)
    btn:SetHeight(30)

    btn:SetScript("OnClick", function()
        options.OnCancel(self)
        frame:Hide()
    end)

    frame:SetPoint("CENTER", 0, 0)
    frame:Hide()

    return frame
end
