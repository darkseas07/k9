ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('k9:checkItems')
AddEventHandler('k9:checkItems', function(id)
    local xPlayer = ESX.GetPlayerFromId(id)
    local _source = source
    local inventory = xPlayer.inventory
    local hasIllegalItem = false
    for i = 1, #inventory do
        for k, v in pairs(Config.illegal_items) do
            if  inventory[i].count > 0 and inventory[i].name == v then
                hasIllegalItem = true
                break
            end
        end
    end

    if hasIllegalItem then
        TriggerClientEvent("k9:illegalItems", _source, true)
    else
        TriggerClientEvent("k9:illegalItems", _source, false)
    end
end)