
local currentStockPrices = {}
local MenuData = {}
local blips = {}

-- VORP Core ir Menu API inicijavimas
TriggerEvent("getCore", function(core)
    VORPcore = core
end)

-- Menu API
TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)

-- Vertimai

Citizen.CreateThread(function()
    local language = Config.Language or "en"
    if Config.Translations[language] then
        for k, v in pairs(Config.Translations[language]) do
            Config.Translations[k] = v
        end
    else
        print("Language not found. Defaulting to English.")
        for k, v in pairs(Config.Translations["en"]) do
            Config.Translations[k] = v
        end
    end
end)

-- Notification system

RegisterNetEvent('stockmarket:notify')
AddEventHandler('stockmarket:notify', function(message, messageType)
    local _source = source
    VorpCore = VORPcore
    if messageType == "success" then
        TriggerEvent('vorp:TipRight', message, 5000)
    elseif messageType == "error" then        
        TriggerEvent('vorp:TipRight', message, 5000)
    else
        TriggerEvent('vorp:TipRight', message, 5000)
    end
end)

-- Gauti kainas iš serverio
RegisterNetEvent('stockmarket:updatePrices')
AddEventHandler('stockmarket:updatePrices', function(prices)
    currentStockPrices = prices
end)

-- Function to freeze player
local function freezePlayer(toggle)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, toggle)
    SetEntityInvincible(playerPed, toggle)
    SetPlayerInvincible(PlayerId(), toggle)
    if toggle then
        SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
        ClearPedTasks(playerPed)
    end
end

local function requestPricesFromServer()
    TriggerServerEvent('stockmarket:requestPrices')
end

-- Function to display 3D text
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        SetTextColor(255, 255, 255, 215)
        SetTextCentre(1)
        DisplayText(CreateVarString(10, "LITERAL_STRING", text), _x, _y)
    end
end

-- Function to display prices from the current table
local function displayPromptWithPrices()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestLocation = nil
    local closestDistance = nil

    -- Randame artimiausią lokaciją
    for _, location in pairs(Config.StockMarketLocations) do
        local distance = Vdist(playerCoords, location.x, location.y, location.z)
        if not closestDistance or distance < closestDistance then
            closestDistance = distance
            closestLocation = location
        end
    end

    -- Jei artimiausia lokacija yra pakankamai arti, rodome prompt su tam tikromis akcijomis
    if closestLocation and closestDistance < 2.0 then
        local text = Config.Translations.promptText
        for _, stockId in pairs(closestLocation.stocks) do
            local stock = Config.Stocks[stockId]
            if stock then
                local prices = currentStockPrices[stockId] or { buy = stock.price, sell = stock.price }
                text = text .. string.format("\n%s: $%.2f/ $%.2f", stock.label, prices.buy, prices.sell)
            end
        end
        DrawText3D(closestLocation.x, closestLocation.y, closestLocation.z + 0.25, text)
    end
end



-- Function to open the menu with a new price request
local function openStockMarketMenu(location)
    requestPricesFromServer() -- Užklausiame kainų iš serverio
    Citizen.Wait(100) -- Nedidelis laukimas

    local elements = {}
    for _, stockId in pairs(location.stocks) do
        local stock = Config.Stocks[stockId]
        if stock then
            table.insert(elements, { label = string.format(Config.Translations.buyOption, stock.label), value = "buy_" .. stockId })
            table.insert(elements, { label = string.format(Config.Translations.sellOption, stock.label), value = "sell_" .. stockId })
        end
    end

    MenuData.Open('default', GetCurrentResourceName(), 'stock_menu', {
        title = Config.Translations.menuTitle,
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value:find("buy_") then
            TriggerServerEvent('stockmarket:buyStock', data.current.value:gsub("buy_", ""), 1, location.name)
        elseif data.current.value:find("sell_") then
            TriggerServerEvent('stockmarket:sellStock', data.current.value:gsub("sell_", ""), 1, location.name)
        end
    end, function(data, menu)
        menu.close()
        freezePlayer(false)
    end)
end


-- Main thread
Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local isNearLocation = false

        for _, location in pairs(Config.StockMarketLocations) do
            local distance = Vdist(playerCoords, location.x, location.y, location.z)

            if distance < 2.0 then
                displayPromptWithPrices(location) -- Parodome 3D tekstą
                if IsControlJustReleased(0, Config.keys["G"]) then
                    freezePlayer(true)
                    openStockMarketMenu(location) -- Perdavimo lokacija į meniu atidarymą
                end
                isNearLocation = true
                Citizen.Wait(0) -- Dažnas tikrinimas, kai arti
                break
            end
        end

        if not isNearLocation then
            Citizen.Wait(1000) -- Retesnis tikrinimas, kai toli
        end
    end
end)




-- Creating blips
Citizen.CreateThread(function()
    for _, location in pairs(Config.StockMarketLocations) do
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, location.x, location.y, location.z) -- Blip handle
        SetBlipSprite(blip, Config.Blip.sprite, 1) -- Ikona
        SetBlipScale(blip, 1.0) -- Blip size
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, location.name) -- Nustatome pavadinimą
        Citizen.InvokeNative(0x662D364ABF16DE2F, blip, Config.Blip.color) -- Spalva
        table.insert(blips, blip)
    end
end)


-- Removing blips when the resource stops
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, blip in pairs(blips) do
            RemoveBlip(blip)
        end
    end
end)
