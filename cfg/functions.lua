zof = {
    getUserSource = function(user_id)
        local xPlayer = ESX.GetPlayerFromIdentifier(user_id)
        return xPlayer and xPlayer.source or nil
    end,
    
    getUserId = function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    end,

    itemNameList = function(item)
        local itemData = exports.ox_inventory:Items(item)
        return itemData and itemData.label or item
    end,

    hasPermission = function(user_id, perm)
        local xPlayer = ESX.GetPlayerFromIdentifier(user_id)
        if not xPlayer then return false end
        return xPlayer.getGroup() == perm or xPlayer.job.name == perm
    end,

    getInventoryItemAmount = function(user_id, idname)
        local count = exports.ox_inventory:GetItemCount(user_id, idname)
        return count or 0
    end,

    tryGetInventoryItem = function(user_id, item, amount)
        return exports.ox_inventory:RemoveItem(user_id, item, amount)
    end,

    giveInventoryItem = function(user_id, item, qtd)
        return exports.ox_inventory:AddItem(user_id, item, qtd)
    end,
    
    getUserByRegistration = function(placa)
        local result = MySQL.scalar.await('SELECT owner FROM owned_vehicles WHERE plate = ?', { placa })
        return result
    end,

    setSData = function(key, data)
        return MySQL.prepare.await('INSERT INTO ox_doorlock (name, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = ?', { key, json.encode(data), json.encode(data) })
    end,

    getSData = function(key)
        local result = MySQL.scalar.await('SELECT data FROM ox_doorlock WHERE name = ?', { key })
        return result and json.decode(result) or nil
    end,

    playAnim = function(source, anim)
        if anim.name and anim.extra then
            TriggerClientEvent('ox_lib:playAnim', source, { dict = anim.name, clip = anim.extra, flag = 49 })
        end
    end,

    stopAnim = function(source, upper)
        TriggerClientEvent('ox_lib:stopAnim', source)
    end,

    deletarObjeto = function(source)
        TriggerClientEvent('ox_lib:removeDefaultProximityObjects', source)
    end,

    createObjects = function(dict, anim, prop, flag, hands, height, pos1, pos2, pos3, pos4, pos5)
        -- Sugestão: Utilizar lib.requestModel e CreateObject no Client
        TriggerClientEvent('zof:spawnObjectClient', -1, prop, dict, anim)
    end,
}