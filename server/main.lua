local Guards = {}           -- { [i] = { netId=..., entity=..., controller=nil, path = {...}, alertCooldown = 0 } }
local Lootables = {}        -- { [i] = { netId=..., entity=..., name=..., cooldown=..., loot = {...}, lootAnimation = {...}, minigame = ... } }
local CONTROL_RADIUS = 120.0
local SELECT_INTERVAL_MS = 3000
local SWITCH_ADVANTAGE = 10.0 

function GiveRewards(lootableTable, src)
    local items = lootableTable.loot
    SetCooldown(lootableTable, 1 * 60 * 1000)
    for _, itemData in ipairs(items) do
        local item = itemData.item
        local amount = itemData.amount
        AddItem(item, amount, src)
    end
end



function SetCooldown(lootableTable, cooldownTime)
    Citizen.CreateThread(function ()
        lootableTable.cooldown = cooldownTime
        Wait(cooldownTime)
        lootableTable.cooldown = 0
    end)
end

function SetGuardAlertCooldown(guardTable, cooldownTime)
    Citizen.CreateThread(function ()
        guardTable.alertCooldown = cooldownTime
        Wait(cooldownTime)
        guardTable.alertCooldown = 0
    end)
end

RegisterNetEvent('UC-PatrolRobbery:callPolice', function(guardnetId)
    
    local src = source
    for i = 1, #Guards do
        local g = Guards[i]
        if g.netId == guardnetId then
            if g.alertCooldown <= 0 then
                SetGuardAlertCooldown(g, Config.PoliceAlertCooldown * 60 * 1000)
                CallPolice(GetEntityCoords(g.entity))
            end
            break
        end
    end
end)
RegisterNetEvent('UC-PatrolRobbery:lootLootable', function(netID)
    local src = source
    for i = 1, #Lootables do
        local l = Lootables[i]
        if l.netId == netID then
            
            if l.cooldown == 0 then
                GiveRewards(l, src)
            else
                
                NotifServer(src, "Lootable is on cooldown, please wait "..math.floor(l.cooldown / 1000).." seconds.")
            end
            break
        end
    end
end)

function spawnLootables()
    
    for locationName, locationData in pairs(Config.Locations) do
        for lootName, lootData in pairs(locationData.lootables) do
           
            local modelHash = joaat(lootData.model)
            
            
            local lootEnt = CreateObject(modelHash, lootData.coords.x, lootData.coords.y, lootData.coords.z, true, true)
            Wait(500)
            if DoesEntityExist(lootEnt) then
                SetEntityHeading(lootEnt, lootData.coords.w)
                FreezeEntityPosition(lootEnt, true)

                local netId = NetworkGetNetworkIdFromEntity(lootEnt)
                Lootables[#Lootables + 1] = { netId = netId, entity = lootEnt, name = lootName, cooldown = 0, loot = lootData.loot, lootAnimation = lootData.lootAnimation, minigame = lootData.minigame  }
                    
            else
                print("[UC-PatrolRobbery] Failed to spawn model: "..lootData.model)
            end
        
           
            
        end
    end
end

lib.callback.register('UC-PatrolRobbery:getSpawnedLootables', function(source)
    local lootablesData = {}
    for i = 1, #Lootables do
        local l = Lootables[i]
        lootablesData[i] = {
            netId = l.netId,
            name = l.name,
            cooldown = l.cooldown,
            loot = l.loot,
            lootAnimation = l.lootAnimation or "",
            minigame = l.minigame or nil
        }
    end
    return lootablesData
end)

local function CreateGuardPed(pedType, modelName, coords)
    local modelHash = joaat(modelName)
    local ped = CreatePed(pedType, modelHash, coords.x, coords.y, coords.z, coords.w, true, true)
    return ped
end

local function SpawnGuards()
    Guards = {}

    for locationName, locationData in pairs(Config.Locations) do
        for _, guardData in ipairs(locationData.guards) do
            local ped = CreateGuardPed(26, guardData.model, guardData.coords)
            Wait(100) -- Give some time for the ped to spawn properly
            if ped ~= 0 and DoesEntityExist(ped) then
                local netId = NetworkGetNetworkIdFromEntity(ped)
                Guards[#Guards + 1] = { netId = netId, entity = ped, controller = nil, path = guardData.path, alertCooldown = 0 }

                
                TriggerClientEvent("UC-PatrolRobbery:guardSpawned", -1, netId)
            else
                print("[UC-PatrolRobbery] Failed to spawn guard ped")
            end
        end
    end
end

local function SetController(guardIndex, newSrc)
    local g = Guards[guardIndex]
    if not g then return end
    if g.controller == newSrc then return end

  
    if g.controller then
        TriggerClientEvent("UC-PatrolRobbery:controlGuard", g.controller, g.netId, false, g.path)
    end

    g.controller = newSrc

  
    if g.controller then
        TriggerClientEvent("UC-PatrolRobbery:controlGuard", g.controller, g.netId, true, g.path)
    end
end

local function ChooseClosestControllerForGuard(guardIndex)
    local g = Guards[guardIndex]
    if not g then return end

    local guardEnt = g.entity
    if not guardEnt or guardEnt == 0 or not DoesEntityExist(guardEnt) then
        SetController(guardIndex, nil)
        return
    end

    local g = GetEntityCoords(guardEnt)

   
    local currentDist = 999999.0
    if g.controller then
        local cPed = GetPlayerPed(g.controller)
        if cPed and cPed ~= 0 and DoesEntityExist(cPed) then
            local c = GetEntityCoords(cPed)
            currentDist = #(c - g)
            if currentDist > CONTROL_RADIUS then
                currentDist = 999999.0
            end
        else
            currentDist = 999999.0
        end
    end

    local bestSrc = nil
    local bestDist = 999999.0

    for _, srcStr in ipairs(GetPlayers()) do
        local src = tonumber(srcStr)
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            local p = GetEntityCoords(ped)
            local d = #(p - g)

            if d <= CONTROL_RADIUS and d < bestDist then
                bestDist = d
                bestSrc = src
            end
        end
    end

    if not bestSrc then
        SetController(guardIndex, nil)
        return
    end

 
    if not g.controller then
        SetController(guardIndex, bestSrc)
        return
    end

   
    if bestSrc ~= g.controller and (bestDist + SWITCH_ADVANTAGE) < currentDist then
        SetController(guardIndex, bestSrc)
    end
end

local function ChooseControllers()
    for i = 1, #Guards do
        ChooseClosestControllerForGuard(i)
    end
end


CreateThread(function()
    Wait(1000)
    SpawnGuards()
    spawnLootables()
    while true do
        Wait(SELECT_INTERVAL_MS)
        if #Guards > 0 then
            ChooseControllers()
        end
    end
end)


AddEventHandler("playerDropped", function()
    local src = source
    for i = 1, #Guards do
        if Guards[i].controller == src then
            SetController(i, nil)
        end
    end
end)


AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for i = 1, #Guards do
        local guard = Guards[i].entity
        if guard and guard ~= 0 and DoesEntityExist(guard) then
            DeleteEntity(guard)
        end
    end
    for i = 1, #Lootables do
        local loot = Lootables[i].entity
        
        if loot and loot ~= 0 and DoesEntityExist(loot) then
            DeleteEntity(loot)
        end
    end
end)



