Config = {}

--- Discord
Config.discordWebhook = true
Config.webhookUrl = "url"

Config.Discordhookmesage = {
}

-- Tax
Config.Tax = 1.00 -- Percentage of transaction as tax (e.g., 0.5% tax)


--- Keys
Config.keys = {
    ["G"] = 0x760A9C6F -- Menu open key
}

-- Trading location
Config.StockMarketLocations = {  -- 
    {
        name = "West Elizabeth Akciju Birža ", -- blip name
        x = -819.28, y = -1278.56, z = 43.59,
        stocks = { "bond1", "bond3", "goldnugget", "goldbar"} -- Only these stocks are available at this location
    },
    {
        name = "New Hanover Akciju Birža",
        x = -305.26, y = 775.42, z = 118.7,
        stocks = { "bond2", "bond3", "goldnugget", "goldbar"} 
    },
    {
        name = "New Hanover Žaliavu Birža",
        x = -291.9, y = 780.81, z = 119.26,
        stocks = {             
            "iron", "coal", "copper", "sulfur", 
            "ironbar", "copperbar", "crate",
            "skin", "Feather", "Wood", "hwood", "woodlog", 
            "consumable_meat_succulent_fish_cooked", "salt"
        }
    },
    
}
--- Blip settings
Config.Blip = {
    sprite = -1567930587, -- https://filmcrz.github.io/blips/
    color = 'BLIP_MODIFIER_MP_COLOR_32' -- Spalva
}

--- Stock market items 
Config.Stocks = {
    ["bond1"] = { -- same as item
        label = "West Elizabeth Obligacijos", -- Label
        price = 10.00, -- Initial price
        item = "bond1", -- Iten name from db
        priceChange = { increase = 0.33, decrease = 0.33 }, -- Price change affter each transaction // 
        minPrice = 0.01 -- Market will crash on this price. Helps avoid negative value
    },
    ["bond2"] = { 
        label = "New Hanover Obligacijos",  
        price = 10.00,
        item = "bond2",
        priceChange = { increase = 0.36, decrease = 0.36 },
        minPrice = 0.01 -- 
    },
    ["bond3"] = { 
        label = "Cornwall Co. Akcijos",  --- 
        price = 10.00,
        item = "bond3",
        priceChange = { increase = 0.11, decrease = 0.11 },
        minPrice = 0.01 -- 
    },
    ["goldnugget"] = { 
        label = "Aukso Grynuoliai",  --- 
        price = 1.00,
        item = "goldnugget",
        priceChange = { increase = 0.01, decrease = 0.01 }, 
        minPrice = 0.01 -- 
    },
    ["goldbar"] = { 
        label = "Aukso Luitai",  --- 
        price = 100.00,
        item = "goldbar",
        priceChange = { increase = 1.00, decrease = 1.00 },
        minPrice = 1.00 -- 
    },
------------------ Could be added not only stocks ------------------
    ["iron"] = { 
        label = "Geležis",  
        price = 0.50,
        item = "iron",
        priceChange = { increase = 0.01, decrease = 0.01 }, 
        minPrice = 0.01 -- 
    },
    ["coal"] = { 
        label = "Anglis",  
        price = 0.50,
        item = "coal",
        priceChange = { increase = 0.01, decrease = 0.01 }, 
        minPrice = 0.01 -- 
    },
    ["copper"] = { 
        label = "Varis",  --- 
        price = 0.50,
        item = "copper",
        priceChange = { increase = 0.01, decrease = 0.01 }, 
        minPrice = 0.01 -- 
    },
    ["sulfur"] = { 
        label = "Siera",  --- 
        price = 0.50,
        item = "sulfur",
        priceChange = { increase = 0.01, decrease = 0.01 }, 
        minPrice = 0.01 -- 
    },
    ["ironbar"] = { 
        label = "Plienas",  
        price = 10.00,
        item = "ironbar",
        priceChange = { increase = 0.10, decrease = 0.11 }, 
        minPrice = 0.10 -- 
    },
    ["copperbar"] = { 
        label = "Vario Luitas",  --- 
        price = 100.00,
        item = "copperbar",
        priceChange = { increase = 1.00, decrease = 1.00 },
        minPrice = 1.00 -- 
    },
    ["crate"] = { 
        label = "Ūkininko Dėžės",  
        price = 50.00,
        item = "crate",
        priceChange = { increase = 0.50, decrease = 0.50 },
        minPrice = 1.00 -- 
    },
    ["skin"] = { 
        label = "Oda",  
        price = 1.00,
        item = "skin",
        priceChange = { increase = 0.01, decrease = 0.01 }, 
        minPrice = 0.01 -- 
    },
    ["Feather"] = { 
        label = "Plunksnos",  
        price = 1.00,
        item = "Feather",
        priceChange = { increase = 0.01, decrease = 0.01 }, 
        minPrice = 0.01 -- 
    },
    ["Wood"] = { 
        label = "Medienos Gaminiai",  
        price = 0.50,
        item = "Wood",
        priceChange = { increase = 0.01, decrease = 0.01 }, 
        minPrice = 0.01 -- 
    },
    ["hwood"] = { 
        label = "Medienos Lentos",  
        price = 1.50,
        item = "hwood",
        priceChange = { increase = 0.02, decrease = 0.02 }, 
        minPrice = 0.01 -- 
    },
    ["woodlog"] = { 
        label = "Medienos Rąstas",  
        price = 3.00,
        item = "woodlog",
        priceChange = { increase = 0.03, decrease = 0.03 }, 
        minPrice = 0.01 -- 
    },
    ["consumable_meat_succulent_fish_cooked"] = { 
        label = "Žalia Žuvis",  
        price = 5.00,
        item = "consumable_meat_succulent_fish_cooked",
        priceChange = { increase = 0.05, decrease = 0.05 }, 
        minPrice = 0.01 -- 
    },
    ["salt"] = { 
        label = "Druska",  
        price = 1.00,
        item = "salt",
        priceChange = { increase = 0.01, decrease = 0.01 }, 
        minPrice = 0.01 -- 
    },
   ----------------- 
}


Config.cooldownTime = 0.5 --- Seconds. Globar Cooldown between transactions. Increases on long db queries.

--- Language
Config.Language = "lt" -- Pasirinkite numatytąją kalbą
Config.Translations = {
    en = {
        blipname = "Stock Market",
        menuTitle = "Stock Market",
        buyOption = "---Buy %s ---",
        sellOption = "Sell %s",
        notEnoughMoney = "You don't have enough money!",
        noSpaceInInventory = "You don't have enough space in your inventory!",
        itemNotFound = "You don't have this item!",
        notEnoughItems = "You don't have enough items to sell!",
        priceTooLow = "You can't sell this item for that price!",
        buySuccess = "You bought %d x %s for $%.2f",
        sellSuccess = "You sold %d x %s for $%.2f",
        cooldownNotification = "Please wait %d seconds",
        promptText = "Press [G] to start trading",
        tax = "Tax",
        ---- Discordhookmesage
        price = "Price",
        item = "Goods",    },
    lt = {
        blipname = "Akciju Birža",
        menuTitle = "Birža",
        buyOption = "---Pirkti %s ---",
        sellOption = "Parduoti %s",        
        noSpaceInInventory = "Neturite vietos inventoriuje!",
        itemNotFound = "Neturite prekes!",
        notEnoughItems = "Neturite ka parduoti!",
        priceTooLow = "Nera kam parduoti!", 
        cooldownNotification = "Prašome palaukti %d sekundžiu",
        promptText = "Spauskite [G] prekiauti",
        notEnoughMoney = "Neturite pakankamai pinigu!",
        buySuccess = "Pirkote %d x %s už $%.2f",
        sellSuccess = "Parduota %d x %s už $%.2f",
        tax = "Tax",
        ---- Discordhookmesage
        price = "Kaina",
        item = "Prekė",
    }
}