-- cfg/functions_client.lua
-- Client-side helper wrappers (ESX-Legacy conversion)
-- Replaces the client-relevant portions of the original cfg/functions.lua

zof = zof or {}

-- Play an animation on the local ped.
-- anim table formats supported (same as original):
--   { name = "dict", extra = "clip" }            → plays as a task
--   { upper = bool, sequency = {{"dict","clip"}}, loop = bool }
zof.playAnim = function(anim)
    local ped = PlayerPedId()

    if anim.name and anim.extra then
        RequestAnimDict(anim.name)
        while not HasAnimDictLoaded(anim.name) do
            Citizen.Wait(1)
        end
        TaskPlayAnim(ped, anim.name, anim.extra, 8.0, -8.0, -1, 49, 0, false, false, false)
        return
    end

    if anim.upper and anim.sequency then
        for _, seq in ipairs(anim.sequency) do
            local dict, clip = seq[1], seq[2]
            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Citizen.Wait(1)
            end
            TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, anim.loop and 1 or 0, 0, false, false, false)
        end
    end
end

-- Stop the local ped animation.
zof.stopAnim = function(upper)
    local ped = PlayerPedId()
    if upper then
        StopAnimTask(ped, "", "", 1.0)
    else
        ClearPedTasks(ped)
    end
end

-- Delete the nearest prop/object that was attached/created for install animations.
-- Uses native DetachAndDeleteObject pattern since vRPclient helpers are gone.
zof.deletarObjeto = function()
    local ped = PlayerPedId()
    -- Clear any task that was playing with a prop; the prop handle is managed
    -- inside createObjects below via the module-level _lastCreatedObject variable.
    if _lastCreatedObject and DoesEntityExist(_lastCreatedObject) then
        DetachEntity(_lastCreatedObject, true, true)
        DeleteEntity(_lastCreatedObject)
        _lastCreatedObject = nil
    end
    ClearPedTasks(ped)
end

-- Module-level storage for the last created prop so deletarObjeto can clean it up.
_lastCreatedObject = nil

-- Create and attach a prop to the local ped, replicating the original vRPclient.createObjects signature:
--   dict  : animation dictionary (used to load the anim)
--   anim  : animation clip name
--   prop  : prop model name
--   flag  : TaskPlayAnim flag
--   hands : bone index (0 = right hand, 1 = left hand)
--   height: vertical offset on bone
--   pos1-5: extra offsets (matching original signature; pos1-pos3 = xyz offset, pos4-pos5 = rot offset)
zof.createObjects = function(dict, anim, prop, flag, hands, height, pos1, pos2, pos3, pos4, pos5)
    local ped = PlayerPedId()

    -- Load the prop model
    local model = GetHashKey(prop)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(1)
    end

    -- Load the anim dict
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(1)
    end

    -- Play the anim on the ped
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, flag or 49, 0, false, false, false)

    -- Create the prop at ped position and attach to hand bone
    local coords = GetEntityCoords(ped)
    local obj = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)

    -- Bone: 28422 = right hand, 18905 = left hand (standard GTA V ped bones)
    local boneIndex = (hands == 1) and 18905 or 28422

    AttachEntityToEntity(
        obj, ped,
        GetPedBoneIndex(ped, boneIndex),
        pos1 or 0.0, pos2 or 0.0, (pos3 or 0.0) + (height or 0.0),
        pos4 or 0.0, pos5 or 0.0, 0.0,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(model)
    _lastCreatedObject = obj
    return obj
end