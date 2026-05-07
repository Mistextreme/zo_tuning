local ESX = exports['es_extended']:getSharedObject()
local currentVehicle = nil
local lastEffectTime = 0
local lastCurrentGear = 0
local waitPurge = 0

local exhaustBones = {
    "exhaust", "exhaust_2", "exhaust_3", "exhaust_4", "exhaust_5", "exhaust_6", "exhaust_7", "exhaust_8",
    "exhaust_9", "exhaust_10", "exhaust_11", "exhaust_12", "exhaust_13", "exhaust_14", "exhaust_15", "exhaust_16"
}

local config = {
    antiLag = {
        minRPM = 0.65,
        periodMs = 350,
        randomMs = 350,
        loudOffThrottle = true,
        loudOffThrottleIntervalMs = 1500
    }
}

RequestScriptAudioBank("dlc_zosounds/zosounds", 0)

local function RequestAsset(name)
    RequestNamedPtfxAsset(name)
    while not HasNamedPtfxAssetLoaded(name) do
        Wait(1)
    end
end

local antiLagEffectsExecs = {
    ["defaultBackfire"] = function(infos)
        RequestAsset("core")
        UseParticleFxAsset("core")
        StartNetworkedParticleFxNonLoopedOnEntity("veh_backfire", infos.veh, infos.boneOff, infos.boneRot, infos.explSz, false, false, false)
    end,

    ["redBackfire"] = function(infos)
        local particleAsset = "veh_sanctus"
        local particleName = "veh_sanctus_backfire"
        RequestAsset(particleAsset)
        UseParticleFxAssetNextCall(particleAsset)
        StartNetworkedParticleFxNonLoopedOnEntity(particleName, infos.veh, infos.boneOff, infos.boneRot, infos.explSz, false, false, false)
    end,

    ["blueNitrousBackfire"] = function(infos)
        RequestAsset("veh_xs_vehicle_mods")
        UseParticleFxAsset("veh_xs_vehicle_mods")
        Citizen.InvokeNative(0xC8E9B6B71B8E660D, infos.veh, true, 1.0, 1.1, 4.0, true)
        local waitFlame = infos.loud and 200 or 100
        Wait(waitFlame)
        Citizen.InvokeNative(0xC8E9B6B71B8E660D, infos.veh, false, 0.0, 0.0, 0.0, true)
    end
}

local antiLagSounds = {
    ["pipoco1"] = { name = "POPS_SOUND_", min = 1, max = 9, dlc = "ZO_PACK_SOUNDS_CAR" },
    ["pipoco2"] = { name = "POPS_SOUND_", min = 10, max = 21, dlc = "ZO_PACK_SOUNDS_CAR" },
    ["pipoco3"] = { name = "POPS_SOUND_", min = 22, max = 33, dlc = "ZO_PACK_SOUNDS_CAR" },
    ["pipoco4"] = { name = "POPS_SOUND_", min = 34, max = 43, dlc = "ZO_PACK_SOUNDS_CAR" },
    ["pipoco5"] = { name = "POPS_SOUND_", min = 44, max = 55, dlc = "ZO_PACK_SOUNDS_CAR" },
}

local westGateSounds = {
    ["west1"] = { name = "WEST_GATE_", min = 1, max = 1, dlc = "ZO_PACK_SOUNDS_CAR" },
    ["west2"] = { name = "WEST_GATE_", min = 2, max = 2, dlc = "ZO_PACK_SOUNDS_CAR" },
    ["west3"] = { name = "WEST_GATE_", min = 3, max = 3, dlc = "ZO_PACK_SOUNDS_CAR" },
    ["west4"] = { name = "WEST_GATE_", min = 4, max = 4, dlc = "ZO_PACK_SOUNDS_CAR" },
    ["west5"] = { name = "WEST_GATE_", min = 5, max = 5, dlc = "ZO_PACK_SOUNDS_CAR" },
    ["west6"] = { name = "WEST_GATE_", min = 6, max = 6, dlc = "ZO_PACK_SOUNDS_CAR" },
}

function mathClamp(num, min, max)
    return math.max(min, math.min(max, num))
end

function mathMap(x, in_min, in_max, out_min, out_max)
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function TriggerAntiLag(loud, rpm)
    if not currentVehicle or not Entity(currentVehicle).state.antiLagActive then return end
    
    local state = Entity(currentVehicle).state
    
    if loud and state.westgateSound then
        local sound = westGateSounds[state.westgateSound]
        if sound then
            local val = math.random(sound.min, sound.max)
            PlaySoundFromEntity(-1, sound.name .. val, currentVehicle, sound.dlc, true, 0)
        end
    end

    if state.antiLagSound then
        local sound = antiLagSounds[state.antiLagSound]
        if sound then
            local val = math.random(sound.min, sound.max)
            PlaySoundFromEntity(-1, sound.name .. val, currentVehicle, sound.dlc, true, 0)
        end
    end

    for _, bone in ipairs(exhaustBones) do
        local boneIdx = GetEntityBoneIndexByName(currentVehicle, bone)
        if boneIdx ~= -1 then
            local bonePos = GetWorldPositionOfEntityBone(currentVehicle, boneIdx)
            local boneRot = GetEntityBoneRotationLocal(currentVehicle, boneIdx)
            local boneOff = GetOffsetFromEntityGivenWorldCoords(currentVehicle, bonePos)
            local explSz = loud and 1.0 or mathClamp(mathMap(rpm, 0.2, 0.5, 0.75, 1.25), 0.75, 1.25)

            if state.antiLagEffect and antiLagEffectsExecs[state.antiLagEffect] then
                antiLagEffectsExecs[state.antiLagEffect]({
                    loud = loud,
                    veh = currentVehicle,
                    boneOff = boneOff,
                    boneRot = boneRot,
                    explSz = explSz
                })
            end
        end
    end
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            currentVehicle = GetVehiclePedIsIn(ped, false)
            local rpm = GetVehicleCurrentRpm(currentVehicle)
            local gear = GetVehicleCurrentGear(currentVehicle)
            
            if rpm > config.antiLag.minRPM and IsControlJustReleased(0, 71) then
                TriggerAntiLag(true, rpm)
            end
        else
            currentVehicle = nil
            Wait(1000)
        end
        Wait(0)
    end
end)
