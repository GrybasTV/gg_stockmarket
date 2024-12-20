local VorpCore = {}
local VorpInv = {}
local stockPrices = {}

TriggerEvent("getCore", function(core)
    VorpCore = core
end)

VorpInv = exports.vorp_inventory:vorp_inventoryApi()

-- Užkrauname kainas iš duomenų bazės
MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT stock_id, price FROM stocks', {}, function(results)
        for _, row in pairs(results) do
            stockPrices[row.stock_id] = row.price
        end
    end)
end)

-- Funkcija atnaujinti kainas visiems klientams
local function updatePricesForAll()
    local prices = {}
    for stockId, stock in pairs(Config.Stocks) do
        local buyPrice = stockPrices[stockId] or stock.price
        local sellPrice = math.max(stock.minPrice, buyPrice - stock.priceChange.decrease)
        prices[stockId] = { buy = buyPrice, sell = sellPrice }
    end    
    TriggerClientEvent('stockmarket:updatePrices', -1, prices)
end

-- Kainų užklausimas iš serverio
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

-- Pirkimo funkcija
local cooldowns = {} -- Bendras cooldown visiems žaidėjams

-- Funkcija patikrinti cooldown
local function isOnCooldown(playerId)
    local currentTime = GetGameTimer()
    if cooldowns[playerId] and currentTime - cooldowns[playerId] < Config.cooldownTime * 1000 then
        return true, math.ceil((Config.cooldownTime * 1000 - (currentTime - cooldowns[playerId])) / 1000)
    end
    return false, 0
end

-- Funkcija atnaujinti cooldown
local function setCooldown(playerId)
    cooldowns[playerId] = GetGameTimer()
end

-- Pirkimo funkcija
RegisterServerEvent('stockmarket:buyStock')
AddEventHandler('stockmarket:buyStock', function(stockId, amount)
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
    local playerMoney = Character.money

    local stock = Config.Stocks[stockId]
    local currentPrice = stockPrices[stockId] or stock.price
    local totalCost = 0

    for i = 1, amount do
        totalCost = totalCost + (currentPrice / 100)
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



-- Pardavimo funkcija
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
    local currentPrice = stockPrices[stockId] or stock.price
    local totalEarnings = 0

    for i = 1, amount do
        totalEarnings = totalEarnings + (currentPrice / 100)
        currentPrice = math.max(stock.minPrice, currentPrice - stock.priceChange.decrease)
    end

    if VorpInv.getItemCount(_source, stock.item) >= amount then
        Character.addCurrency(0, totalEarnings)
        VorpInv.subItem(_source, stock.item, amount)
        stockPrices[stockId] = currentPrice
        MySQL.Async.execute('UPDATE stocks SET price = @price WHERE stock_id = @id', {
            ['@price'] = currentPrice,
            ['@id'] = stockId
        })
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.sellSuccess:format(amount, stock.label, totalEarnings), "success")
        updatePricesForAll()
    else
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.notEnoughItems, "error")
    end
end)




