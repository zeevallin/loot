Difficulty = {
    [1] = "NORMAL", -- Normal party
    [2] = "HEROIC", -- Heroic party"
    [3] = "NORMAL", -- 10 Player raid
    [4] = "NORMAL", -- 25 Player raid
    [5] = "HEROIC", -- 10 Player (Heroic) raid
    [6] = "HEROIC", -- 25 Player (Heroic) raid
    [7] = "RAIDFINDER", -- Looking For Raid (Legacy LFR; prior to SoO)
    [8] = "MYTHIC", -- Mythic Keystone party
    [9] = "NORMAL", -- 40 Player raid
    [11] = "HEROIC", -- Heroic Scenario
    [12] = "NORMAL", -- Normal Scenario
    [14] = "NORMAL", -- Normal raid
    [15] = "HEROIC", -- Heroic raid
    [16] = "MYTHIC", -- Mythic raid
    [17] = "RAIDFINDER", -- Looking For Raid
    [18] = "EVENT", -- Event raid
    [19] = "EVENT", -- Event party
    [20] = "EVENT", -- Event Scenario
    [23] = "MYTHIC", -- Mythic party
    [24] = "TIMEWALKING", -- Timewalking party
    [25] = "PVP", -- World PvP Scenario
    [29] = "PVP", -- PvEvP Scenario
    [30] = "EVENT", -- Event scenario
    [32] = "PVP", -- World PvP Scenario
    [33] = "TIMEWALKING", -- Timewalking raid
    [34] = "PVP", -- PvP
    [38] = "NORMAL", -- Normal scenario
    [39] = "HEROIC", -- Heroic scenario
    [40] = "MYTHIC", -- Mythic scenario
    [45] = "PVP", -- PvP scenario
    [147] = "NORMAL", -- Normal scenario (Warfronts)
    [148] = "NORMAL", -- 20 Player raid (Classic WoW 20mans; ZG, AQ20)
    [149] = "HEROIC", -- Heroic scenario (Warfronts)
    [150] = "NORMAL", -- Normal party
    [151] = "TIMEWALKING", -- Looking For Raid (Timewalking)
    [152] = "NORMAL", -- Visions of N'Zoth scenario
    [153] = "NORMAL", -- Teeming Island scenario
    [167] = "NORMAL", -- Torghast	scenario
    [168] = "NORMAL", -- Path of Ascension: Courage scenario
    [169] = "NORMAL", -- Path of Ascension: Loyalty scenario
    [170] = "NORMAL", -- Path of Ascension: Wisdom scenario
    [171] = "NORMAL", -- Path of Ascension: Humility scenario
}

function Difficulty:LookupID(id)
    return self[id] or "UNKNOWN"
end