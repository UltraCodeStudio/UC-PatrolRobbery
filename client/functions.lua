lib.locale()

function AddNetworkPropTarget(entity, options)
    if Config.Integrations.target == "ox_target" then
        exports.ox_target:addEntity(entity, options)
        return
    end
    print("[ERROR] No target integration found.")
    
end

function Notif(src, msg)
    if Config.Integrations.notify == "ox_lib" then
        TriggerEvent('ox_lib:notify', {
        type = 'success',
        title = locale('name_robbery'),
        description = msg,
        duration = 5000,
        position = 'top-right'
        })
    elseif Config.Integrations.notify == 'esx' then
        exports["esx_notify"]:Notify("success", 3000, msg, locale('name_robbery')) 
    else
        print("[ERROR] No Notify integration found.")
    end
end
function RandomMiniGame()
    local minigames = {'qte', 'circle', 'memory', 'math', 'reaction'}
    return minigames[math.random(1, #minigames)]
end

function ProgressBar(label, duration, options)
    options = options or {}
    if Config.Integrations.progressbar == "ox_lib" then
        return lib.progressBar({
            duration = duration or 3000,
            label = label or locale('work'),
            useWhileDead = options.useWhileDead or false,
            canCancel = options.canCancel ~= false,
            disable = options.disable or {
                move = true,
                car = true,
                combat = true
            },
            anim = options.anim,
            prop = options.prop
        })
    end
    print("[ERROR] No Progress Bar integration found.")
    
end


function RunMiniGame(game)
    local games = Config.MiniGames
    if not game or game == 'random' then
        local keys = {}
        for k in pairs(games) do
            keys[#keys + 1] = k
        end
        game = keys[math.random(#keys)]
    end
    local fn = games[game]
    return fn and fn() or false
end