-- script/client/client.lua (ESX-Legacy conversion)
-- All vRP Tunnel/Proxy/module calls replaced with ESX callbacks and server events.
-- All original NUI callbacks, camera logic, tuning mechanics, and command preserved 100%.

local math = math

infosVeh = nil
cam = nil
inMoveCam = false

-- Utility: convert hex color string to R, G, B integers
function hexToRGB(hex)
    if type(hex) == "string" then
        hex = hex:gsub("#", "")
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)
        return r, g, b
    end
    return 255, 255, 255
end

-- Utility: round a number to N decimal places
function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Utility: check if a table is empty
function table.empty(self)
    for _, _ in pairs(self) do return false end
    return true
end

-- Close the NUI, restore camera, and save current vehicle state to server
function closeNui()
    if cam then
        RenderScriptCams(0, 0, cam, 0, 0)
        DestroyCam(cam, true)
        cam = nil
    end

    SetFocusEntity(PlayerPedId())
    SetNuiFocus(false, false)

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    if vehicle and vehicle ~= 0 then
        SetVehicleLights(vehicle, 0)
    end

    SendNUIMessage({ type = "closeNui" })
end

-- Set xenon color on vehicle
function setXenonCarColor(vehicle, color)
    if color then
        local r, g, b = hexToRGB(color)
        ToggleVehicleMod(vehicle, 22, true)
        SetVehicleXenonLightsCustomColor(vehicle, r, g, b)
    end
end

-- Toggle all four neon lights
function setNeonCarOnOff(vehicle, toggle)
    for _, l in pairs({ 0, 1, 2, 3 }) do
        SetVehicleNeonLightEnabled(vehicle, l, toggle)
    end
end

-- Set neon color and enable neons
function setNeonCarColor(vehicle, color)
    local r, g, b = hexToRGB(color)
    setNeonCarOnOff(vehicle, true)
    SetVehicleNeonLightsColour(vehicle, r, g, b)
end

-- Apply remap handling floats to a vehicle
function setRemapVehicle(vehicle, remapInfos)
    if not remapInfos then return end
    for i, remap in pairs(remapOptions) do
        if remapInfos[remap.key] then
            SetVehicleHandlingFloat(vehicle, "CHandlingData", remap.field, remapInfos[remap.key].value * 1.0)
        end
    end
end

instalandoModulo = false

-- Return world-coords offset from a vehicle bone
function returnCoordBone(veh, bone, px, py, pz)
    local b = GetEntityBoneIndexByName(veh, bone)
    local bx, by, bz = table.unpack(GetWorldPositionOfEntityBone(veh, b))
    local ox2, oy2, oz2 = table.unpack(GetOffsetFromEntityGivenWorldCoords(veh, bx, by, bz))
    local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(veh, ox2 + f(px), oy2 + f(py), oz2 + f(pz)))
    return x, y, z
end

-- Draw floating 3D text in the world
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.28, 0.28)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.005 + factor, 0.03, 41, 11, 41, 68)
end

-- Find all vehicles within radius
function getNearestVehicles(radius)
    local r = {}
    local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId()))
    local vehs = {}
    local it, veh = FindFirstVehicle()
    if veh then table.insert(vehs, veh) end
    local ok
    repeat
        ok, veh = FindNextVehicle(it)
        if ok and veh then table.insert(vehs, veh) end
    until not ok
    EndFindVehicle(it)
    for _, v in pairs(vehs) do
        local x, y, z = table.unpack(GetEntityCoords(v, true))
        local distance = GetDistanceBetweenCoords(x, y, z, px, py, pz, true)
        if distance <= radius then r[v] = distance end
    end
    return r
end

-- Find the single nearest vehicle within radius
function getNearestVehicle(radius)
    local veh
    local vehs = getNearestVehicles(radius)
    local min = radius + 0.0001
    for _veh, dist in pairs(vehs) do
        if dist < min then
            min = dist
            veh = _veh
        end
    end
    return veh
end

-- Return vehicle info table for the vehicle near or used by the player (called server-side via tunnel in original, here used as helper for NUI open)
function vehListClient(radius)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsUsing(ped)
    if not IsPedInAnyVehicle(ped) then veh = getNearestVehicle(radius) end
    if IsEntityAVehicle(veh) then
        return veh, VehToNet(veh), GetVehicleNumberPlateText(veh), GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    end
end

-- Play a sound for suspension movement (called from server event)
function soundSuspensao(subir)
    local sound = "SUSPENSION_UP"
    if subir then sound = "SUSPENSION_DOWN" end
    if currentVehicle then
        PlaySoundFromEntity(-1, sound, currentVehicle, "ZO_PACK_SOUNDS_CAR", true, 0)
    end
end

RegisterNetEvent("zo_tuning:soundSuspensao")
AddEventHandler("zo_tuning:soundSuspensao", function(subir)
    soundSuspensao(subir)
end)

-- ─── NUI CALLBACKS ───────────────────────────────────────────────────────────

local registerNUICallbacks = {

    ["closeNui"] = function(data, cb)
        closeNui()

        ESX.TriggerServerCallback("zo_tuning:getInfos", function(infos)
            if infos then
                TriggerServerEvent("zo_tuning:setCustom", infosVeh, infos, VehToNet(currentVehicle))
            end
        end, nil)

        cb({})
    end,

    ["removeModulo"] = function(data, cb)
        ESX.TriggerServerCallback("zo_tuning:checkPerms", function(hasPerms)
            if not hasPerms then
                TriggerEvent("Notify", notifysType["erro"], textNotifys[2](), 5000)
                cb({})
                return
            end

            ESX.TriggerServerCallback("zo_tuning:checkItens", function(possuiItens, itens)
                if not possuiItens then
                    TriggerEvent("Notify", notifysType["erro"], textNotifys[1](itens), 5000)
                    cb({})
                    return
                end

                ESX.TriggerServerCallback("zo_tuning:checkVehicleInfos", function(infosVehRemove)
                    local modulo = data.item

                    if not infosVehRemove then cb({}) return end

                    if infosVehRemove[modulo] then
                        infosVehRemove[modulo].instalado = nil

                        ESX.TriggerServerCallback("zo_tuning:getInfos", function(infos)
                            TriggerServerEvent("zo_tuning:setCustom", infosVehRemove, infos, VehToNet(currentVehicle))
                            closeNui()

                            TriggerServerEvent("zo_tuning:giveItens", { { item = configuracaoModulos[modulo].configItem.nameItem, qtd = 1 } })
                            TriggerEvent("Notify", notifysType["sucesso"], textNotifys[8](), 5000)
                        end, nil)
                    end

                    cb({})
                end, nil)
            end, menuTuning.itensObrigatorioRemoverModulo)
        end, menuTuning.permissoesRemoverModulo)
    end,

    ["setValueCamber"] = function(data, cb)
        infosVeh.camber = data.camber
        cb({})
    end,

    ["setValueOffset"] = function(data, cb)
        infosVeh.offset = data.offset
        cb({})
    end,

    ["setValueSuspensao"] = function(data, cb)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(ped)

        infosVeh.suspensao.value = data.suspensao

        local suspensao = round(GetVehicleSuspensionHeight(vehicle), 2)
        TriggerServerEvent("zo_tuning_suspe", VehToNet(vehicle), infosVeh.suspensao.value, suspensao)
        cb({})
    end,

    ["setValueAntiLag"] = function(data, cb)
        infosVeh.antiLag = data.antiLag

        if infosVeh.antiLag.effect then
            antiLag(true)
        end
        cb({})
    end,

    ["setValueWestgate"] = function(data, cb)
        infosVeh.westgate = data.westgate

        if infosVeh.westgate.sound and infosVeh.westgate.active then
            local sound = westGateSounds[infosVeh.westgate.sound]
            local val = math.random(sound.min, sound.max)
            PlaySoundFromEntity(-1, "WEST_GATE_" .. val, currentVehicle, sound.dlc, true, 0)
        end
        cb({})
    end,

    ["setPurgadorValue"] = function(data, cb)
        infosVeh.purgador.value = data.purgador
        infosVeh.purgador.active = true

        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(ped)
        SetVehicleNitroPurgeEnabled(vehicle, data.purgador)
        cb({})
    end,

    ["disablePurgador"] = function(data, cb)
        infosVeh.purgador.active = data.active

        if data.active then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsUsing(ped)
            SetVehicleNitroPurgeEnabled(vehicle, infosVeh.purgador.value)
        end
        cb({})
    end,

    ["disableNeon"] = function(data, cb)
        if not data.active then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsUsing(ped)
            setNeonCarOnOff(vehicle, false)
        end
        infosVeh.neon.power = data.active
        cb({})
    end,

    ["setValueNeon"] = function(data, cb)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(ped)

        infosVeh.neon.power = true
        infosVeh.neon.color = data.color

        setNeonCarColor(vehicle, data.color)
        cb({})
    end,

    ["disableXenon"] = function(data, cb)
        if not data.active then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsUsing(ped)
            ToggleVehicleMod(vehicle, 22, false)
        end
        infosVeh.xenon.power = data.active
        cb({})
    end,

    ["setValueXenon"] = function(data, cb)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(ped)

        infosVeh.xenon.power = true
        infosVeh.xenon.color = data.color

        setXenonCarColor(vehicle, data.color)
        cb({})
    end,

    ["setRemapValue"] = function(data, cb)
        local item = data.item

        infosVeh.remap[item.key] = {
            value = item.value,
            max   = item.max,
            min   = item.min,
        }

        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(ped)
        if vehicle and vehicle ~= 0 then
            setRemapVehicle(vehicle, infosVeh.remap)
        end
        cb({})
    end,

    ["destroyCam"] = function(data, cb)
        if cam then
            RenderScriptCams(0, 0, cam, 0, 0)
            DestroyCam(cam, true)
            cam = nil
        end
        SetFocusEntity(PlayerPedId())
        cb({})
    end,

    ["moveCam"] = function(data, cb)
        inMoveCam = data.move

        if inMoveCam then
            Citizen.CreateThread(function()
                SetNuiFocus(false, true)

                while inMoveCam do
                    Citizen.Wait(0)

                    BlockWeaponWheelThisFrame()
                    DisableControlAction(0, 261, true)
                    DisableControlAction(0, 262, true)
                    DisableInputGroup(24)

                    local alterPosition = false

                    if IsControlPressed(1, 172) then positionCam.cds[1] = (positionCam.cds[1] or 0) + 0.01; alterPosition = true end
                    if IsControlPressed(1, 173) then positionCam.cds[1] = (positionCam.cds[1] or 0) - 0.01; alterPosition = true end
                    if IsControlPressed(1, 308) then positionCam.cds[2] = (positionCam.cds[2] or 0) + 0.01; alterPosition = true end
                    if IsControlPressed(1, 307) then positionCam.cds[2] = (positionCam.cds[2] or 0) - 0.01; alterPosition = true end
                    if IsControlPressed(1, 172) and IsControlPressed(1, 21) then positionCam.cds[3] = (positionCam.cds[3] or 0) + 0.01; alterPosition = true end
                    if IsControlPressed(1, 173) and IsControlPressed(1, 21) then positionCam.cds[3] = (positionCam.cds[3] or 0) - 0.01; alterPosition = true end

                    if IsControlPressed(1, 38) or IsControlPressed(1, 200) then
                        inMoveCam = false
                        SetNuiFocus(true, true)
                        cb(true)
                    end

                    if alterPosition then
                        if positionCam.pos then
                            MoveVehCam(positionCam.pos, positionCam.cds[1], positionCam.cds[2], positionCam.cds[3])
                        end
                        if positionCam.bone then
                            PointCamAtBone(positionCam.bone, positionCam.cds[1], positionCam.cds[2], positionCam.cds[3])
                        end
                        alterPosition = false
                    end
                end
            end)
        end
    end,

    ["setCam"] = function(data, cb)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(ped)

        if cam == nil then
            cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        end

        if data.tipo == "home" then
            MoveVehCam("front-top", 0, 2.0, 0.5)
        end

        if data.tipo == "wheel" then
            if data.eixo == "frontal" then
                PointCamAtBone("wheel_lf", -1.4, 0.0, 0.3)
            elseif data.eixo == "traseiro" then
                PointCamAtBone("wheel_lr", -1.4, -1.0, 0.3)
            else
                MoveVehCam("left", -5, 0.0, 0.5)
            end
        end

        if data.tipo == "suspe" then
            MoveVehCam("left", -5, 0.0, 0.5)
        end

        if data.tipo == "xenon" then
            MoveVehCam("front", 0, 2.0, 0.5)
            SetVehicleLights(vehicle, 2)
        end

        if data.tipo == "purgador" then
            MoveVehCam("front", 0, 2.0, 1.0)
        end

        if data.tipo == "exahust" then
            MoveVehCam("back", 1.5, -3.0, 1.0)
        end

        if data.tipo == "neon" then
            MoveVehCam("left", -1.5, 3.5, 1.0)
        end

        cb({})
    end,
}

-- ─── REGISTER NUI CALLBACKS ──────────────────────────────────────────────────

Citizen.CreateThread(function()
    closeNui()

    for i, fn in pairs(registerNUICallbacks) do
        RegisterNUICallback(i, function(data, cb)
            fn(data, cb)
        end)
    end

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    if vehicle and vehicle ~= 0 then
        Citizen.Wait(1000)
        loopWhileInVehicle()
    end
end)

-- ─── SHARED OPEN MENU LOGIC ──────────────────────────────────────────────────

local function openTuningMenu()
    ESX.TriggerServerCallback("zo_tuning:checkPerms", function(hasPerms)
        if not hasPerms then
            TriggerEvent("Notify", notifysType["erro"], textNotifys[2](), 5000)
            return
        end

        ESX.TriggerServerCallback("zo_tuning:checkItens", function(possuiItens, itens)
            if not possuiItens then
                TriggerEvent("Notify", notifysType["erro"], textNotifys[1](itens), 5000)
                return
            end

            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsUsing(ped)

            if vehicle ~= 0 and vehicle ~= nil then
                ESX.TriggerServerCallback("zo_tuning:checkVehicleInfos", function(result)
                    infosVeh = result
                    if not infosVeh then
                        TriggerEvent("Notify", notifysType["erro"], textNotifys[3](), 5000)
                        return
                    end

                    if not infosVeh.suspensao.value then
                        infosVeh.suspensao.value = round(GetVehicleSuspensionHeight(vehicle), 2)
                    end

                    if not infosVeh.offset.defaultCar then
                        infosVeh.offset.defaultCar = GetVehicleWheelXOffset(vehicle)
                    end

                    for i, v in pairs(remapOptions) do
                        if infosVeh.remap and infosVeh.remap[v.key] then
                            remapOptions[i].value = infosVeh.remap[v.key].value
                            remapOptions[i].max   = infosVeh.remap[v.key].max
                            remapOptions[i].min   = infosVeh.remap[v.key].min
                        end

                        if not remapOptions[i].max or not remapOptions[i].min then
                            if vehicle and vehicle ~= 0 then
                                local valueVehicle = GetVehicleHandlingFloat(vehicle, "CHandlingData", v.field)
                                remapOptions[i].value = round(valueVehicle, 2)
                                remapOptions[i].max   = round(valueVehicle + remapOptions[i].var, 2)
                                remapOptions[i].min   = round(valueVehicle - remapOptions[i].var, 2)
                            end
                        end
                    end

                    local permsMenu = {}
                    local exibirInstalados = false
                    local itensInstalados = {}

                    for i, v in pairs(configuracaoModulos) do
                        local itemInstalado = true

                        if v.configItem.obrigatorioItemInstaladoParaAcessar then
                            exibirInstalados = true

                            if infosVeh[i] then
                                itemInstalado = infosVeh[i].instalado ~= nil
                            end

                            if itemInstalado then
                                table.insert(itensInstalados, { key = i, nome = v.nome, img = v.img })
                            else
                                permsMenu[i] = { key = i, block = true }
                            end
                        end

                        if table.empty(v.permsAcessarMenu) and not permsMenu[i] then
                            permsMenu[i] = { key = i, block = false }
                        else
                            if permsMenu[i] then
                                if permsMenu[i].block then goto continue end
                            end

                            ESX.TriggerServerCallback("zo_tuning:checkPerms", function(menuPerm)
                                permsMenu[i] = { key = i, block = not menuPerm }
                            end, v.permsAcessarMenu)
                        end

                        permsMenu[i].img       = v.img
                        permsMenu[i].desabilitar = v.desabilitar

                        ::continue::
                    end

                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        type = "openNuiCars",
                        data = {
                            infosVeh        = infosVeh,
                            remapConfig     = remapOptions,
                            permsMenu       = permsMenu,
                            exibirInstalados = exibirInstalados,
                            modulosInstalados = itensInstalados,
                            configValues    = {
                                antiLagEffects = antiLagEffectsDict,
                                antiLagSounds  = antiLagSounds,
                                westgateSounds = westGateSounds,
                            },
                        },
                    })
                end, nil)
            else
                TriggerEvent("Notify", notifysType["erro"], textNotifys[6](), 5000)
            end
        end, menuTuning.itensObrigatorioAcessar)
    end, menuTuning.permissoesAcessarMenu)
end

-- ─── COMMAND TO OPEN MENU ────────────────────────────────────────────────────

RegisterCommand(menuTuning.comando, function()
    openTuningMenu()
end)

-- ─── PROXIMITY MARKER & INTERACTION LOOP ────────────────────────────────────

Citizen.CreateThread(function()
    local tunning_coords = {
        vec3(48.42, -1104.16, 28.23),
    }

    while true do
        local SLEEP_TIME = 1000
        local playercoords = GetEntityCoords(PlayerPedId())

        for _, v in pairs(tunning_coords) do
            local distance = #(playercoords - v)
            if distance < 10 then
                SLEEP_TIME = 0
                DrawMarker(27, v.x, v.y, v.z - 0.97, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 1.0, 255, 102, 0, 200, 0, 0, 0, 1)

                if IsControlJustPressed(0, 38) then
                    openTuningMenu()
                end
            end
        end

        Wait(SLEEP_TIME)
    end
end)

-- ─── VEHICLE ENTER LISTENER ──────────────────────────────────────────────────

AddEventHandler("gameEventTriggered", function(event, args)
    if event == "CEventNetworkPlayerEnteredVehicle" then
        loopWhileInVehicle()
    end
end)

-- ─── SUSPENSION SYNC ─────────────────────────────────────────────────────────

RegisterNetEvent("synczosuspe_tuning")
AddEventHandler("synczosuspe_tuning", function(vehicle, altura)
    if NetworkDoesNetworkIdExist(vehicle) then
        local v = NetToVeh(vehicle)
        SetVehicleSuspensionHeight(v, f(altura))
    end
end)

RegisterNetEvent("zo_tuning:clientPlayAnim")
AddEventHandler("zo_tuning:clientPlayAnim", function(anim)
    zof.playAnim(anim)
end)

RegisterNetEvent("zo_tuning:clientStopAnim")
AddEventHandler("zo_tuning:clientStopAnim", function()
    zof.deletarObjeto()
    zof.stopAnim(false)
end)

-- Client-side vehicle data responder for server callbacks
RegisterNetEvent("zo_tuning:requestVehData")
AddEventHandler("zo_tuning:requestVehData", function()
    local ped    = PlayerPedId()
    local veh    = GetVehiclePedIsUsing(ped)
    if not veh or veh == 0 then veh = getNearestVehicle(3) end

    if veh and IsEntityAVehicle(veh) then
        TriggerServerEvent("zo_tuning:vehDataResponse", {
            plate  = GetVehicleNumberPlateText(veh),
            vname  = GetDisplayNameFromVehicleModel(GetEntityModel(veh)):lower(),
            vnetid = VehToNet(veh),
        })
    else
        TriggerServerEvent("zo_tuning:vehDataResponse", nil)
    end
end)