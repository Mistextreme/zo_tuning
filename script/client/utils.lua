local ESX = exports['es_extended']:getSharedObject()

cam = nil
positionCam = nil

function f(n)
	return (n + 0.00000001)
end

function PointCamAtBone(bone, ox, oy, oz)
    if not IsCamActive(cam) then
        SetCamActive(cam, true)
    end

    local veh = currentVehicle
    positionCam = { bone = bone, cds = { ox, oy, oz } }
    
    local b = GetEntityBoneIndexByName(veh, bone)
    local bx, by, bz = table.unpack(GetWorldPositionOfEntityBone(veh, b))
    local ox2, oy2, oz2 = table.unpack(GetOffsetFromEntityGivenWorldCoords(veh, bx, by, bz))
    local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(veh, ox2 + f(ox), oy2 + f(oy), oz2 + f(oz)))

    SetCamCoord(cam, x, y, z)
    PointCamAtCoord(cam, GetOffsetFromEntityInWorldCoords(veh, 0, oy2, oz2))

    RenderScriptCams(true, true, 1000, false, false)
end

function MoveVehCam(pos, x, y, z)
    if not IsCamActive(cam) then
        SetCamActive(cam, true)
    end

    positionCam = { pos = pos, cds = { x, y, z } }
    local veh = currentVehicle
	local d = GetModelDimensions(GetEntityModel(veh))
	local length, width, height = d.y * -2, d.x * -2, d.z * -2
	local ox, oy, oz

	if pos == 'front' then
		ox, oy, oz = table.unpack(GetOffsetFromEntityInWorldCoords(veh, f(x), (length / 2) + f(y), f(z)))
	elseif pos == "front-top" then
		ox, oy, oz = table.unpack(GetOffsetFromEntityInWorldCoords(veh, f(x), (length / 2) + f(y), (height) + f(z)))
	elseif pos == "back" then
		ox, oy, oz = table.unpack(GetOffsetFromEntityInWorldCoords(veh, f(x), -(length/2) + f(y), f(z)))
	elseif pos == "back-top" then
		ox, oy, oz = table.unpack(GetOffsetFromEntityInWorldCoords(veh, f(x), -(length/2) + f(y), (height / 2) + f(z)))
	elseif pos == "left" then
		ox, oy, oz = table.unpack(GetOffsetFromEntityInWorldCoords(veh, -(width / 2) + f(x), f(y), f(z)))
	elseif pos == "right" then
		ox, oy, oz = table.unpack(GetOffsetFromEntityInWorldCoords(veh, (width / 2) + f(x), f(y), f(z)))
	elseif pos == "middle" then
		ox, oy, oz = table.unpack(GetOffsetFromEntityInWorldCoords(veh, f(x), f(y), (height / 2) + f(z)))
	end

	SetCamCoord(cam, ox, oy, oz)
    PointCamAtCoord(cam, GetOffsetFromEntityInWorldCoords(veh, 0, 0, f(0)))
    RenderScriptCams(true, true, 1000, false, false)
end

function animationInstall(vehicle, part)
    local ped = PlayerPedId()
    local vehiclePos = GetEntityCoords(vehicle)
    
    if part.insideCar then
        local vehicleInside = GetVehiclePedIsUsing(ped)
        if vehicleInside == vehicle and GetPedInVehicleSeat(vehicleInside, -1) == ped then
            if lib.progressBar({
                duration = part.anim.time,
                label = 'Instalando Módulo...',
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true },
                anim = { dict = part.anim.dict, clip = part.anim.name }
            }) then
                part.installAplly()
                lib.notify({ title = 'Sucesso', description = 'Instalação concluída!', type = 'success' })
            end
        else
            lib.notify({ title = 'Erro', description = 'Você deve estar no banco do motorista!', type = 'error' })
        end
    else
        for i, blip in ipairs(part.blips) do
            local point = lib.points.new({
                coords = vector3(blip[1], blip[2], blip[3]),
                distance = 2
            })

            function point:nearby()
                DrawMarker(1, self.coords.x, self.coords.y, self.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 0, 255, 0, 150, false, false, 2, false, nil, nil, false)
                if self.currentDistance < 1.5 and IsControlJustReleased(0, 38) then
                    if blip.prepareInstall then blip.prepareInstall() end
                    if lib.progressBar({
                        duration = part.anim.time,
                        label = 'Instalando parte...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { car = true, move = true },
                        anim = { dict = part.anim.dict, clip = part.anim.name }
                    }) then
                        part.installAplly()
                    end
                end
            end
        end
    end
end