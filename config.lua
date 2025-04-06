Config = {}

Config.DiscordWebhook = "INSERISCI_QUI_IL_TUO_WEBHOOK" -- inserisci il tuo webhook discord per i log

-- Impostazioni Generali del Sistema
Config.Command = "autogratis"         -- Comando per richiedere il veicolo gratuito
Config.DefaultPlate = "REGALO"        -- Prefisso targa (verrà aggiunto numero casuale)
Config.Framework = "esx"              -- Framework utilizzato
Config.AdminCommand = "resetveicolo"  -- Comando admin per gestione veicoli riscattati

-- Configurazione Notifiche
Config.Notifications = {
    title = "🚗 Auto Gratis",                                                    -- Titolo delle notifiche
    alreadyClaimed = "Hai già riscattato la tua auto gratuita! Controlla il tuo garage.",  -- Messaggio se già riscattato
    success = "Hai ricevuto la tua auto gratuita! Puoi ritirarla dal garage.",             -- Messaggio di successo
    error = "Si è verificato un errore durante la consegna del veicolo."                    -- Messaggio di errore
}

-- Configurazione Menu Interface
Config.Menu = {
    title = "Auto Gratuita per Nuovi Giocatori",    -- Titolo del menu principale
    description = "Scegli un'auto gratuita per iniziare la tua avventura",  -- Descrizione menu
    position = 'middle',                            -- Posizione del menu sullo schermo
    icon = "car"                                    -- Icona del menu
}

-- Lista Veicoli Disponibili
Config.Vehicles = {
    {
        label = "Fiat Panda",                           -- Nome visualizzato
        model = "panto",                                -- Modello spawn del veicolo
        description = "Una piccola utilitaria perfetta per la città",  -- Descrizione veicolo
        icon = "car-side"                               -- Icona nel menu
    }
    -- Puoi aggiungere altri veicoli seguendo la stessa struttura
}

-- Impostazioni Garage
Config.Garage = {
    defaultGarage = "A",    -- Garage dove verrà salvato il veicolo
    defaultType = "car"     -- Tipo di veicolo (car, boat, aircraft)
}
