ESX = exports['es_extended']:getSharedObject()
local ox_lib = exports.ox_lib

local infosVeh = nil
local inMoveCam = false
local cam = nil
local currentVehicle = nil

local function close()
    RenderScriptCams(0, 0, cam, 0, 0)
    DestroyCam(cam, true)
    SetFocusEntity(PlayerPedId())
    cam = nil
    SetNuiFocus(false, false)
    
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    if vehicle ~= 0 then
        SetVehicleLights(vehicle, 0)
    end
    SendNUIMessage({ type = 'closeNui' })
end

local function hexToRGB(hex)
    if type(hex) == "string" then
        hex = hex:gsub("#","")
        return tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
    end
    return 255, 255, 255
end

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

RegisterNUICallback("closeNui", function(data, cb)
    close()
    ESX.TriggerServerCallback('tuning:getInfos', function(infos)
        if infos then
            TriggerServerEvent('tuning:setCustom', infosVeh, infos, VehToNet(currentVehicle))
        end
    end)
    cb('ok')
end)

RegisterNUICallback("removeModulo", function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    local modulo = data.item

    ESX.TriggerServerCallback('tuning:checkPerms', function(hasPerm)
        if not hasPerm then
            lib.notify({ title = 'Erro', description = 'Sem permissão', type = 'error' })
            return
        end
        
        ESX.TriggerServerCallback('tuning:checkItens', function(possui, missing)
            if not possui then
                lib.notify({ title = 'Erro', description = 'Faltando itens: ' .. (missing or ''), type = 'error' })
                return
            end

            ESX.TriggerServerCallback('tuning:getVehicleInfos', function(infosVehRemove)
                if infosVehRemove and infosVehRemove[modulo] then
                    infosVehRemove[modulo].instalado = nil
                    ESX.TriggerServerCallback('tuning:getInfos', function(infos)
                        TriggerServerEvent('tuning:setCustom', infosVehRemove, infos, VehToNet(vehicle))
                        close()
                        TriggerServerEvent('tuning:giveItem', configuracaoModulos[modulo].configItem.nameItem, 1)
                        lib.notify({ title = 'Sucesso', description = 'Módulo removido', type = 'success' })
                    end)
                end
            end)
        end, menuTuning.itensObrigatorioRemoverModulo)
    end, menuTuning.permissoesRemoverModulo)
    cb('ok')
end)

RegisterNUICallback("setValueSuspensao", function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    infosVeh.suspensao.value = data.suspensao
    local currentH = round(GetVehicleSuspensionHeight(vehicle), 2)
    TriggerServerEvent("zo_tuning_suspe", VehToNet(vehicle), infosVeh.suspensao.value, currentH)
    cb('ok')
end)

RegisterCommand(menuTuning.comando, function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    if vehicle == 0 then
        lib.notify({ description = 'Você precisa estar em um veículo', type = 'error' })
        return
    end

    ESX.TriggerServerCallback('tuning:checkAccess', function(canAccess)
        if not canAccess then return end
        
        ESX.TriggerServerCallback('tuning:getVehicleInfos', function(dataInfos)
            if not dataInfos then return end
            infosVeh = dataInfos
            currentVehicle = vehicle
            
            if not infosVeh.suspensao.value then
                infosVeh.suspensao.value = round(GetVehicleSuspensionHeight(vehicle), 2)
            end

            SetNuiFocus(true, true)
            SendNUIMessage({
                type = 'openNuiCars',
                data = {
                    infosVeh = infosVeh,
                    remapConfig = remapOptions,
                    configValues = {
                        antiLagEffects = antiLagEffectsDict,
                        antiLagSounds = antiLagSounds,
                        westgateSounds = westGateSounds
                    }
                }
            })
        end)
    end)
end)

Citizen.CreateThread(function() 
    for _, v in pairs(menuTuning.coords or {}) do
        ox_lib.addMarker({
            coords = v,
            type = 27,
            color = { r = 255, g = 102, b = 0, a = 200 }
        })
    end
end)