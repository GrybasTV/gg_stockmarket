Config = {}

Config.Language = "lt" -- Pasirinkite numatytąją kalbą

Config.keys = {
    ["G"] = 0x760A9C6F -- Menu open key
}

-- Prekybos vieta
Config.StockMarketLocation = {  --- Only one location is supported
    x = -819.28, y = -1278.56, z = 43.59,
}

-- Blipas
BlipData = {
    blips = {
        {name = "Stock Market",  
        sprite = -1567930587, --  https://filmcrz.github.io/blips/
        x = Config.StockMarketLocation.x, 
        y = Config.StockMarketLocation.y, 
        z = Config.StockMarketLocation.z, 
        color = 'BLIP_MODIFIER_MP_COLOR_32'},
    }
}

Config.Stocks = {
    ["bond1"] = { 
        label = "West Elizabeth Obligacijos", -- Label
        price = 10.00, -- Initial price
        item = "bond1", -- Iten name from db
        priceChange = { increase = 0.33, decrease = 0.34 }, -- Price change affter each transaction
        minPrice = 1.00 -- Market will crash on this price. Helps avoid negative value
    },
    ["bond2"] = { 
        label = "New Hanover Obligacijos",  
        price = 10.00,
        item = "bond2",
        priceChange = { increase = 0.33, decrease = 0.34 },
        minPrice = 1.00 -- 
    },
    ["bond3"] = { 
        label = "Cornwall Co. Akcijos",  --- 
        price = 10.00,
        item = "bond3",
        priceChange = { increase = 0.1, decrease = 0.11 },
        minPrice = 1.00 -- 
    }
}


Config.cooldownTime = 0.5 --- Seconds. Globar Cooldown between transactions. Increases on long db queries.

