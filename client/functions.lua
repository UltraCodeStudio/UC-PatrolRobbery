function AddNetworkPropTarget(entity, options)
    exports.ox_target:addEntity(entity, options)
end

function RandomMiniGame()
    local minigames = {'qte', 'circle', 'memory', 'math', 'reaction'}
    return minigames[math.random(1, #minigames)]
end

function ProgressBar(label, duration, options)
    options = options or {}
    return lib.progressBar({
        duration = duration or 3000,
        label = label or 'Working...',
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

function Notif(src, msg)
    TriggerEvent('ox_lib:notify', {
        type = 'success',
        title = 'Construction Robbery',
        description = msg,
        duration = 5000,
        position = 'top-right'
    })
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