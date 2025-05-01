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

-- Debug Print funkcija: spausdina tik jei Config.Debug yra true
local function DebugPrint(...)
    if Config.Debug then
        print(...)
    end
end

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
local function sendSummaryToDiscord()
    local embed = {
        title = "📈 Biržos Laikmatis - Current Stock Prices",
        color = 0x00ff00, -- Pasirinkite norimą spalvą
        fields = {}
    }

    -- Pridedame kiekvieną biržos vietą
    for _, location in ipairs(Config.StockMarketLocations) do
        local lines = {}
        
        -- Surenkame kiekvienos akcijos informaciją kaip eilutę
        for _, stockId in ipairs(location.stocks) do
            local stock = Config.Stocks[stockId]
            if stock then
                local buyPrice = stockPrices[stockId] or stock.price
                local sellPrice = math.max(stock.minPrice, buyPrice - stock.priceChange.decrease)
                local buyPriceStr = string.format("$%.2f", buyPrice)
                local sellPriceStr = string.format("$%.2f", sellPrice)
                table.insert(lines, string.format("%s: %s | %s", stock.label, buyPriceStr, sellPriceStr))
            end
        end
        
        if #lines == 0 then
            lines = {"Šioje vietoje nėra prekių"}
        end
        
        -- Suskaidome eilutes į kelias dalis, kad kiekvieno lauko ilgis neviršytų 1024 simbolių
        local chunks = {}
        local currentChunk = ""
        for i, line in ipairs(lines) do
            if currentChunk == "" then
                currentChunk = line
            else
                if string.len(currentChunk) + 1 + string.len(line) <= 1024 then
                    currentChunk = currentChunk .. "\n" .. line
                else
                    table.insert(chunks, currentChunk)
                    currentChunk = line
                end
            end
        end
        if currentChunk ~= "" then
            table.insert(chunks, currentChunk)
        end
        
        -- Kiekvieną chunką įdedame į embed laukus
        for i, chunk in ipairs(chunks) do
            local fieldName = location.name
            if i > 1 then
                fieldName = fieldName .. " (toliau)"
            end
            table.insert(embed.fields, {
                name = fieldName,
                value = chunk,
                inline = false
            })
        end
    end

    -- Siunčiame embed žinutę į Discord per webhook
    if Config.discordWebhook then
        local webhookUrl = Config.webhookUrl
        if webhookUrl then
            local payload = { content = "Biržos atnaujinimas", embeds = { embed } }
            local jsonPayload = json.encode(payload)
            PerformHttpRequest(webhookUrl, 
                function(err, text, headers)
                end, 
                'POST', 
                jsonPayload, 
                { ['Content-Type'] = 'application/json' }
            )
        end
    end
end




-- Schedule periodic Discord updates
Citizen.CreateThread(function()
    while true do
        Wait(Config.DiscordUpdateInterval * 1000) -- Interval in seconds (convert to milliseconds)
        sendSummaryToDiscord()
    end
end)

-- Admin command to send a summary to Discord
RegisterCommand(Config.Discordwebhookmanualcommand, function(source, args)
    -- Check if the Discord sending feature is enabled
    if not Config.discordWebhook then
        print("^1[Stock Market]^7 Discord sending feature is disabled in the configuration.")
        return
    end
    if source == 0 then -- RCON
        print("^1[Stock Market]^7 Discord summary sent.")
    else
        local player = VorpCore.getUser(source).getUsedCharacter
        local group = player.group
        if group == "admin" then
            sendSummaryToDiscord()
            TriggerClientEvent('vorp:TipBottom', source, "Discord summary sent.", 3000)
        else
            TriggerClientEvent('vorp:TipBottom', source, "Only admins can use this command.", 3000)
        end
    end
end, false)

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

-- NUI Event Handlers for Stock Market

-- Handle stock price request from client
RegisterServerEvent('stockmarket:requestPrices')
AddEventHandler('stockmarket:requestPrices', function()
    local _source = source
    
    -- Retrieve current stock prices from database or memory
    local currentPrices = {}
    for stockId, stock in pairs(Config.Stocks) do
        currentPrices[stockId] = stock.currentPrice
    end
    
    -- Send prices back to the specific client
    TriggerClientEvent('stockmarket:sendPrices', _source, currentPrices)
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

    -- Patikriname ar žaidėjas gali panešti tiek daiktų
    local canCarry = VorpInv.canCarryItems(_source, amount) 
    if not canCarry then
        TriggerClientEvent('stockmarket:notify', _source, "Jūs negalite panešti tiek daiktų!", "error")
        return
    end

    for i = 1, amount do
        totalCost = totalCost + currentPrice
        currentPrice = currentPrice + stock.priceChange.increase
    end
        
    local taxAmount = calculateTax(totalCost)

    -- Patikriname, ar žaidėjas turi pakankamai pinigų
    if playerMoney >= (totalCost + taxAmount) then
        Character.removeCurrency(0, totalCost + taxAmount)
        stockPrices[stockId] = currentPrice
        MySQL.Async.execute('UPDATE stocks SET price = @price WHERE stock_id = @id', {
            ['@price'] = currentPrice,
            ['@id'] = stockId
        })

        VorpInv.addItem(_source, stock.item, amount)
        
        -- Formuojame vieną bendrą pranešimą
        local buyMessage = string.format("Pirkote %dx %s už $%.2f (Tax: $%.2f)", amount, stock.label, totalCost, taxAmount)
        
        -- Debug: spausdiname pranešimą į konsolę
        DebugPrint("^2[DEBUG] Buy message:^7", buyMessage)
        
        -- Siunčiame vieną bendrą pranešimą
        TriggerClientEvent('stockmarket:notify', _source, buyMessage, "success")
        
        updatePricesForAll()
    else
        TriggerClientEvent('stockmarket:notify', _source, Translations.notEnoughMoney, "error")
    end
end)



RegisterServerEvent('stockmarket:sellStock')
AddEventHandler('stockmarket:sellStock', function(stockId, amount, locationName)
    local _source = source

    -- Tikriname cooldown
    local onCooldown, remainingTime = isOnCooldown(_source)
    if onCooldown then
        TriggerClientEvent('stockmarket:notify', _source, Translations.cooldownNotification:format(remainingTime), "error")
        return
    end

    setCooldown(_source)

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

    local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    local stock = Config.Stocks[stockId]

    if VorpInv.getItemCount(_source, stock.item) < amount then
        TriggerClientEvent('stockmarket:notify', _source, Translations.notEnoughItems, "error")
        return
    end

    -- Gauname daikto degradaciją ir skaičiuojame kainą
    GetItemDegradation(stock.item, _source, function(currentDegradation)
        DebugPrint("^2[DEBUG] Final degradation value:^7", currentDegradation)
        DebugPrint("^2[DEBUG] Stock item:^7", stock.item)
        DebugPrint("^2[DEBUG] Base price:^7", stockPrices[stockId] or stock.price)
        
        local basePrice = stockPrices[stockId] or stock.price
        local priceWithDecay = CalculatePriceWithDecay(basePrice, currentDegradation)
        local totalEarnings = priceWithDecay * amount
        
        local taxAmount = calculateTax(totalEarnings)
        local finalEarnings = totalEarnings - taxAmount

        VorpInv.subItem(_source, stock.item, amount)
        Character.addCurrency(0, finalEarnings)

        local newPrice = math.max(stock.minPrice, basePrice - (stock.priceChange.decrease * amount))
        stockPrices[stockId] = newPrice
        
        MySQL.Async.execute('UPDATE stocks SET price = @price WHERE stock_id = @id', {
            ['@price'] = newPrice,
            ['@id'] = stockId
        })

        -- Formuojame vieną bendrą pranešimą
        local saleMessage = ""
        if currentDegradation and currentDegradation < 100 then
            saleMessage = string.format("Pardavete %dx %s už $%.2f (Tax: $%.2f)", amount, stock.label, finalEarnings, taxAmount)
            saleMessage = saleMessage .. string.format("\nDaikto bukle: %d%%", currentDegradation)
            saleMessage = saleMessage .. string.format("\nPilna kaina butu: $%.2f", basePrice * amount)
        else
            saleMessage = string.format("Pardavete %dx %s už $%.2f (Tax: $%.2f)", amount, stock.label, finalEarnings, taxAmount)
        end

        -- Siunčiame vieną bendrą pranešimą
        TriggerClientEvent('stockmarket:notify', _source, saleMessage, "success")

        -- Discord pranešimas su detalesne informacija
        local description = string.format(
            "Player sold %dx %s for $%.2f\nBase price: $%.2f\nTax: $%.2f\nCondition: %.1f%%\nLocation: %s", 
            amount, 
            stock.label, 
            finalEarnings,
            basePrice * amount,
            taxAmount,
            currentDegradation,
            locationName
        )
        sendToDiscord("Stock Market - Sale", description, 15158332, true)

        updatePricesForAll()
    end)
end)
