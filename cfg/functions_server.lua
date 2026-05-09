-- cfg/functions_server.lua
-- Server-side helper wrappers (ESX-Legacy conversion)
-- Replaces the server-relevant portions of the original cfg/functions.lua
-- All original zof.* signatures are preserved so server.lua requires no signature changes.

zof = zof or {}

-- Return the server source (numeric player id) for a given ESX identifier (user_id).
-- Original: vRP.Source(parseInt(user_id))
zof.getUserSource = function(identifier)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if xPlayer then
        return xPlayer.source
    end
    return nil
end

-- Return the ESX identifier (string) for a given server source.
-- Original: vRP.Passport(source)
zof.getUserId = function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.getIdentifier()
    end
    return nil
end

-- Return a display name for an item. ESX does not require a lookup table for this;
-- we return the item name directly (same behaviour as the original vRP stub).
-- Original: vRP.itemNameList(item) -- described as "doesn't have itemNameList, using item name directly"
zof.itemNameList = function(item)
    return item
end

-- Check whether a player (by ESX identifier) has a given permission/group.
-- Original: vRP.HasPermission(user_id, perm, 1)
-- ESX-Legacy maps permissions to job names and ace groups.
-- We check xPlayer.getGroup() for ace-group style perms AND xPlayer.job.name for job-based perms.
zof.hasPermission = function(identifier, perm)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if not xPlayer then return false end

    -- Support both ESX group strings (e.g. "Admin") and job names.
    local group = xPlayer.getGroup()
    if group == perm then return true end

    local jobName = xPlayer.job and xPlayer.job.name or ""
    if jobName == string.lower(perm) then return true end

    -- Also support ESX admin check via IsPlayerAceAllowed if the perm looks like an ace node
    if string.find(perm, "%.") then
        return IsPlayerAceAllowed(tostring(xPlayer.source), perm)
    end

    return false
end

-- Return the amount of a given item in the player's inventory.
-- Original: vRP.InventoryItemAmount(user_id, idname)
zof.getInventoryItemAmount = function(identifier, idname)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if not xPlayer then return 0 end

    local item = xPlayer.getInventoryItem(idname)
    return item and item.count or 0
end

-- Remove `amount` of an item from the player's inventory (returns true on success).
-- Original: vRP.TakeItem(user_id, item, amount, true)
zof.tryGetInventoryItem = function(identifier, item, amount)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if not xPlayer then return false end

    local invItem = xPlayer.getInventoryItem(item)
    if invItem and invItem.count >= amount then
        xPlayer.removeInventoryItem(item, amount)
        return true
    end
    return false
end

-- Give `qtd` of an item to the player.
-- Original: vRP.GiveItem(user_id, item, qtd, true)
zof.giveInventoryItem = function(identifier, item, qtd)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if not xPlayer then return end
    xPlayer.addInventoryItem(item, qtd)
end

-- Return the ESX identifier of the player who owns a vehicle with the given plate.
-- Original: vRP.PassportPlate(placa)
-- ESX stores vehicle ownership in the `owned_vehicles` table (owner = identifier, plate).
zof.getUserByRegistration = function(placa)
    local result = MySQL.Sync.fetchScalar(
        "SELECT `owner` FROM `owned_vehicles` WHERE `plate` = ? LIMIT 1",
        { string.upper(string.gsub(placa, "%s+", "")) }
    )
    return result or nil
end

-- Persist arbitrary data server-side, keyed by `key`.
-- Original: vRP.SetSrvData(key, data, true)
-- ESX-Legacy replacement: we store tuning data in a dedicated `zo_tuning_data` table.
-- The key is the full compound key used in the original (e.g. "zoCustomVehicle:<id>veh_<n>placa_<p>").
zof.setSData = function(key, data)
    if type(data) == "table" then
        data = json.encode(data)
    end
    MySQL.Async.execute(
        "INSERT INTO `zo_tuning_data` (`data_key`, `data_value`) VALUES (?, ?) " ..
        "ON DUPLICATE KEY UPDATE `data_value` = VALUES(`data_value`)",
        { key, data }
    )
end

-- Retrieve previously persisted data by key.
-- Original: vRP.GetSrvData(key, true)
zof.getSData = function(key)
    local result = MySQL.Sync.fetchScalar(
        "SELECT `data_value` FROM `zo_tuning_data` WHERE `data_key` = ? LIMIT 1",
        { key }
    )
    return result or nil
end