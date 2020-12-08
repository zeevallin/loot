-- Raid difficulties define what different kind of raid difficulties exists.
RAID_DIFFICULTIES = {
    ["R"] = "Raid Finder",
    ["N"] = "Normal",
    ["H"] = "Heroic",
    ["M"] = "Mythic"
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
                difficulties = {"R", "N", "H", "M"}
            },
            {
                id = "2417",
                name = "Stone Legion Generals",
                difficulties = {"R", "N", "H", "M"}
            },
            {
                id = "2412",
                name = "The Council of Blood",
                difficulties = {"R", "N", "H", "M"}
            },
            {
                id = "2407",
                name = "Sire Denathrius",
                difficulties = {"R", "N", "H", "M"}
            },
            {
                id = "2406",
                name = "Lady Inerva Darkvein",
                difficulties = {"R", "N", "H", "M"}
            },
            {
                id = "2405",
                name = "Artificer Xy'mox",
                difficulties = {"R", "N", "H", "M"}
            },
            {
                id = "2402",
                name = "Sun King's Salvation",
                difficulties = {"R", "N", "H", "M"}
            },
            {
                id = "2399",
                name = "Sludgefist",
                difficulties = {"R", "N", "H", "M"}
            },
            {
                id = "2398",
                name = "Shriekwing",
                difficulties = {"R", "N", "H", "M"}
            },
            {
                id = "2383",
                name = "Hungering Destroyer",
                difficulties = {"R", "N", "H", "M"}
            }
        }
    }
}