local VorpCore = {}
local VorpInv = {}
local stockPrices = {}
local cooldowns = {} --  cooldown for all players

-- Translations
local language = Config.Language or "en"
if Config.Translations[language] then
    Config.Translations = Config.Translations[language]
else
    print("Language not found. Defaulting to English.")
    Config.Translations = Config.Translations["en"]
end

TriggerEvent("getCore", function(core)
    VorpCore = core
end)

VorpInv = exports.vorp_inventory:vorp_inventoryApi()

-- Create the database table if it does not exist
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS stocks (
            stock_id VARCHAR(50) PRIMARY KEY,
            price DECIMAL(10, 2) NOT NULL
        )
    ]], {})
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

-- Purchase function
RegisterServerEvent('stockmarket:buyStock')
AddEventHandler('stockmarket:buyStock', function(stockId, amount)
    local _source = source

    -- General cooldown check
    local onCooldown, remainingTime = isOnCooldown(_source)
    if onCooldown then
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.cooldownNotification:format(remainingTime), "error")
        return
    end

    -- Cooldown nustatymas
    setCooldown(_source)

    local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    local playerMoney = Character.money

    local stock = Config.Stocks[stockId]
    local currentPrice = stockPrices[stockId] or stock.price
    local totalCost = 0

    for i = 1, amount do
        totalCost = totalCost + currentPrice
        currentPrice = currentPrice + stock.priceChange.increase
    end

    if playerMoney >= totalCost then
        Character.removeCurrency(0, totalCost)
        stockPrices[stockId] = currentPrice
        MySQL.Async.execute('UPDATE stocks SET price = @price WHERE stock_id = @id', {
            ['@price'] = currentPrice,
            ['@id'] = stockId
        })
        VorpInv.addItem(_source, stock.item, amount)
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.buySuccess:format(amount, stock.label, totalCost), "success")
        updatePricesForAll()
    else
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.notEnoughMoney, "error")
    end
end)


-- Sell function
RegisterServerEvent('stockmarket:sellStock')
AddEventHandler('stockmarket:sellStock', function(stockId, amount)
    local _source = source

    -- Bendras cooldown tikrinimas
    local onCooldown, remainingTime = isOnCooldown(_source)
    if onCooldown then
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.cooldownNotification:format(remainingTime), "error")
        return
    end

    -- Cooldown nustatymas
    setCooldown(_source)

    local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter

    local stock = Config.Stocks[stockId]
    local buyPrice = stockPrices[stockId] or stock.price
    local sellPrice = math.max(stock.minPrice, buyPrice - stock.priceChange.decrease)
    local totalEarnings = 0

    for i = 1, amount do
        totalEarnings = totalEarnings + sellPrice
        sellPrice = math.max(stock.minPrice, sellPrice - stock.priceChange.decrease)
    end

    -- Update buyPrice after selling
    local newBuyPrice = math.max(stock.minPrice, buyPrice - (stock.priceChange.decrease * amount))
    stockPrices[stockId] = newBuyPrice

    if VorpInv.getItemCount(_source, stock.item) >= amount then
        Character.addCurrency(0, totalEarnings)
        VorpInv.subItem(_source, stock.item, amount)
        MySQL.Async.execute('UPDATE stocks SET price = @price WHERE stock_id = @id', {
            ['@price'] = newBuyPrice,
            ['@id'] = stockId
        })
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.sellSuccess:format(amount, stock.label, totalEarnings), "success")
        updatePricesForAll()
    else
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.notEnoughItems, "error")
    end
end)




