function AddItem(item, amount, src)
    if Config.Integrations.inventory == "ox_inventory" then
        exports.ox_inventory:AddItem(src, item, amount)
        return
    end
    print("[ERROR] No Inventory integration found.")
end

function NotifServer(src, msg)
    if Config.Integrations.notify == "ox_lib" then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            title = 'Construction Robbery',
            description = msg,
            duration = 5000,
            position = 'top-right'
        })
        return
    end
    print("[ERROR] No Notify integration found.")
    
end

function CallPolice(coords)
    --Add your police alerting code here
end