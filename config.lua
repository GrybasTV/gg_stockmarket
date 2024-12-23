Config = {}

Config.Language = "en" -- Pasirinkite numatytąją kalbą

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
        promptText = "Press [G] to start trading"
    },
    lt = {
        blipname = "Akciju Birža",
        menuTitle = "Birža",
        buyOption = "---Pirkti %s ---",
        sellOption = "Parduoti %s",
        notEnoughMoney = "Neturite pakankamai pinigu!",
        noSpaceInInventory = "Neturite vietos inventoriuje!",
        itemNotFound = "Neturite prekes!",
        notEnoughItems = "Neturite ka parduoti!",
        priceTooLow = "Nera kam parduoti!",
        buySuccess = "Pirkote %d x %s už $%.2f",
        sellSuccess = "Parduota %d x %s už $%.2f",
        cooldownNotification = "Prašome palaukti %d sekundžiu",
        promptText = "Spauskite [G] prekiauti"
    }
}

Config.keys = {
    ["G"] = 0x760A9C6F -- Menu open key
}

-- Trading location
Config.StockMarketLocation = {  --- Only one location is supported
    x = -819.28, y = -1278.56, z = 43.59,
}

-- Blip
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
        label = "West Elizabeth Bonds", -- Label
        price = 10.00, -- Initial price
        item = "bond1", -- Iten name from db
        priceChange = { increase = 0.33, decrease = 0.34 }, -- Price change affter each transaction
        minPrice = 0.01 -- Market will crash on this price. Helps avoid negative value
    },
    ["bond2"] = { 
        label = "New Hanover Bonds",  
        price = 10.00,
        item = "bond2",
        priceChange = { increase = 0.33, decrease = 0.34 },
        minPrice = 0.01 -- 
    },
    ["bond3"] = { 
        label = "Cornwall Co. Stocks",  --- 
        price = 10.00,
        item = "bond3",
        priceChange = { increase = 0.1, decrease = 0.11 },
        minPrice = 0.01 -- 
    }
}


Config.cooldownTime = 0.5 --- Seconds. Globar Cooldown between transactions. Increases on long db queries.

