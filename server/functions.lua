function AddItem(item, amount, src)
    exports.ox_inventory:AddItem(src, item, amount)
end

function NotifServer(src, msg)
    
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        title = 'Construction Robbery',
        description = msg,
        duration = 5000,
        position = 'top-right'
    })
end

function CallPolice(coords)
    --Add your police alerting code here
end