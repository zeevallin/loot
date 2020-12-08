ItemTooltip = {}

function ItemTooltip:Embed(frame, link)
    frame:SetScript('OnEnter', ItemTooltip:OnEnterFunc(link))
    frame:SetScript('OnLeave', ItemTooltip:OnLeaveFunc())
end

function ItemTooltip:Unembed(frame)
    frame:SetScript('OnEnter', function() end)
    frame:SetScript('OnLeave', function() end)
end

-- Used to show and attach an item tooltip to the player's cursor.
function ItemTooltip:OnEnterFunc(link)
    return function()
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end
end

-- Used to hide the game tooltip from view.
function ItemTooltip:OnLeaveFunc()
    return function()
        GameTooltip:Hide()
    end
end
