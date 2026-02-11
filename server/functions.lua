lib.locale()

function AddItem(item, amount, src)
    if Config.Integrations.inventory == "ox_inventory" then
        if not exports.ox_inventory:CanCarryItem(src, item, 1) then
            NotifServer(src, locale('not_enought_space', item))
            return
        end
        exports.ox_inventory:AddItem(src, item, amount)
        return
    end
    print("[ERROR] No Inventory integration found.")
end

function NotifServer(src, msg)
    if Config.Integrations.notify == "ox_lib" then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            title = locale('name_robbery'),
            description = msg,
            duration = 5000,
            position = 'top-right'
        })
    elseif Config.Integrations.notify == "esx" then
        TriggerClientEvent("ESX:Notify", src, "success", 3000, msg, locale('name_robbery'))
    else
        print("[ERROR] No Notify integration found.")
    end
end

function CallPolice(coords)
    --Add your police alerting code here
end