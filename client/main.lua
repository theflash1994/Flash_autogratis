local ESX = nil
local selectedVehicle = nil

CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(0)
    end
end)

RegisterNetEvent('free-starter-car:openMenu')
AddEventHandler('free-starter-car:openMenu', function()
    local options = {}
    
    for i, vehicle in ipairs(Config.Vehicles) do
        table.insert(options, {
            title = vehicle.label,
            description = vehicle.description or "Riscatta questo veicolo",
            icon = vehicle.icon or "car",
            onSelect = function()
                selectedVehicle = vehicle
                OpenColorInputMenu()
            end
        })
    end
    
    lib.registerContext({
        id = 'free_starter_car_menu',
        title =  Config.Menu.title, 
        options = options
    })
    
    lib.showContext('free_starter_car_menu')
end)

-- Funzione per aprire il menu di input per i colori con color picker
function OpenColorInputMenu()
    if not selectedVehicle then return end
    
    local input = lib.inputDialog('Seleziona il colore del veicolo', {
        {type = 'color', label = 'Colore', format = 'rgb', description = 'Seleziona un colore per il tuo veicolo'}
    })
    
    if input then
        local colorRGB = lib.math.torgba(input[1])
        local color = {
            r = math.floor(colorRGB.x),
            g = math.floor(colorRGB.y),
            b = math.floor(colorRGB.z)
        }
        
        ClaimVehicle(selectedVehicle.model, color)
    else
        -- L'utente ha annullato, torna al menu principale
        lib.showContext('free_starter_car_menu')
    end
end

-- Funzione per generare una targa casuale
local function GeneratePlate()
    local plate = Config.DefaultPlate or "FREE"
    local randomNum = math.random(100, 999)
    -- Rimuovi spazi, converti in maiuscolo e limita a 8 caratteri
    plate = string.upper(string.gsub(plate, "%s+", "")) .. randomNum
    plate = string.sub(plate, 1, 8)
    return plate
end

-- Funzione per riscattare il veicolo
function ClaimVehicle(model, color)
    local plate = GeneratePlate()
    
    -- Prima notifica
    lib.notify({
        title = Config.Notifications.title,
        description = "Stiamo preparando il tuo veicolo...",
        type = 'info',
        duration = 2000
    })
    
    -- Aggiungiamo un piccolo ritardo prima di salvare il veicolo
    Wait(2000)
    
    -- Salva il veicolo nel database
    TriggerServerEvent('free-starter-car:saveVehicle', model, plate, color)
end

-- Notifica che il veicolo è stato salvato
RegisterNetEvent('free-starter-car:vehicleSaved')
AddEventHandler('free-starter-car:vehicleSaved', function()
    lib.notify({
        title = Config.Notifications.title,
        description = Config.Notifications.success,
        type = 'success'
    })
end)

-- Notifica che il giocatore ha già riscattato un veicolo
RegisterNetEvent('free-starter-car:alreadyClaimed')
AddEventHandler('free-starter-car:alreadyClaimed', function()
    lib.notify({
        title = Config.Notifications.title,
        description = Config.Notifications.alreadyClaimed,
        type = 'error'
    })
end)

RegisterNetEvent('flash_autogratis:openAdminMenu')
AddEventHandler('flash_autogratis:openAdminMenu', function(options)
    for i, option in ipairs(options) do
        local originalTitle = option.title
        option.onSelect = function(args)
            lib.registerContext({
                id = 'admin_confirm_delete',
                title = 'Conferma Rimozione',
                menu = 'admin_reset_vehicles',
                options = {
                    {
                        title = 'Conferma Rimozione',
                        description = 'Sei sicuro di voler rimuovere il veicolo di ' .. originalTitle .. '?',
                        icon = 'trash',
                        iconColor = 'red',
                        onSelect = function()
                            TriggerServerEvent('flash_autogratis:deleteVehicle', args.plate)
                        end
                    },
                    {
                        title = 'Annulla',
                        description = 'Torna al menu precedente',
                        icon = 'x',
                        iconColor = 'gray',
                        menu = 'admin_reset_vehicles'
                    }
                }
            })
            lib.showContext('admin_confirm_delete')
        end
    end

    lib.registerContext({
        id = 'admin_reset_vehicles',
        title = 'Gestione Veicoli Gratuiti',
        options = options
    })
    
    lib.showContext('admin_reset_vehicles')
end)

-- Comando per aprire il menu
RegisterCommand('autogratis', function()
    TriggerServerEvent('free-starter-car:checkClaim')
end, false)
