-- script/server/server.lua (ESX-Legacy conversion)
-- All vRP Tunnel/Proxy/module/vRPclient references replaced with ESX-Legacy equivalents.
-- All original callbacks, events, cache logic, and vehicle/item/perm mechanics preserved.

vehiclesInfoCache = {}

local customDefault = {
    neon = {
        power = false,
        color = "#ffffff",
    },
    xenon = {
        power = false,
        color = "#ffffff",
    },
    suspensao = {
        max   = -0.1,
        min   =  0.1,
        value =  0,
    },
    camber = {
        frontal  = 0,
        ambos    = 0,
        traseiro = 0,
    },
    offset = {
        frontal  = 0,
        ambos    = 0,
        traseiro = 0,
    },
    antiLag = {
        active = 0,
    },
    westgate = {
        active = 0,
    },
    remap = {},
    purgador = {
        active = 0,
        value  = 1,
    },
}

function table.empty(self)
    for _, _ in pairs(self) do return false end
    return true
end

-- ─── ITEM HELPERS ────────────────────────────────────────────────────────────

-- Give a list of items to the player.
-- Replaces original src.giveItens which called zof.giveInventoryItem (vRP).
local function giveItens(source, itens)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    for _, v in pairs(itens) do
        xPlayer.addInventoryItem(v.item, v.qtd)
    end
end

-- Check whether the player has at least one of any item in the list.
-- Returns (true) or (false, itemNameString).
-- Replaces original src.checkItens.
local function checkItens(source, itens)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false, "" end

    if not itens or json.encode(itens) == json.encode({}) then return true end

    local itensName = ""
    for _, v in pairs(itens) do
        local item = xPlayer.getInventoryItem(v)
        if item and item.count > 0 then return true end
        itensName = itensName .. "- " .. zof.itemNameList(v) .. "<br/>"
    end

    return false, itensName
end

-- Remove one of each item in the list from the player's inventory.
-- Returns true if all items were present and removed.
local function removeItens(source, itens)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local possuiItens, _ = checkItens(source, itens)
    if possuiItens then
        for _, v in pairs(itens) do
            xPlayer.removeInventoryItem(v, 1)
        end
    end
    return possuiItens
end

-- ─── PERMISSION HELPER ───────────────────────────────────────────────────────

-- Check whether the player has at least one of the listed permissions/groups.
-- Replaces original src.checkPerms which called zof.hasPermission (vRP).
local function checkPerms(source, perms)
    if perms == nil then return true end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    if type(perms) == "string" then
        return zof.hasPermission(xPlayer.getIdentifier(), perms)
    end

    -- Empty table = no restriction
    local next = next
    if next(perms) == nil then return true end

    for _, v in ipairs(perms) do
        if zof.hasPermission(xPlayer.getIdentifier(), v) then
            return true
        end
    end

    return false
end

-- ─── VEHICLE INFO HELPERS ────────────────────────────────────────────────────

-- Return a metadata table describing the vehicle nearest to / driven by the player.
-- Replaces original src.getInfos / vCLIENT.vehList (Tunnel call to client).
-- ESX-Legacy: we request this from the client via a registered callback.
-- The result is assembled server-side once the client responds with plate + vname + vnet.
local function buildInfosFromClientData(source, clientData)
    if not clientData then return nil end

    local plate  = clientData.plate
    local vname  = clientData.vname
    local vnetid = clientData.vnetid

    if not plate or not vname then return nil end

    -- Black-list check
    if veiculosBlackList[vname] then return nil end

    local placa_user_id = zof.getUserByRegistration(plate)
    if not placa_user_id then return nil end

    return {
        placa_user_id = placa_user_id,
        vname         = vname,
        placa         = plate,
        vnetid        = tostring(vnetid),
        keyCache      = tostring(vnetid) .. plate,
        key           = placa_user_id .. "veh_" .. vname .. "placa_" .. plate,
    }
end

-- Retrieve stored tuning data for a vehicle, falling back to customDefault.
local function getCustom(infos)
    if infos then
        local tuning = zof.getSData("zoCustomVehicle:" .. infos.key)
        local custom = {}

        if tuning then
            if type(tuning) == "string" then
                custom = json.decode(tuning) or {}
            elseif type(tuning) == "table" then
                custom = tuning
            end
        end

        if table.empty(custom) then
            return customDefault, nil
        end

        return custom, infos
    end
    return customDefault, nil
end

-- ─── ESX SERVER CALLBACKS ────────────────────────────────────────────────────

-- zo_tuning:checkPerms
-- Client sends a permissions table; server verifies for the calling source.
ESX.RegisterServerCallback("zo_tuning:checkPerms", function(source, cb, perms)
    cb(checkPerms(source, perms))
end)

-- zo_tuning:checkItens
-- Client sends an item list; server checks the player's ESX inventory.
ESX.RegisterServerCallback("zo_tuning:checkItens", function(source, cb, itens)
    local ok, names = checkItens(source, itens)
    cb(ok, names)
end)

-- zo_tuning:removeItens
-- Client requests item removal after install animation completes.
ESX.RegisterServerCallback("zo_tuning:removeItens", function(source, cb, itens)
    cb(removeItens(source, itens))
end)

-- zo_tuning:getInfos
-- Client requests the metadata block for its current/nearest vehicle.
-- We ask the client for its vehicle data first, then build the infos table.
ESX.RegisterServerCallback("zo_tuning:getInfos", function(source, cb, params)
    -- params may be nil (use current vehicle) or a table { vname, vehicle, vnetid }
    if params then
        -- Build from supplied params (used by sync.lua for remote vehicles)
        local plate = params.plate
        if not plate and params.vehicle then
            -- The client sends the entity handle; resolve plate client-side before calling
            -- For remote vehicle syncs the client already includes the plate in params.
        end

        local infos = buildInfosFromClientData(source, params)
        cb(infos)
    else
        -- Ask the client for its current vehicle data, then build infos
        TriggerClientEvent("zo_tuning:requestVehData", source)
        -- The client will respond via zo_tuning:responseVehData; handled below.
        -- We cache a pending callback keyed by source.
        pendingGetInfosCb = pendingGetInfosCb or {}
        pendingGetInfosCb[source] = cb
    end
end)

pendingGetInfosCb = {}

RegisterNetEvent("zo_tuning:responseVehData")
AddEventHandler("zo_tuning:responseVehData", function(clientData)
    local source = source
    if pendingGetInfosCb[source] then
        local infos = buildInfosFromClientData(source, clientData)
        pendingGetInfosCb[source](infos)
        pendingGetInfosCb[source] = nil
    end
end)

-- zo_tuning:checkVehicleInfos
-- Returns the full custom tuning table for the player's current vehicle.
ESX.RegisterServerCallback("zo_tuning:checkVehicleInfos", function(source, cb, params)
    -- Ask the client for its vehicle data
    TriggerClientEvent("zo_tuning:requestVehData", source)

    pendingCheckVehicleCb = pendingCheckVehicleCb or {}
    pendingCheckVehicleCb[source] = { cb = cb, params = params }
end)

pendingCheckVehicleCb = {}

RegisterNetEvent("zo_tuning:responseVehDataForCheck")
AddEventHandler("zo_tuning:responseVehDataForCheck", function(clientData)
    local source = source
    if pendingCheckVehicleCb[source] then
        local entry  = pendingCheckVehicleCb[source]
        local params = entry.params or clientData

        local infos = buildInfosFromClientData(source, clientData)

        if infos then
            if vehiclesInfoCache[infos.keyCache] then
                entry.cb(vehiclesInfoCache[infos.keyCache])
                pendingCheckVehicleCb[source] = nil
                return
            end

            local custom, isNotDefault = getCustom(infos)
            if isNotDefault ~= nil then
                custom.vnetid = infos.vnetid
                vehiclesInfoCache[infos.keyCache] = custom
            end

            entry.cb(custom)
        else
            entry.cb(false)
        end

        pendingCheckVehicleCb[source] = nil
    end
end)

-- Unified listener: client sends veh data in response to either request type.
-- We route to whichever pending callback is waiting.
RegisterNetEvent("zo_tuning:vehDataResponse")
AddEventHandler("zo_tuning:vehDataResponse", function(clientData)
    local source = source

    if pendingGetInfosCb and pendingGetInfosCb[source] then
        local infos = buildInfosFromClientData(source, clientData)
        pendingGetInfosCb[source](infos)
        pendingGetInfosCb[source] = nil
        return
    end

    if pendingCheckVehicleCb and pendingCheckVehicleCb[source] then
        local entry = pendingCheckVehicleCb[source]
        local infos = buildInfosFromClientData(source, clientData)

        if infos then
            if vehiclesInfoCache[infos.keyCache] then
                entry.cb(vehiclesInfoCache[infos.keyCache])
                pendingCheckVehicleCb[source] = nil
                return
            end

            local custom, isNotDefault = getCustom(infos)
            if isNotDefault ~= nil then
                custom.vnetid = infos.vnetid
                vehiclesInfoCache[infos.keyCache] = custom
            end

            entry.cb(custom)
        else
            entry.cb(false)
        end

        pendingCheckVehicleCb[source] = nil
    end
end)

-- ─── SERVER EVENTS ───────────────────────────────────────────────────────────

-- zo_tuning:setCustom
-- Persists tuning data and updates the server cache.
-- Replaces original src.setCustom.
RegisterNetEvent("zo_tuning:setCustom")
AddEventHandler("zo_tuning:setCustom", function(custom, infos, vNetId)
    if infos then
        zof.setSData("zoCustomVehicle:" .. infos.key, json.encode(custom))
        custom.vnetid = vNetId
        vehiclesInfoCache[infos.keyCache] = custom
    end
end)

-- zo_tuning:giveItens
-- Gives items to the triggering player.
RegisterNetEvent("zo_tuning:giveItens")
AddEventHandler("zo_tuning:giveItens", function(itens)
    local source = source
    giveItens(source, itens)
end)

-- zo_tuning_suspe
-- Suspension sync: smoothly broadcasts height changes to all clients.
RegisterNetEvent("zo_tuning_suspe")
AddEventHandler("zo_tuning_suspe", function(vehicle, pAlturaAtual, pAlturaAnterior)
    local source = source

    local altura = pAlturaAnterior
    local subir  = pAlturaAtual > pAlturaAnterior

    TriggerClientEvent("zo_tuning:soundSuspensao", source, subir)

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

-- ─── ANIMATION HANDLER ───────────────────────────────────────────────────────

-- Replaces original src.anim which called zof.playAnim/stopAnim/deletarObjeto via vRPclient Tunnel.
-- We now trigger client-side events directly.
RegisterNetEvent("zo_tuning:playAnim")
AddEventHandler("zo_tuning:playAnim", function(anim)
    local source = source
    TriggerClientEvent("zo_tuning:clientPlayAnim", source, anim)

    SetTimeout(anim.time, function()
        TriggerClientEvent("zo_tuning:clientStopAnim", source)
    end)
end)

-- ─── PLAYER LOAD HOOK ────────────────────────────────────────────────────────

-- Replaces original vRP:CharacterChosen hook.
-- Broadcasts the full vehiclesInfoCache to the newly loaded player.
AddEventHandler("esx:playerLoaded", function(source)
    TriggerClientEvent("zo_tuning:updateVehicles", source, vehiclesInfoCache)
end)