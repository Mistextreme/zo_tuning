local ESX = exports['es_extended']:getSharedObject()
local vehiclesInfoCache = {}
local lastEffectTime = 0
local lastCurrentGear = 0
local waitPurge = 0
local currentVehicle = nil
local infosVeh = nil
local instalandoModulo = false

function loopWhileInVehicle()
    local ped = cache.ped
    local vehicle = cache.vehicle
    if not vehicle then return end

    lib.callback('zo_tuning:checkVehicleInfos', false, function(data)
        infosVeh = data
        if infosVeh then
            if infosVeh.neon.power then setNeonCarColor(vehicle, infosVeh.neon.color) end
            if infosVeh.xenon.power then setXenonCarColor(vehicle, infosVeh.xenon.color) end
            setRemapVehicle(vehicle, infosVeh.remap)
            if infosVeh.suspensao.value ~= 0 then
                local val = math.clamp(infosVeh.suspensao.value, infosVeh.suspensao.max, infosVeh.suspensao.min)
                SetVehicleSuspensionHeight(vehicle, val + 0.0)
            end
        end
    end)

    while cache.seat == -1 do
        if currentVehicle ~= vehicle then
            currentVehicle = vehicle
            lib.callback('zo_tuning:checkVehicleInfos', false, function(data) infosVeh = data end)
        end

        if infosVeh then
            if not infosVeh.offset.defaultCar then infosVeh.offset.defaultCar = GetVehicleWheelXOffset(vehicle) end
            if infosVeh.antiLag.active ~= 0 or infosVeh.westgate.active ~= 0 then checkAntiLagAndWestgate() end
            if IsControlJustPressed(1, 73) and infosVeh.purgador.active and waitPurge < 1 then
                SetVehicleNitroPurgeEnabled(vehicle, (infosVeh.purgador.value or 1))
            end
            setCamberAndOffSet(vehicle, infosVeh)
        end

        if waitPurge > 0 then waitPurge = waitPurge - 5 end
        Wait(5)
    end

    infosVeh = nil
    currentVehicle = nil
end

function applyChangesVehicle(vehicle, infos)
    if currentVehicle and VehToNet(currentVehicle) == VehToNet(vehicle) then return end
    setCamberAndOffSet(vehicle, infos)
    if infos.suspensao.value ~= 0 then
        local val = math.clamp(infos.suspensao.value, infos.suspensao.max, infos.suspensao.min)
        SetVehicleSuspensionHeight(vehicle, val + 0.0)
    end
end

function setCamberAndOffSet(vehicle, infos)
    local function checkZeroOrNull(value) return value == 0 or value == nil end
    local setOffSet = true
    if checkZeroOrNull(infos.offset.defaultCar) then infos.offset.defaultCar = GetVehicleWheelXOffset(vehicle) end
    if checkZeroOrNull(infos.camber.frontal) then infos.camber.frontal = infos.camber.ambos end
    if checkZeroOrNull(infos.camber.traseiro) then infos.camber.traseiro = infos.camber.ambos end
    if checkZeroOrNull(infos.offset.frontal) then infos.offset.frontal = infos.offset.ambos end
    if checkZeroOrNull(infos.offset.traseiro) then infos.offset.traseiro = infos.offset.ambos end
    if checkZeroOrNull(infos.offset.ambos) and checkZeroOrNull(infos.offset.frontal) and checkZeroOrNull(infos.offset.traseiro) then setOffSet = false end

    for x = 0, 3 do
        local valCamb = (x <= 1) and (infos.camber.frontal / 100) or (infos.camber.traseiro / 100)
        local valOff = (x <= 1) and (infos.offset.defaultCar - (infos.offset.frontal / 100)) or (infos.offset.defaultCar - (infos.offset.traseiro / 100))
        if x % 2 ~= 0 then valCamb, valOff = valCamb * -1, valOff * -1 end
        if valCamb ~= 0 then SetVehicleWheelYRotation(vehicle, x, valCamb) end
        if setOffSet then SetVehicleWheelXOffset(vehicle, x, valOff) end
    end
end

function checkAntiLagAndWestgate()
    local rpm = GetVehicleCurrentRpm(currentVehicle)
    if math.abs(GetVehicleThrottleOffset(currentVehicle)) < 0.1 and rpm > 0.65 then
        local gameTime = GetGameTimer()
        if gameTime > (lastEffectTime + (config.antiLag.periodMs or 500)) then
            local loud = false
            local currentGear = GetVehicleCurrentGear(currentVehicle)
            if lastCurrentGear ~= currentGear then
                lastCurrentGear = currentGear
                loud = true
            end
            antiLag(loud, rpm)
            lastEffectTime = gameTime
        end
    end
end

RegisterNetEvent("zo_sync_tuning", function(vnet)
    if NetworkDoesEntityExistWithNetworkId(vnet) then
        local vehicle = NetToVeh(vnet)
        if DoesEntityExist(vehicle) then
            lib.callback('zo_tuning:checkVehicleInfos', false, function(infosVehSync)
                setRemapVehicle(vehicle, infosVehSync.remap)
                applyChangesVehicle(vehicle, infosVehSync)
            end, { vnet = vnet, vname = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower() })
        end
    end
end)

RegisterNetEvent('zo_tuning:updateVehicles', function(data)
    vehiclesInfoCache = data
end)

CreateThread(function()
    while true do
        local vehiclePool = GetGamePool('CVehicle')
        for i = 1, #vehiclePool do
            local veh = vehiclePool[i]
            if NetworkGetEntityIsNetworked(veh) then
                local netKey = tostring(VehToNet(veh)) .. GetVehicleNumberPlateText(veh)
                if vehiclesInfoCache[netKey] then
                    applyChangesVehicle(veh, vehiclesInfoCache[netKey])
                end
            end
        end
        Wait(1000)
    end
end)

RegisterNetEvent("zo_install_modulo_tuning", function(modulo)
    if instalandoModulo then return lib.notify({title = 'Tuning', description = 'Instalação em andamento', type = 'error'}) end
    
    local vehicleInstall = lib.getClosestVehicle(cache.coords, 5.0, false)
    if not vehicleInstall then return end

    lib.callback('zo_tuning:checkInstallRequirements', false, function(canInstall, reason)
        if not canInstall then return lib.notify({title = 'Erro', description = reason or 'Sem permissão ou itens', type = 'error'}) end
        
        instalandoModulo = true
        if lib.progressBar({ duration = 5000, label = 'Instalando '..modulo, useWhileDead = false, canCancel = true, anim = { dict = 'mini@repair', clip = 'fixing_a_ped' }}) then
            TriggerServerEvent('zo_tuning:completeInstall', modulo, VehToNet(vehicleInstall))
            lib.notify({title = 'Sucesso', description = 'Módulo instalado!', type = 'success'})
        end
        instalandoModulo = false
    end, modulo)
end)