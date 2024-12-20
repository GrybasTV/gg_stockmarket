
local currentStockPrices = {}
local MenuData = {}
local initBlips = {}

-- Translations
local language = Config.Language or "en"
if Config.Translations[language] then
    Config.Translations = Config.Translations[language]
else
    print("Language not found. Defaulting to English.")
    Config.Translations = Config.Translations["en"]
end

-- VORP Core ir Menu API inicijavimas
TriggerEvent("getCore", function(core)
    VORPcore = core
end)

-- Menu API
TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)

-- Notification system
RegisterNetEvent('stockmarket:notify')
AddEventHandler('stockmarket:notify', function(message, messageType)
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
    local location = Config.StockMarketLocation
    local text = Config.Translations.promptText

    for stockId, stock in pairs(Config.Stocks) do
        local prices = currentStockPrices[stockId] or { buy = stock.price, sell = stock.price }
        text = text .. string.format("\n%s: $%.2f/ $%.2f", stock.label, prices.buy, prices.sell)
    end

    DrawText3D(location.x, location.y, location.z + 0.25, text)
end

-- Function to open the menu with a new price request
local function openStockMarketMenu()
    requestPricesFromServer() -- Užklausiame naujausias kainas tik atidarant meniu
    Citizen.Wait(100) -- Nedidelis laukimas, kad kainos būtų atnaujintos

    local elements = {}
    for stockId, stock in pairs(Config.Stocks) do
        table.insert(elements, { label = string.format(Config.Translations.buyOption, stock.label), value = "buy_" .. stockId })
        table.insert(elements, { label = string.format(Config.Translations.sellOption, stock.label), value = "sell_" .. stockId })
    end

    MenuData.Open('default', GetCurrentResourceName(), 'stock_menu', {
        title = Config.Translations.menuTitle,
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value:find("buy_") then
            TriggerServerEvent('stockmarket:buyStock', data.current.value:gsub("buy_", ""), 1)
        elseif data.current.value:find("sell_") then
            TriggerServerEvent('stockmarket:sellStock', data.current.value:gsub("sell_", ""), 1)
        end
    end, function(data, menu)
        menu.close()
        freezePlayer(false)
    end)
end

-- Main thread
Citizen.CreateThread(function()
    local location = Config.StockMarketLocation

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = Vdist(playerCoords, location.x, location.y, location.z)

        if distance < 2.0 then
            displayPromptWithPrices()
            if IsControlJustReleased(0, Config.keys["G"]) then
                freezePlayer(true)
                openStockMarketMenu()
            end
            Citizen.Wait(0) -- Tikriname dažniau, kai žaidėjas arti
        else
            Citizen.Wait(500) -- Ilgesnis laukimas, kai žaidėjas toli
        end
    end
end)



-- Creating blips
Citizen.CreateThread(function()    
    for _, data in pairs(BlipData.blips) do
        local blipId = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, data.x, data.y, data.z)
        SetBlipSprite(blipId, data.sprite, 1)
        Citizen.InvokeNative(0x662D364ABF16DE2F, blipId, data.color or 0)
        local varString = CreateVarString(10, 'LITERAL_STRING', data.name)
        Citizen.InvokeNative(0x9CB1A1623062F402, blipId, varString)
        table.insert(initBlips, blipId)
    end
end)

-- Removing blips when the resource stops
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, blip in pairs(initBlips) do
            RemoveBlip(blip)
        end
    end
end)
