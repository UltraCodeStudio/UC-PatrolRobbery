Config = {}

Config.Debug = false

Config.Integrations = {
    target = "ox_target",
    progressbar = "ox_lib",
    notify = "ox_lib",
    inventory = "ox_inventory",
}
--Add new minigames here
Config.MiniGames = {
    skill_multi = function()
        return lib.skillCheck({ 'easy', 'medium' }, { 'w', 'a', 's', 'd' })
    end,

    skill_single = function()
        return lib.skillCheck({ 'medium' }, { 'e' })
    end,

    
}

Config.PoliceAlertCooldown = 5 -- in minutes

Config.KillableGuards = true
Config.AttackPlayers = true
Config.RespawnTime = 5 -- in minutes

--Find more here https://docs.fivem.net/docs/game-references/speeches/
Config.GuardVoiceLines = {
    "CHALLENGE_THREATEN",
    "GENERIC_CURSE_HIGH",
    "GENERIC_INSULT_HIGH",
    "GENERIC_SHOCKED_HIGH",
    "GENERIC_HI",
    "GENERIC_HOWS_IT_GOING",
    "GENERIC_HELLO",
}

Config.Locations = {

    ["ConstructionSite"] = {
        guards = {
            {
            model = "s_m_y_construct_01",
            coords = vector4(-903.57, 413.37, 83.97, 350),
            path = {
                vector3(-895.86, 414.10, 85.64),
                vector3(-919.17, 396.54, 79.12),
                vector3(-921.09, 377.64, 79.51),

            }
            },
            {
            model = "s_m_y_construct_01",
            coords = vector4(-925.00, 380.72, 79.12, 344),
            path = {
                vector3(-919.45, 410.06, 79.74),
                vector3(-957.76, 398.76, 75.86),
                vector3(-960.18, 389.36, 73.86),
                vector3(-957.27, 379.29, 73.05),
                vector3(-940.17, 379.81, 76.41),
                vector3(-925.00, 380.72, 79.12)



            }
            },
        },
        lootables = {
            ["Safe"] = {
                model = "xm3_prop_xm3_safe_01a", --Find here https://forge.plebmasters.de/
                lootAnimation = {
                    dict = 'mini@safe_cracking',
                    clip = 'dial_turn_clock_fast_1'
                },
                minigame = "skill_multi",
                coords = vector4(-935.24, 393.21, 76.75, 286),
                loot = {
                    { item = "goldbar", amount = 1 },
                    { item = "diamond", amount = 2 },
                },
            },
            ["box"] = {
                model = "xm3_prop_xm3_ind_cs_box_01a", 
                lootAnimation = {
                    dict = 'anim@gangops@facility@servers@bodysearch@',
                    clip = 'player_search'
                },
                minigame = "skill_multi",
                coords = vector4(-935.59, 404.67, 78.14, 203),
                loot = {
                    { item = "goldbar", amount = 1 },
                    { item = "plastic", amount = 3 },
                },
            },
        },
    },
    
}