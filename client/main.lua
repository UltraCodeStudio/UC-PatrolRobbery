local ControlledGuards = {}  -- [netId] = true/false

local GuardDebug = {} -- [netId] = { path=..., idx=..., target=vector3, enabled=true }

local function v3(x,y,z) return vector3(x+0.0, y+0.0, z+0.0) end

local function DrawText3D(x, y, z, text)
    local onScreen,_x,_y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.30, 0.30)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)
end

local function DrawPedRadiusSphere(ped, radius)
    if not DoesEntityExist(ped) then return end
    local c = GetEntityCoords(ped)
    DrawMarker(
        28,
        c.x, c.y, c.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        radius / 5.0, radius / 5.0, radius / 5.0,
        255, 0, 0, 80,
        false, false, 2, false, nil, nil, false
    )
end


local function DrawWaypointMarker(p, label)
    DrawMarker(
        2,
        p.x, p.y, p.z + 0.25,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.25, 0.25, 0.25,
        255, 255, 0, 180,
        false, false, 2, false, nil, nil, false
    )
    DrawText3D(p.x, p.y, p.z + 0.6, label)
end

local function EnsureDebugThread()
    Citizen.CreateThread(function()
        while true do
            for netId, info in pairs(GuardDebug) do
                if type(info) == "table" and info.enabled and info.path then
                    
                    for i, c in ipairs(info.path) do
                        local p = v3(c.x, c.y, c.z)
                        DrawWaypointMarker(p, ("G%s #%d"):format(netId, i))

                        
                        if i < #info.path then
                            local n = info.path[i+1]
                            DrawLine(p.x, p.y, p.z + 0.3, n.x, n.y, n.z + 0.3, 255, 255, 0, 160)
                        end
                    end

                    
                    if info.guard and DoesEntityExist(info.guard) and info.target then
                        local gp = GetEntityCoords(info.guard)
                        DrawLine(gp.x, gp.y, gp.z + 0.9, info.target.x, info.target.y, info.target.z + 0.3, 0, 255, 255, 200)
                        DrawPedRadiusSphere(info.guard, 30.0)
                        DrawText3D(gp.x, gp.y, gp.z + 1.1, ("Guard %s wp %s"):format(netId, tostring(info.idx)))
                    end
                end
            end

            Citizen.Wait(0)
        end
    end)
end



RegisterNetEvent("UC-PatrolRobbery:guardSpawned")
AddEventHandler("UC-PatrolRobbery:guardSpawned", function(netId)
    if Config.Debug then
        print("Guard spawned with netId:", netId)
    end
    local ped = NetworkGetEntityFromNetworkId(netId)
    SetEntityInvincible(ped, true)
    SetEntityProofs(ped, true,true,true,true,true,true,true,true)
    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
end)

RegisterNetEvent("UC-PatrolRobbery:controlGuard")
AddEventHandler("UC-PatrolRobbery:controlGuard", function(netId, shouldControl, path)

   
    

    ControlledGuards[netId] = shouldControl == true

    local guard = NetworkGetEntityFromNetworkId(netId)
    if guard == 0 or not DoesEntityExist(guard) then
        return
    end

    if shouldControl then
       
        NetworkRequestControlOfEntity(guard)

        
        StartFollowingPath(netId, guard, path)

    else
        ControlledGuards = {}
    end
end)

function RunStoppingAnimation(guard)
    TaskStartScenarioInPlace(guard, "WORLD_HUMAN_STAND_MOBILE", 0, true)
    Wait(10000)
    SetPedShouldPlayImmediateScenarioExit(guard)
end

function CheckArea(ped, radius)
    radius = radius or 5.0
    

    local pedCoords = GetEntityCoords(ped)
    local myId = PlayerId()

    for _, player in ipairs(GetActivePlayers()) do
      
            local playerPed = GetPlayerPed(player)
            if playerPed ~= 0 then
                local pCoords = GetEntityCoords(playerPed)

                local dx = pCoords.x - pedCoords.x
                local dy = pCoords.y - pedCoords.y
                local dz = pCoords.z - pedCoords.z

                if (dx*dx + dy*dy + dz*dz) <= radius then
                    
                    if HasEntityClearLosToEntity(playerPed, ped, 17) then
                        TaskTurnPedToFaceEntity(ped, playerPed, -1)
                        TaskLookAtEntity(guard, playerPed, -1, 2048, 3)
                        return true, player, playerPed
                        
                    end
                end
            end
        --end
    end

    return false
end

local function MoveTo(guard, coord)
    TaskFollowNavMeshToCoord(guard, coord.x, coord.y, coord.z, 1.0, -1, 0.0, 0, 40000.0)
end



local function AimFlashlightAtPlayer(guard, playerPed)
    if not DoesEntityExist(guard) or not DoesEntityExist(playerPed) then
        return
    end

 
    if GetSelectedPedWeapon(guard) ~= `WEAPON_FLASHLIGHT` then
        GiveWeaponToPed(guard, `WEAPON_FLASHLIGHT`, 0, false, true)
        SetCurrentPedWeapon(guard, `WEAPON_FLASHLIGHT`, true)
    end


    local line = Config.GuardVoiceLines[math.random(#Config.GuardVoiceLines)]
    PlayPedAmbientSpeechNative(
        guard,
        line,
        "SPEECH_PARAMS_FORCE_SHOUTED"
    )



    TaskTurnPedToFaceEntity(guard, playerPed, 500)
    TaskAimGunAtEntity(guard, playerPed, -1, true)
end

local function StopFlashlight(guard)
    if not DoesEntityExist(guard) then return end


    ClearPedTasks(guard)


    if HasPedGotWeapon(guard, `WEAPON_FLASHLIGHT`, false) then
        RemoveWeaponFromPed(guard, `WEAPON_FLASHLIGHT`)
    end
end



local function BeginWaypoint(guard, coord)
    RunStoppingAnimation(guard)
    MoveTo(guard, coord)
    Wait(1000)
end

local function UpdateDistanceRemaining(guard)
    local retval, distance, isPathReady = GetNavmeshRouteDistanceRemaining(guard)
    return retval, distance, isPathReady
end

local function EngagePlayerLoop(netId, guard, coord, playerPed)
 
    while true do
        if not DoesEntityExist(guard) then
            break
        end

        
        AimFlashlightAtPlayer(guard, playerPed)
        Citizen.Wait(1000)

        local check, playerId, newPlayerPed = CheckArea(guard, 30.0)
        TriggerServerEvent('UC-PatrolRobbery:callPolice', netId)
        if Config.Debug then
            print("Guard ".. tostring(netId) .." spotted player ".. tostring(playerId))
        end
        if not check then
            MoveTo(guard, coord)
            StopFlashlight(guard)
            Citizen.Wait(1000)
            break
        end

        
        playerPed = newPlayerPed
    end
end

local function HandleWaypoint(netId, guard, coord, idx, path)
    -- Debug store
    if Config.Debug then
        EnsureDebugThread()
        GuardDebug[netId] = GuardDebug[netId] or { enabled = true }
        GuardDebug[netId].guard = guard
        GuardDebug[netId].path = path
        GuardDebug[netId].idx = idx
        GuardDebug[netId].target = v3(coord.x, coord.y, coord.z)
    end

    local distance = 9999.0
    BeginWaypoint(guard, coord)

    while distance > 1.5 do
        local retval, newDistance, isPathReady = UpdateDistanceRemaining(guard)
        distance = newDistance

        if Config.Debug then
            print(("Guard %s -> wp %d dist=%.2f ready=%s"):format(netId, idx, distance or -1, tostring(isPathReady)))
        end

        local check, playerId, playerPed = CheckArea(guard, 30.0)
        if check then
            EngagePlayerLoop(netId, guard, coord, playerPed)
        end

        Citizen.Wait(250)
    end
end




function FollowPathLoop(netId, guard, path)
    return promise.new(function(resolve)
        for idx, coord in ipairs(path) do
            HandleWaypoint(netId, guard, coord, idx, path)
        end
        resolve("Done")
    end)
end



function StartFollowingPath(netId, guard, path)
    Citizen.CreateThread(function()
        while ControlledGuards and ControlledGuards[netId] do
            if not DoesEntityExist(guard) then
                break
            end
            local ok = pcall(function ()
                return Citizen.Await(FollowPathLoop(netId, guard, path))
            end)
            Citizen.Wait(5000)
        end
    end)
end

Citizen.CreateThread(function()
    Citizen.Wait(4000)  
   local result = lib.callback.await('UC-PatrolRobbery:getSpawnedLootables', false)
    
    for _, lootData in ipairs(result) do
        
         local lootEnt = NetworkGetEntityFromNetworkId(lootData.netId)
         
         if lootEnt ~= 0 and DoesEntityExist(lootEnt) then
              local options = {
                {
                     name = 'loot_construction_safe',
                     icon = 'fa-solid fa-box-open',
                     label = 'Loot '.. lootData.name,
                     distance = 3.0,
                     onSelect = function()
                        
                        local success = ProgressBar('Looting '.. lootData.name ..'...', 5000, {
                            
                            anim = {
                                dict = lootData.lootAnimation.dict,
                                clip = lootData.lootAnimation.clip
                            }
                        })
                        if success then
                            local success = RunMiniGame(lootData.minigame)
                            
                            if not success then
                                Notif(PlayerId(), 'You failed to loot the '.. lootData.name ..'.')
                                return
                            end
                            TriggerServerEvent('UC-PatrolRobbery:lootLootable', lootData.netId)
                        end
                     end,
                }
              }
              
              AddNetworkPropTarget(lootData.netId, options)
         end
    end
end)


