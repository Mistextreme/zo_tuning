local ESX = exports['es_extended']:getSharedObject()

CreateThread(function()
    Wait(5000)

    while true do
        local vehiclesInfoCache = GlobalState.vehiclesInfoCache or {}
        local vehiclesExists = {}
        local updated = false

        for plate, data in pairs(vehiclesInfoCache) do
            if data.vnetid then
                local entity = NetworkGetEntityFromNetworkId(tonumber(data.vnetid))
                if entity and entity ~= 0 then
                    vehiclesExists[plate] = data
                else
                    updated = true
                end
            end
        end

        if updated then
            GlobalState.vehiclesInfoCache = vehiclesExists
        end

        Wait(3 * 60000)
    end
end)