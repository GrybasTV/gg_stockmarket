Config = {}

-- Mygtuko kodai
Config.keys = {
    ["G"] = 0x760A9C6F -- Mygtuko kodas (G)
}

-- Prekybos vieta
Config.StockMarketLocation = {
    x = -819.28, y = -1278.56, z = 43.59,
    promptText = "Spauskite [G] prekiauti"
}

-- Blipas
BlipData = {
    blips = {
        {name = "Akciju Birža", 
        sprite = -1567930587, -- https://filmcrz.github.io/blips/
        x = Config.StockMarketLocation.x, 
        y = Config.StockMarketLocation.y, 
        z = Config.StockMarketLocation.z, 
        color = 'BLIP_MODIFIER_MP_COLOR_32'},
    }
}
-- Prekės su pradinėmis kainomis, etiketėmis, inventoriaus ID ir kainos kitimo dydžiais
Config.Stocks = {
    ["bond1"] = { 
        label = "West Elizabeth Obligacijos", -- Aprašymas: West Elizabeth Obligacijos yra paskolos vertybinis popierius kuriuo galima prekiauti biržoje ir už jos ribų.
        price = 10.00,
        item = "bond1",
        priceChange = { increase = 0.33, decrease = 0.34 }, -- 
        minPrice = 1.00 -- 
    },
    ["bond2"] = { 
        label = "New Hanover Obligacijos",  -- Aprašymas: New Hanover Obligacijos yra paskolos vertybinis popierius kuriuo galima prekiauti biržoje ir už jos ribų.
        price = 10.00,
        item = "bond2",
        priceChange = { increase = 0.33, decrease = 0.34 },
        minPrice = 1.00 -- 
    },
    ["bond3"] = { 
        label = "Cornwall Co. Akcijos",  --- Aprašymas: Cornwall Co. Akcijos yra paskolos vertybinis popierius kuriuo galima prekiauti biržoje ir už jos ribų.
        price = 10.00,
        item = "bond3",
        priceChange = { increase = 0.1, decrease = 0.11 },
        minPrice = 1.00 -- 
    }
}


-- Vertimo raktai
Config.Translations = {
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
    cooldownNotification = "Prašome palaukti %d sekundžiu"
}



Config.cooldownTime = 0.5 --- Seconds
