zof = {
    getUserSource = function(user_id)
        return vRP.Source(parseInt(user_id))
    end,
    
    getUserId = function(source)
        return vRP.Passport(source)
    end,

    itemNameList = function(item)
        -- vRP doesn't have itemNameList, using item name directly
        return item
    end,

    hasPermission = function(user_id, perm)
        return vRP.HasPermission(user_id, perm, 1)
    end,

    getInventoryItemAmount = function(user_id, idname)
        return vRP.InventoryItemAmount(user_id, idname)
    end,

    tryGetInventoryItem = function(user_id, item, amount)
        return vRP.TakeItem(user_id, item, amount, true)
    end,

    giveInventoryItem = function(user_id, item, qtd)
        return vRP.GiveItem(user_id, item, qtd, true)
    end,
    
    getUserByRegistration = function(placa)
        return vRP.PassportPlate(placa)
    end,

    setSData = function(key, data)
        if type(data) == "table" then
            data = json.encode(data)
        end
        return vRP.SetSrvData(key, data, true)
    end,

    getSData = function(key)
        return vRP.GetSrvData(key, true)
    end,

    playAnim = function(source, anim)
        -- Usar a função nativa do vRP para animações
        if anim.name and anim.extra then
            return vRPclient._playAnim(source, false, {{ anim.name, anim.extra }}, true)
        elseif anim.upper and anim.sequency then
            return vRPclient._playAnim(source, anim.upper, anim.sequency, anim.loop or true)
        end
    end,

    stopAnim = function(source, upper)
        return vRPclient._stopAnim(source, upper or false)
    end,

    deletarObjeto = function(source)
        -- Tentar diferentes métodos para remover objetos
        if vRPclient.DeletarObjeto then
            return vRPclient.DeletarObjeto(source)
        elseif vRPclient.removeObjects then
            return vRPclient.removeObjects(source, 1)
        else
            -- Fallback: usar função nativa
            return vRPclient._removeObjects(source, 1)
        end
    end,

    createObjects = function(dict, anim, prop, flag, hands, height, pos1, pos2, pos3, pos4, pos5)
        -- Criar objetos/props usando vRP
        if vRPclient.createObjects then
            return vRPclient.createObjects(dict, anim, prop, flag, hands, height, pos1, pos2, pos3, pos4, pos5)
        elseif tvRP.createObjects then
            return tvRP.createObjects(dict, anim, prop, flag, hands, height, pos1, pos2, pos3, pos4, pos5)
        else
            -- Fallback: usar função nativa do vRP
            return vRPclient._createObjects(dict, anim, prop, flag, hands, height, pos1, pos2, pos3, pos4, pos5)
        end
    end,
}
