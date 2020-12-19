-- Raid difficulties define what different kind of raid difficulties exists.
RAID_DIFFICULTIES = {
    ["RAIDFINDER"] = "Raid Finder",
    ["NORMAL"] = "Normal",
    ["HEROIC"] = "Heroic",
    ["MYTHIC"] = "Mythic"
}

-- Raid instances is a map of raid instances, their encounters and their difficulties.
RAID_INSTANCES = {
    {
        id = "2296",
        name = "Castle Nathria",
        encounters = {
            {
                id = "2418",
                name = "Huntsman Altimor",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            },
            {
                id = "2417",
                name = "Stone Legion Generals",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            },
            {
                id = "2412",
                name = "The Council of Blood",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            },
            {
                id = "2407",
                name = "Sire Denathrius",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            },
            {
                id = "2406",
                name = "Lady Inerva Darkvein",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            },
            {
                id = "2405",
                name = "Artificer Xy'mox",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            },
            {
                id = "2402",
                name = "Sun King's Salvation",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            },
            {
                id = "2399",
                name = "Sludgefist",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            },
            {
                id = "2398",
                name = "Shriekwing",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            },
            {
                id = "2383",
                name = "Hungering Destroyer",
                difficulties = {"RAIDFINDER", "NORMAL", "HEROIC", "MYTHIC"}
            }
        }
    }
}