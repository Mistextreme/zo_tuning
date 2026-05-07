local ESX = exports['es_extended']:getSharedObject()

local vehiclesInfoCache = {}

local customDefault = {
    neon = { power = false, color = '#ffffff' },
    xenon = { power = false, color = '#ffffff' },
    suspensao = { max = -0.1, min = 0.1, value = 0 },
    camber = { frontal = 0, ambos = 0, traseiro = 0 },
    offset = { frontal = 0, ambos = 0, traseiro = 0 },
    antiLag = { active = 0 },
    westgate = { active = 0 },
    remap = {},
    purgador = { active = 0, value = 1 },
}

function table.empty(self)
    for _, _ in pairs(self) do return false end
    return true
end

-- Funções de Inventário adaptadas para ESX
lib.callback.register('zo_tuning:giveItens', function(source, itens)
    local xPlayer = ESX.GetPlayerFromId(source)
    for i, v in pairs(itens) do
        xPlayer.addInventoryItem(v.item, v.qtd)
    end
end)

lib.callback.register('zo_tuning:checkItens', function(source, itens)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not itens or #itens == 0 then return true end

    local missingItems = ""
    for i, v in pairs(itens) do
        local item = xPlayer.getInventoryItem(v)
        if not item or item.count <= 0 then
            missingItems = missingItems .. "- " .. (item and item.label or v) .. "<br/>"
        end
    end

    if missingItems == "" then return true end
    return false, missingItems
end)

-- Sistema de Permissões (Grupos ESX)
lib.callback.register('zo_tuning:checkPerms', function(source, perms)
    local xPlayer = ESX.GetPlayerFromId(source)
    if perms == nil then return true end

    if type(perms) == "string" then
        return xPlayer.getGroup() == perms
    end

    for _, v in ipairs(perms) do
        if xPlayer.getGroup() == v then return true end
    end

    return false
end)

-- Sincronização de Suspensão
RegisterNetEvent("zo_tuning_suspe")
AddEventHandler('zo_tuning_suspe', function(vehicle, pAlturaAtual, pAlturaAnterior)
    local _source = source
    local altura = pAlturaAnterior
    local subir = pAlturaAtual > pAlturaAnterior

    TriggerClientEvent("zo_tuning:soundSuspensao", _source, subir)

    if subir then
        while altura < pAlturaAtual do
            altura = altura + 0.003
            TriggerClientEvent("synczosuspe_tuning", -1, vehicle, altura)
            Citizen.Wait(1)
        end
    else
        while altura > pAlturaAtual do
            altura = altura - 0.003
            TriggerClientEvent("synczosuspe_tuning", -1, vehicle, altura)
            Citizen.Wait(1)
        end
    end
end)

-- Gerenciamento de Dados (MySQL instead of vRP SData)
local function getVehicleTuningData(key)
    local result = MySQL.scalar.await('SELECT data FROM zo_tuning WHERE vehicle_key = ?', {key})
    if result then return json.decode(result) end
    return nil
end

local function setVehicleTuningData(key, data)
    MySQL.prepare('INSERT INTO zo_tuning (vehicle_key, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = ?', {key, json.encode(data), json.encode(data)})
end

lib.callback.register('zo_tuning:getCustom', function(source, infos)
    if not infos or not infos.key then return customDefault end
    local custom = getVehicleTuningData(infos.key)
    if not custom or table.empty(custom) then return customDefault end
    return custom
end)

RegisterNetEvent('zo_tuning:saveCustom')
AddEventHandler('zo_tuning:saveCustom', function(custom, infos, vNetId)
    if infos and infos.key then
        setVehicleTuningData(infos.key, custom)
        custom.vnetid = vNetId
        vehiclesInfoCache[infos.keyCache] = custom
    end
end)

AddEventHandler('esx:playerLoaded', function(source, xPlayer)
    TriggerClientEvent('zo_tuning:updateVehicles', source, vehiclesInfoCache)
end)