local categories, vehicles = {}, {}
local vehiclesByModel = {}

TriggerEvent("esx_society:registerSociety", "cardealer", TranslateCap("car_dealer"), "society_cardealer", "society_cardealer", "society_cardealer", {
    type = "private",
})

CreateThread(function()
    local char = Config.PlateLetters
    char = char + Config.PlateNumbers
    if Config.PlateUseSpace then
        char = char + 1
    end

    if char > 8 then
        print(("[^3WARNING^7] Character Limit Exceeded, ^5%s/8^7!"):format(char))
    end
end)

function RemoveOwnedVehicle(plate)
    MySQL.update("DELETE FROM owned_vehicles WHERE plate = ?", { plate })
end

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SQLVehiclesAndCategories()
    end
end)

function SQLVehiclesAndCategories()
    categories = MySQL.query.await("SELECT * FROM vehicle_categories")
    vehicles = MySQL.query.await("SELECT vehicles.*, vehicle_categories.label AS categoryLabel FROM vehicles JOIN vehicle_categories ON vehicles.category = vehicle_categories.name")

    for _, vehicle in pairs(vehicles) do
        vehiclesByModel[vehicle.model] = vehicle
    end

    TriggerClientEvent("esx_vehicleshop:updateVehiclesAndCategories", -1, vehicles, categories, vehiclesByModel)
end

function getVehicleFromModel(model)
    return vehiclesByModel[model]
end

RegisterNetEvent("esx_vehicleshop:getVehiclesAndCategories", function()
    TriggerClientEvent("esx_vehicleshop:updateVehiclesAndCategories", source, vehicles, categories, vehiclesByModel)
end)

RegisterNetEvent("esx_vehicleshop:setVehicleOwnedPlayerId")
AddEventHandler("esx_vehicleshop:setVehicleOwnedPlayerId", function(playerId, vehicleProps, model, label)
    local xPlayer, xTarget = ESX.Player(source), ESX.Player(playerId)

    if xPlayer.getJob().name ~= "cardealer" or not xTarget then
        return
    end
    local xTargetName = xTarget.getName()
    MySQL.scalar("SELECT id FROM cardealer_vehicles WHERE vehicle = ?", { model }, function(id)
        if not id then
            return
        end

        MySQL.update("DELETE FROM cardealer_vehicles WHERE id = ?", { id }, function(rowsChanged)
            if rowsChanged == 1 then
                MySQL.insert("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)", { xTarget.getIdentifier(), vehicleProps.plate, json.encode(vehicleProps) }, function(id)
                    xPlayer.showNotification(TranslateCap("vehicle_set_owned", vehicleProps.plate, xTargetName))
                    xTarget.showNotification(TranslateCap("vehicle_belongs", vehicleProps.plate))
                end)

                MySQL.insert("INSERT INTO vehicle_sold (client, model, plate, soldby, date) VALUES (?, ?, ?, ?, ?)", { xTargetName, label, vehicleProps.plate, xPlayer.getName(), os.date("%Y-%m-%d %H:%M") })
            end
        end)
    end)
end)

ESX.RegisterServerCallback("esx_vehicleshop:getSoldVehicles", function(source, cb)
    MySQL.query("SELECT client, model, plate, soldby, date FROM vehicle_sold ORDER BY DATE DESC", function(result)
        cb(result)
    end)
end)

RegisterNetEvent("esx_vehicleshop:rentVehicle")
AddEventHandler("esx_vehicleshop:rentVehicle", function(vehicle, plate, rentPrice, playerId)
    local xPlayer, xTarget = ESX.Player(source), ESX.Player(playerId)

    if xPlayer.getJob().name ~= "cardealer" or not xTarget then
        return
    end
    local xTargetName = xTarget.getName()
    MySQL.single("SELECT id, price FROM cardealer_vehicles WHERE vehicle = ?", { vehicle }, function(result)
        if not result then
            return
        end

        MySQL.update("DELETE FROM cardealer_vehicles WHERE id = ?", { result.id }, function(rowsChanged)
            if rowsChanged ~= 1 then
                return
            end
        end)
    end)
end)

ESX.RegisterServerCallback("esx_vehicleshop:buyVehicle", function(source, cb, model, plate)
    local xPlayer = ESX.Player(source)
    local modelPrice = getVehicleFromModel(model).price

    if modelPrice and xPlayer.getMoney() >= modelPrice then
        xPlayer.removeMoney(modelPrice, "Vehicle Purchase")

        MySQL.insert("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)", { xPlayer.getIdentifier(), plate, json.encode({ model = joaat(model), plate = plate }) }, function(rowsChanged)
            xPlayer.showNotification(TranslateCap("vehicle_belongs", plate))
            ESX.OneSync.SpawnVehicle(joaat(model), Config.Zones.ShopOutside.Pos, Config.Zones.ShopOutside.Heading, { plate = plate }, function(vehicle)
                Wait(100)
                local vehicle = NetworkGetEntityFromNetworkId(vehicle)
                Wait(300)
                TaskWarpPedIntoVehicle(GetPlayerPed(source), vehicle, -1)
            end)
            cb(true)
        end)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback("esx_vehicleshop:getCommercialVehicles", function(source, cb)
    MySQL.query("SELECT price, vehicle FROM cardealer_vehicles ORDER BY vehicle ASC", function(result)
        cb(result)
    end)
end)

ESX.RegisterServerCallback("esx_vehicleshop:buyCarDealerVehicle", function(source, cb, model)
    local xPlayer = ESX.Player(source)

    if xPlayer.getJob().name ~= "cardealer" then
        return cb(false)
    end
    local modelPrice = getVehicleFromModel(model).price

    if not modelPrice then
        return cb(false)
    end
    TriggerEvent("esx_addonaccount:getSharedAccount", "society_cardealer", function(account)
        if account.money < modelPrice then
            return cb(false)
        end

        account.removeMoney(modelPrice)

        MySQL.insert("INSERT INTO cardealer_vehicles (vehicle, price) VALUES (?, ?)", { model, modelPrice }, function(rowsChanged)
            cb(true)
        end)
    end)
end)

RegisterNetEvent("esx_vehicleshop:returnProvider")
AddEventHandler("esx_vehicleshop:returnProvider", function(vehicleModel)
    local xPlayer = ESX.Player(source)

    if xPlayer.getJob().name ~= "cardealer" then
        return
    end
    MySQL.single("SELECT id, price FROM cardealer_vehicles WHERE vehicle = ?", { vehicleModel }, function(result)
        if not result then
            return print(("[^3WARNING^7] Player ^5%s^7 Attempted To Sell Invalid Vehicle - ^5%s^7!"):format(source, vehicleModel))
        end

        local id = result.id

        MySQL.update("DELETE FROM cardealer_vehicles WHERE id = ?", { id }, function(rowsChanged)
            if rowsChanged ~= 1 then
                return
            end
            TriggerEvent("esx_addonaccount:getSharedAccount", "society_cardealer", function(account)
                local price = ESX.Math.Round(result.price * 0.75)
                local vehicleLabel = getVehicleFromModel(vehicleModel).name

                account.addMoney(price)
                xPlayer.showNotification(TranslateCap("vehicle_sold_for", vehicleLabel, ESX.Math.GroupDigits(price)))
            end)
        end)
    end)
end)

ESX.RegisterServerCallback("esx_vehicleshop:getRentedVehicles", function(source, cb)
    MySQL.query("SELECT * FROM rented_vehicles ORDER BY player_name ASC", function(result)
        local vehicles = {}

        for i = 1, #result do
            local vehicle = result[i]
            vehicles[#vehicles + 1] = {
                name = vehicle.vehicle,
                plate = vehicle.plate,
                playerName = vehicle.player_name,
            }
        end

        cb(vehicles)
    end)
end)

ESX.RegisterServerCallback("esx_vehicleshop:giveBackVehicle", function(source, cb, plate)
    MySQL.single("SELECT base_price, vehicle FROM rented_vehicles WHERE plate = ?", { plate }, function(result)
        if not result then
            return cb(false)
        end

        MySQL.update("DELETE FROM rented_vehicles WHERE plate = ?", { plate }, function()
            MySQL.insert("INSERT INTO cardealer_vehicles (vehicle, price) VALUES (?, ?)", { result.vehicle, result.base_price })

            RemoveOwnedVehicle(plate)
            cb(true)
        end)
    end)
end)

ESX.RegisterServerCallback("esx_vehicleshop:resellVehicle", function(source, cb, plate, model)
    local xPlayer, resellPrice = ESX.Player(source)

    if xPlayer.getJob().name == "cardealer" or not Config.EnablePlayerManagement then
        -- calculate the resell price
        for i = 1, #vehicles, 1 do
            if joaat(vehicles[i].model) == model then
                resellPrice = ESX.Math.Round(vehicles[i].price / 100 * Config.ResellPercentage)
                break
            end
        end

        if not resellPrice then
            print(("[^3WARNING^7] Player ^5%s^7 Attempted To Resell Invalid Vehicle - ^5%s^7!"):format(source, model))
            return cb(false)
        end
        MySQL.single("SELECT * FROM rented_vehicles WHERE plate = ?", { plate }, function(result)
            if result then -- is it a rented vehicle?
                return cb(false) -- it is, don't let the player sell it since he doesn't own it
            end
            MySQL.single("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ?", { xPlayer.getIdentifier(), plate }, function(result)
                if not result then -- does the owner match?
                    return
                end
                local vehicle = json.decode(result.vehicle)

                if vehicle.model ~= model then
                    print(("[^3WARNING^7] Player ^5%s^7 Attempted To Resell Vehicle With Invalid Model - ^5%s^7!"):format(source, model))
                    return cb(false)
                end
                if vehicle.plate ~= plate then
                    print(("[^3WARNING^7] Player ^5%s^7 Attempted To Resell Vehicle With Invalid Plate - ^5%s^7!"):format(source, plate))
                    return cb(false)
                end

                xPlayer.addMoney(resellPrice, "Sold Vehicle")
                RemoveOwnedVehicle(plate)
                cb(true)
            end)
        end)
    end
end)

ESX.RegisterServerCallback("esx_vehicleshop:getStockItems", function(source, cb)
    TriggerEvent("esx_addoninventory:getSharedInventory", "society_cardealer", function(inventory)
        cb(inventory.items)
    end)
end)

ESX.RegisterServerCallback("esx_vehicleshop:getPlayerInventory", function(source, cb)
    local xPlayer = ESX.Player(source)
    local items = xPlayer.getInventory(true)

    cb({ items = items })
end)

ESX.RegisterServerCallback("esx_vehicleshop:isPlateTaken", function(source, cb, plate)
    MySQL.scalar("SELECT plate FROM owned_vehicles WHERE plate = ?", { plate }, function(result)
        cb(result ~= nil)
    end)
end)

ESX.RegisterServerCallback("esx_vehicleshop:retrieveJobVehicles", function(source, cb, type)
    local xPlayer = ESX.Player(source)

    MySQL.query("SELECT * FROM owned_vehicles WHERE owner = ? AND type = ? AND job = ?", { xPlayer.getIdentifier(), type, xPlayer.getJob().name }, function(result)
        cb(result)
    end)
end)

RegisterNetEvent("esx_vehicleshop:setJobVehicleState")
AddEventHandler("esx_vehicleshop:setJobVehicleState", function(plate, state)
    local xPlayer = ESX.Player(source)

    MySQL.update("UPDATE owned_vehicles SET `stored` = ? WHERE plate = ? AND job = ?", { state, plate, xPlayer.getJob().name }, function(rowsChanged)
        if rowsChanged == 0 then
            print(("[^3WARNING^7] Player ^5%s^7 Attempted To Exploit the Garage!"):format(source, plate))
        end
    end)
end)
