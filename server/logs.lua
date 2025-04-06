local ESX = exports["es_extended"]:getSharedObject()

local function SendDiscordLog(source, model, plate, color)
    local xPlayer = ESX.GetPlayerFromId(source)
    local steamName = GetPlayerName(source)
    local steamID = xPlayer.identifier

    local embed = {
        {
            ["title"] = "🚗 Nuovo Veicolo Riscattato",
            ["color"] = 3447003,
            ["fields"] = {
                {["name"] = "Giocatore", ["value"] = steamName, ["inline"] = true},
                {["name"] = "Steam ID", ["value"] = steamID, ["inline"] = true},
                {["name"] = "Veicolo", ["value"] = model, ["inline"] = true},
                {["name"] = "Targa", ["value"] = plate, ["inline"] = true},
                {["name"] = "Colore", ["value"] = string.format("RGB(%d,%d,%d)", color.r, color.g, color.b), ["inline"] = true}
            },
            ["footer"] = {
                ["text"] = "Flash AutoGratis System • " .. os.date("%d/%m/%Y %H:%M")
            }
        }
    }

    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
end

exports('SendDiscordLog', SendDiscordLog)
