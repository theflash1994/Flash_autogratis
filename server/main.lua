-- Variabili locali
local ESX = nil

-- Inizializzazione del framework ESX
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Funzione per ottenere l'identificatore del giocatore
local function GetPlayerIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        return xPlayer.identifier
    end
    return nil
end

-- Controlla se un giocatore ha già riscattato un veicolo
RegisterNetEvent('free-starter-car:checkClaim')
AddEventHandler('free-starter-car:checkClaim', function()
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if not identifier then
        return
    end
    
    -- Verifica se esiste già una colonna autogratis nella tabella owned_vehicles
    MySQL.Async.fetchAll('SHOW COLUMNS FROM owned_vehicles LIKE "autogratis"', {}, function(columns)
        if #columns == 0 then
            -- La colonna non esiste, creala
            MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN autogratis TINYINT(1) DEFAULT 0', {}, function()
                print('Colonna autogratis aggiunta alla tabella owned_vehicles')
                CheckVehicleClaim(src, identifier)
            end)
        else
            -- La colonna esiste già
            CheckVehicleClaim(src, identifier)
        end
    end)
end)

-- Funzione per verificare se il giocatore ha già riscattato un veicolo
function CheckVehicleClaim(src, identifier)
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM owned_vehicles WHERE owner = @owner AND autogratis = 1', {
        ['@owner'] = identifier
    }, function(count)
        if count > 0 then
            -- Il giocatore ha già riscattato un veicolo
            TriggerClientEvent('free-starter-car:alreadyClaimed', src)
        else
            -- Il giocatore non ha ancora riscattato un veicolo
            TriggerClientEvent('free-starter-car:openMenu', src)
        end
    end)
end

-- Salva il veicolo nel database
RegisterNetEvent('free-starter-car:saveVehicle')
AddEventHandler('free-starter-car:saveVehicle', function(model, plate, color)
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if not identifier then return end
    
    plate = string.upper(string.gsub(plate, "%s+", ""))
    plate = string.sub(plate, 1, 8)
    
    local playerName = GetPlayerName(src)
    print("Colore ricevuto dal client:", json.encode(color))
    
    local vehicleProps = {
        model = GetHashKey(model),
        plate = plate,
        engineHealth = 1000.0,
        bodyHealth = 1000.0,
        fuelLevel = 100.0,
        
        -- Solo le proprietà necessarie per il colore
        color1 = 34,
        color2 = 34,
        pearlescentColor = 0,
        wheelColor = 0,
        
        -- Colori personalizzati
        customPrimaryColor = {r = color.r, g = color.g, b = color.b},
        customSecondaryColor = {r = color.r, g = color.g, b = color.b},
        
        -- Colori RGB separati per massima compatibilità
        colore1r = color.r,
        colore1g = color.g,
        colore1b = color.b,
        colore2r = color.r,
        colore2g = color.g,
        colore2b = color.b
    }
    
    local vehiclePropsJson = json.encode(vehicleProps)
    print("Proprietà del veicolo:", vehiclePropsJson)
    
    local vehicleName = "Auto Gratuita"
    for _, v in ipairs(Config.Vehicles) do
        if v.model == model then
            vehicleName = v.label
            break
        end
    end
    
    local query = [[
        INSERT INTO owned_vehicles 
        (owner, plate, vehicle, stored, type, vehiclename, garage, autogratis) 
        VALUES 
        (@owner, @plate, @vehicle, 1, 'car', @vehiclename, @garage, 1)
    ]]
    
    local params = {
        ['@owner'] = identifier,
        ['@plate'] = plate,
        ['@vehicle'] = vehiclePropsJson,
        ['@vehiclename'] = vehicleName,
        ['@garage'] = Config.Garage.defaultGarage or 'A'
    }
    
    MySQL.Async.execute(query, params, function(rowsChanged)
        if rowsChanged > 0 then
            exports.Flash_autogratis:SendDiscordLog(src, model, plate, color)
            print('Vehicle saved successfully for player ' .. playerName .. ' with plate ' .. plate)
            TriggerClientEvent('free-starter-car:vehicleSaved', src)
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Notifications.title,
                description = Config.Notifications.error,
                type = 'error'
            })
        end
    end)    
end)

-- Comando admin per resettare il claim di un giocatore
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    MySQL.Async.fetchAll('SHOW COLUMNS FROM owned_vehicles LIKE "info"', {}, function(columns)
        if #columns == 0 then
            MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN info TIMESTAMP DEFAULT CURRENT_TIMESTAMP', {})
            print('Colonna info aggiunta alla tabella owned_vehicles')
        end
    end)
end)

RegisterCommand(Config.AdminCommand, function(source, args, rawCommand)
    local src = source
    
    if IsPlayerAceAllowed(src, "command.resetauto") then
        MySQL.Async.fetchAll([[
            SELECT 
                ov.*,
                UNIX_TIMESTAMP(ov.info) as info_timestamp,
                u.firstname,
                u.lastname,
                u.dateofbirth,
                u.identifier as steam,
                u.phone_number
            FROM owned_vehicles ov
            LEFT JOIN users u ON ov.owner = u.identifier
            WHERE ov.autogratis = 1
        ]], {}, function(vehicles)
            if vehicles and #vehicles > 0 then
                local options = {}
                
                for _, vehicle in ipairs(vehicles) do
                    local fullName = (vehicle.firstname and vehicle.lastname) and
                        ("%s %s"):format(vehicle.firstname, vehicle.lastname) or "Nome non disponibile"
                    
                    local infoData = vehicle.info_timestamp and os.date('%d/%m/%Y %H:%M', vehicle.info_timestamp) or "Non disponibile"
                    
                    table.insert(options, {
                        title = fullName,
                        description = ("Targa: %s | Veicolo: %s"):format(vehicle.plate, vehicle.vehiclename or "Non specificato"),
                        metadata = {
                            -- {label = 'Steam', value = vehicle.steam or "Non disponibile"},
                            -- {label = 'Telefono', value = vehicle.phone_number or "Non disponibile"},
                            -- {label = 'Data di nascita', value = vehicle.dateofbirth or "Non disponibile"},
                            {label = 'Garage', value = vehicle.garage or "Non specificato"},
                            {label = 'Tipo Veicolo', value = vehicle.type or "Auto"},
                            {label = 'Data Riscatto', value = infoData},
                            {label = 'Identifier', value = vehicle.owner or "Non disponibile"}
                        },
                        args = {plate = vehicle.plate}
                    })
                end

                TriggerClientEvent('flash_autogratis:openAdminMenu', src, options)
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Admin System',
                    description = 'Nessun veicolo gratuito trovato nel database',
                    type = 'error'
                })
            end
        end)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Admin System',
            description = 'Non hai i permessi necessari',
            type = 'error'
        })
    end
end, false)

RegisterNetEvent('flash_autogratis:deleteVehicle')
AddEventHandler('flash_autogratis:deleteVehicle', function(plate)
    local src = source
    if IsPlayerAceAllowed(src, "command.resetauto") then
        MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate = @plate AND autogratis = 1', {
            ['@plate'] = plate
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Rimozione Veicolo Gratis',
                    description = 'Veicolo rimosso con successo!',
                    type = 'success'
                })
            end
        end)
    end
end)

-- Aggiunge la colonna autogratis se non esiste quando la risorsa viene avviata
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    MySQL.Async.fetchAll('SHOW COLUMNS FROM owned_vehicles LIKE "autogratis"', {}, function(columns)
        if #columns == 0 then
            MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN autogratis TINYINT(1) DEFAULT 0', {}, function()
                print('Colonna autogratis aggiunta alla tabella owned_vehicles')
            end)
        end
    end)
    
    print('Resource ' .. resourceName .. ' started. Free starter car system initialized.')
end)
