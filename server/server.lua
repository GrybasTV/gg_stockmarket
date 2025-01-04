local VorpCore = {}
local VorpInv = {}
local stockPrices = {}
local cooldowns = {} --  cooldown for all players

-- Initialize translations
local Translations = {}

Citizen.CreateThread(function()
    local language = Config.Language or "en"
    Translations = Config.Translations[language] or Config.Translations["en"]
    -- print("Vertimai serverio pusėje įkelti:", json.encode(Translations))
end)


setmetatable(Translations, {
    __index = function(_, key)
        local language = Config.Language or "en"
        local translation = Config.Translations[language][key] or Config.Translations["en"][key]
        if not translation then
            print(string.format("No translations for '%s' .", key))
            return key -- Grąžins raktą kaip atsarginį vertimą
        end
        return translation
    end
})

TriggerEvent("getCore", function(core)
    VorpCore = core
end)

VorpInv = exports.vorp_inventory:vorp_inventoryApi()


-- Sukurkite lentelę, jei jos nėra, ir pridėkite trūkstamus įrašus
MySQL.ready(function()
    -- Lentelės kūrimas
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS stocks (
            stock_id VARCHAR(50) PRIMARY KEY,
            price DECIMAL(10, 2) NOT NULL
        )
    ]], {})

    -- Patikrinkite ir pridėkite trūkstamus įrašus
    for stockId, stock in pairs(Config.Stocks) do
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM stocks WHERE stock_id = @stock_id', {
            ['@stock_id'] = stockId
        }, function(count)
            if count == 0 then
                MySQL.Async.execute('INSERT INTO stocks (stock_id, price) VALUES (@stock_id, @price)', {
                    ['@stock_id'] = stockId,
                    ['@price'] = stock.price
                })
            end
        end)
    end
end)



-- Load initial data if the table was created
MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT COUNT(*) AS count FROM stocks', {}, function(result)
        if result[1].count == 0 then
            for stockId, stock in pairs(Config.Stocks) do
                MySQL.Async.execute('INSERT INTO stocks (stock_id, price) VALUES (@stock_id, @price)', {
                    stock_id = stockId, price = stock.price
                })
            end
            print("[Stock Market] Pradiniai duomenys įkelti.")
        end
    end)
end)

-- Load prices from the database
MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT stock_id, price FROM stocks', {}, function(results)
        for _, row in pairs(results) do
            stockPrices[row.stock_id] = row.price
        end
    end)
end)

-- Function to update prices for all clients
local function updatePricesForAll()
    local prices = {}
    for stockId, stock in pairs(Config.Stocks) do
        local buyPrice = stockPrices[stockId] or stock.price
        local sellPrice = math.max(stock.minPrice, buyPrice - stock.priceChange.decrease)
        prices[stockId] = { buy = buyPrice, sell = sellPrice }
    end    
    TriggerClientEvent('stockmarket:updatePrices', -1, prices)
end

-- Function to check cooldown
local function isOnCooldown(playerId)
    local currentTime = GetGameTimer()
    if cooldowns[playerId] and currentTime - cooldowns[playerId] < Config.cooldownTime * 1000 then
        return true, math.ceil((Config.cooldownTime * 1000 - (currentTime - cooldowns[playerId])) / 1000)
    end
    return false, 0
end

-- Function to update cooldown
local function setCooldown(playerId)
    cooldowns[playerId] = GetGameTimer()
end

-- Tikrina, ar lentelėje yra nurodyta reikšmė
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

--Discord hook
function sendDiscordMessage(message)
    local webhookUrl = Config.webhookUrl
    if webhookUrl then
        PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({ content = message }), { ['Content-Type'] = 'application/json' })
    end
end

--- taxAmount
local function round(value, decimals)
    local multiplier = 10^(decimals or 0)
    local rounded = math.floor(value * multiplier + 0.5) / multiplier    
    return rounded
end
local function calculateTax(totalCost)
    local rawTax = totalCost * (Config.Tax / 100)    
    return round(rawTax, 2)
end

-- Request event
RegisterServerEvent('stockmarket:requestPrices')
AddEventHandler('stockmarket:requestPrices', function()
    local _source = source
    local prices = {}
    for stockId, stock in pairs(Config.Stocks) do
        local buyPrice = stockPrices[stockId] or stock.price
        local sellPrice = math.max(stock.minPrice, buyPrice - stock.priceChange.decrease)
        prices[stockId] = { buy = buyPrice, sell = sellPrice }
    end
    TriggerClientEvent('stockmarket:updatePrices', _source, prices)
end)

-- Purchase function
RegisterServerEvent('stockmarket:buyStock')
AddEventHandler('stockmarket:buyStock', function(stockId, amount, locationName)
    local _source = source

    -- General cooldown check
    local onCooldown, remainingTime = isOnCooldown(_source)
    if onCooldown then
        TriggerClientEvent('stockmarket:notify', _source, Translations.cooldownNotification:format(remainingTime), "error")
        return
    end

    -- Cooldown nustatymas
    setCooldown(_source)

    -- Patikriname, ar akcija leidžiama pasirinktoje lokacijoje
    local isStockValid = false
    for _, location in pairs(Config.StockMarketLocations) do
        if location.name == locationName and table.contains(location.stocks, stockId) then
            isStockValid = true
            break
        end
    end

    if not isStockValid then
        TriggerClientEvent('stockmarket:notify', _source, "Ši akcija neveikia šioje vietoje!", "error")
        return
    end

    -- VORP vartotojo ir pinigų informacija
    local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter -- Pataisyta
    local playerMoney = Character.money

    -- Akcijos logika
    local stock = Config.Stocks[stockId]
    local currentPrice = stockPrices[stockId] or stock.price
    local totalCost = 0

    for i = 1, amount do
        totalCost = totalCost + currentPrice
        currentPrice = currentPrice + stock.priceChange.increase
    end
        
        local taxAmount = calculateTax(totalCost)

    -- Patikriname, ar žaidėjas turi pakankamai pinigų
    if playerMoney >= (totalCost + taxAmount) then
        -- Pašaliname bendrą sumą, įskaitant mokesčius
        Character.removeCurrency(0, totalCost + taxAmount)
        stockPrices[stockId] = currentPrice -- Atnaujiname kainą
        MySQL.Async.execute('UPDATE stocks SET price = @price WHERE stock_id = @id', {
            ['@price'] = currentPrice,
            ['@id'] = stockId
        })

        VorpInv.addItem(_source, stock.item, amount) -- Pridedame akcijas į inventorių
        TriggerClientEvent('stockmarket:notify', _source, Translations.buySuccess:format(amount, stock.label, totalCost), "success")
        if taxAmount > 0 then
        TriggerClientEvent('stockmarket:notify', _source, string.format("%s: %.2f $", Translations.tax, taxAmount), "info")
        end
        updatePricesForAll() -- Atnaujiname kainas visiems klientams
        ---- discord hook
        local message = "----------\n" .. string.format("📦 %s: %s\n💰 %s: $%.2f", Translations.item, stock.label, Translations.price, totalCost)
        sendDiscordMessage(message)
    else
        TriggerClientEvent('stockmarket:notify', _source, Translations.notEnoughMoney, "error")
    end
end)



RegisterServerEvent('stockmarket:sellStock')
AddEventHandler('stockmarket:sellStock', function(stockId, amount, locationName)
    local _source = source

    -- Bendras cooldown tikrinimas
    local onCooldown, remainingTime = isOnCooldown(_source)
    if onCooldown then
        TriggerClientEvent('stockmarket:notify', _source, Translations.cooldownNotification:format(remainingTime), "error")
        return
    end

    -- Cooldown nustatymas
    setCooldown(_source)

    -- Patikriname, ar akcija galioja šioje lokacijoje
    local isStockValid = false
    for _, location in pairs(Config.StockMarketLocations) do
        if location.name == locationName and table.contains(location.stocks, stockId) then
            isStockValid = true
            break
        end
    end

    if not isStockValid then
        TriggerClientEvent('stockmarket:notify', _source, "Ši akcija neveikia šioje vietoje!", "error")
        return
    end

    -- Gauti vartotojo duomenis
    local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    local stock = Config.Stocks[stockId]
    local buyPrice = stockPrices[stockId] or stock.price
    local sellPrice = math.max(stock.minPrice, buyPrice - stock.priceChange.decrease)
    local totalEarnings = 0

    -- Apskaičiuojame pelną
    for i = 1, amount do
        totalEarnings = totalEarnings + sellPrice
        sellPrice = math.max(stock.minPrice, sellPrice - stock.priceChange.decrease)
    end
    
    local taxAmount = calculateTax(totalEarnings) 
    local totalEarningsAfterTax = totalEarnings - taxAmount

    -- Atnaujiname kainas po pardavimo
    local newBuyPrice = math.max(stock.minPrice, buyPrice - (stock.priceChange.decrease * amount))
    stockPrices[stockId] = newBuyPrice

    -- Tikriname, ar žaidėjas turi pakankamai prekių inventoriuje
    if VorpInv.getItemCount(_source, stock.item) >= amount then
        -- Pelnas žaidėjui po mokesčių ir inventoriaus atnaujinimas
        Character.addCurrency(0, totalEarningsAfterTax)
        VorpInv.subItem(_source, stock.item, amount)

        -- Atnaujiname duomenų bazę
        MySQL.Async.execute('UPDATE stocks SET price = @price WHERE stock_id = @id', {
            ['@price'] = newBuyPrice,
            ['@id'] = stockId
        })

        -- Pranešimas apie sėkmingą pardavimą
        TriggerClientEvent('stockmarket:notify', _source, Translations.sellSuccess:format(amount, stock.label, totalEarnings), "success")
        if taxAmount > 0 then
            TriggerClientEvent('stockmarket:notify', _source, string.format("%s: %.2f $", Translations.tax, taxAmount), "info")
        end
        updatePricesForAll()
        ---- discord hook
        local message = string.format("----------\n📦 %s: %s\n💰 %s: $%.2f", Translations.item, stock.label, Translations.price, totalEarnings)
        sendDiscordMessage(message)
    else
        -- Klaida, jei žaidėjas neturi pakankamai prekių
        TriggerClientEvent('stockmarket:notify', _source, Translations.notEnoughItems, "error")
    end
end)





