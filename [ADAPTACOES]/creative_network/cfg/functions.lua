zof = {
    getUserSource = function(user_id)
        return vRP.Source(parseInt(user_id))
    end,
    
    getUserId = function(source)
        return vRP.Passport(source)
    end,

    itemNameList = function(item)
        return (vRP.itemNameList(item) or item)
    end,

    hasPermission = function(user_id, perm)
        return vRP.HasPermission(user_id, perm)
    end,

    getInventoryItemAmount = function(user_id, item)
        return vRP.ItemAmount(user_id, item)
    end,

    tryGetInventoryItem = function(user_id, item, amount)
        return vRP.TryGetInventoryItem(user_id, item, amount)
    end,

    giveInventoryItem = function(user_id, item, qtd)
        return vRP.GiveInventoryItem(user_id, item, qtd)
    end,

    getUserByRegistration = function(placa)
        local plate = vRP.PassportPlate(placa)

        if plate then
            return plate.user
        end

        return nil
    end,

    getSData = function(key)
        local query = vRP.Query("entitydata/GetData", { dkey = key })
        
        if query then
            if parseInt(#query) > 0 then
                return query[1].dvalue
            end
        end

        return json.encode({})
    end,

    setSData = function(key, data)
        return vRP.Query("entitydata/SetData", { dkey = key, dvalue = data })
    end,

    playAnim = function(source, anim)
        return vRPclient.playAnim(source, false, { anim.name, anim.extra }, true)
    end,

    stopAnim = function(source)
        return vRPclient.stopAnim(source, false)
    end,

    deletarObjeto = function(source)
        return vRPclient.removeObjects(source)
    end,
}
