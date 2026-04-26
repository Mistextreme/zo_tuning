zof = {
    getUserSource = function(user_id)
        return vRP.userSource(parseInt(user_id))
    end,
    
    getUserId = function(source)
        return vRP.getUserId(source)
    end,

    itemNameList = function(item)
        return (itemName(item) or item)
    end,

    hasPermission = function(user_id, perm)
        return vRP.hasPermission(user_id, perm)
    end,

    getInventoryItemAmount = function(user_id, item)
        local item = vRP.getInventoryItemAmount(user_id, item)
        return (item[1] or 0)
    end,

    tryGetInventoryItem = function(user_id, item, amount)
        return vRP.tryGetInventoryItem(user_id, item, amount)
    end,

    giveInventoryItem = function(user_id, item, qtd)
        return vRP.giveInventoryItem(user_id, item, qtd)
    end,
    
    getUserByRegistration = function(placa)
        local plate = vRP.userPlate(placa)
        if type(plate) == "boolean" then return nil end

        return plate
    end,

    setSData = function(key, data)
        return vRP.execute("entitydata/setData", { dkey = key, value = data })
    end,

    getSData = function(key)
        local query = vRP.query("entitydata/getData", { dkey = key })
        if parseInt(#query) > 0 then
            return query[1]["dvalue"]
        end

        return json.encode({})
    end,

    playAnim = function(source, anim)
        return vRPclient._playAnim(source, false, { anim.name, anim.extra }, true)
    end,

    stopAnim = function(source)
        return vRPclient._stopAnim(source, false)
    end,

    deletarObjeto = function(source)
        return vRPclient.DeletarObjeto(source)
    end,
}
