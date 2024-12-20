local VorpCore = {}
local VorpInv = {}

TriggerEvent("getCore", function(core)
    VorpCore = core
end)

VorpInv = exports.vorp_inventory:vorp_inventoryApi()

-- Prekių kainos (užkraunamos iš DB arba Config)
local stockPrices = {}

MySQL.ready(function()
    -- Tikriname ir pridedame trūkstamas prekes į DB
    for stockId, stock in pairs(Config.Stocks) do
        MySQL.Async.fetchScalar('SELECT price FROM stocks WHERE stock_id = @id', { ['@id'] = stockId }, function(price)
            if not price then
                MySQL.Async.execute('INSERT INTO stocks (stock_id, price) VALUES (@id, @price)', {
                    ['@id'] = stockId,
                    ['@price'] = stock.price
                })
                stockPrices[stockId] = stock.price
            else
                stockPrices[stockId] = price
            end
        end)
    end
end)

-- Pirkimo funkcija
RegisterServerEvent('stockmarket:buyStock')
AddEventHandler('stockmarket:buyStock', function(stockId, amount)
    local _source = source
    local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    local playerMoney = Character.money

    local stock = Config.Stocks[stockId]
    if not stock then
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.itemNotFound, "error")
        return
    end

    -- Iš DB per naujo patikriname kainą, kad įsitikinti, ar ji nepasikeitė
    MySQL.Async.fetchScalar('SELECT price FROM stocks WHERE stock_id = @id', {
        ['@id'] = stockId
    }, function(dbPrice)
        if not dbPrice then
            TriggerClientEvent('stockmarket:notify', _source, Config.Translations.itemNotFound, "error")
            return
        end

        local currentPrice = dbPrice -- Paimame kainą tiesiai iš DB, o ne iš cache
        local totalCost = 0

        -- Perskaičiuojame galutinę kainą naudojant esamą kainą iš DB
        for i = 1, amount do
            totalCost = totalCost + (currentPrice / 100)
            currentPrice = currentPrice + stock.priceChange.increase
        end

        if playerMoney >= totalCost then
            -- Jeigu žaidėjas turi pakankamai pinigų, atnaujiname duomenų bazę ir suteikiame prekes
            Character.removeCurrency(0, totalCost)

            -- Atnaujiname naują kainą DB ir cache
            MySQL.Async.execute('UPDATE stocks SET price = @price WHERE stock_id = @id', {
                ['@price'] = currentPrice,
                ['@id'] = stockId
            })
            stockPrices[stockId] = currentPrice

            for i = 1, amount do
                VorpInv.addItem(_source, stock.item, 1)
            end

            TriggerClientEvent('stockmarket:notify', _source, string.format("Pirkote %d %s už $%.2f", amount, stock.label, totalCost), "success")
        else
            TriggerClientEvent('stockmarket:notify', _source, Config.Translations.notEnoughMoney, "error")
        end
    end)
end)


-- Pardavimo funkcija
RegisterServerEvent('stockmarket:sellStock')
AddEventHandler('stockmarket:sellStock', function(stockId, amount)
    local _source = source
    local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter

    local stock = Config.Stocks[stockId]
    if not stock then
        TriggerClientEvent('stockmarket:notify', _source, Config.Translations.itemNotFound, "error")
        return
    end

    -- Patikriname kainą iš DB
    MySQL.Async.fetchScalar('SELECT price FROM stocks WHERE stock_id = @id', {
        ['@id'] = stockId
    }, function(dbPrice)
        if not dbPrice then
            TriggerClientEvent('stockmarket:notify', _source, Config.Translations.itemNotFound, "error")
            return
        end

        local currentPrice = dbPrice
        local totalEarnings = 0

        -- Patikriname, ar žaidėjas turi pakankamai prekių
        local count = VorpInv.getItemCount(_source, stock.item)
        if count < amount then
            TriggerClientEvent('stockmarket:notify', _source, Config.Translations.notEnoughItems, "error")
            return
        end

        for i = 1, amount do
            if (currentPrice - stock.priceChange.decrease) < stock.minPrice then
                TriggerClientEvent('stockmarket:notify', _source, Config.Translations.priceTooLow, "error")
                return
            end
            totalEarnings = totalEarnings + (currentPrice / 100)
            currentPrice = currentPrice - stock.priceChange.decrease
        end

        -- Atnaujiname kainą DB ir cache
        MySQL.Async.execute('UPDATE stocks SET price = @price WHERE stock_id = @id', {
            ['@price'] = currentPrice,
            ['@id'] = stockId
        })
        stockPrices[stockId] = currentPrice

        -- Pašaliname prekes
        VorpInv.subItem(_source, stock.item, amount)

        -- Pridedame pinigus
        Character.addCurrency(0, totalEarnings)
        TriggerClientEvent('stockmarket:notify', _source, string.format(Config.Translations.sellSuccess, amount, stock.label, totalEarnings), "success")
    end)
end)

