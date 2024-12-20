local VORPcore = {}

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)

local promptActive = false
local showingPrompt = false
local isMenuOpen = false

-- Užšaldo arba atšaldo žaidėją
local function freezePlayer(toggle)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, toggle)
    SetEntityInvincible(playerPed, toggle) -- Užtikriname, kad žaidėjas nebūtų sužeistas
    SetPlayerInvincible(PlayerId(), toggle)
    if toggle then
        SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true) -- Atimame ginklus, kad nebūtų šaudymo
        ClearPedTasks(playerPed) -- Atšaukime visas esamas enimacijas
    end
end

-- Funkcija rodyti 3D tekstą
local function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
    local px,py,pz=table.unpack(GetGameplayCamCoord())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        SetTextColor(255, 255, 255, 215)
        SetTextCentre(1)
        DisplayText(CreateVarString(10, "LITERAL_STRING", text), _x,_y)
        local factor = (string.len(text)) / 225
        DrawSprite("feeds", "hud_menu_4a", _x,_y+0.0125,0.015+ factor, 0.03, 0.1, 35, 35, 35, 190, 0)
    end
end

-- Funkcija rodyti prompt tekstą
local function displayPrompt(text)
    showingPrompt = true
    Citizen.CreateThread(function()
        while showingPrompt do
            Citizen.Wait(0)
            DrawText3D(Config.StockMarketLocation.x, Config.StockMarketLocation.y, Config.StockMarketLocation.z + 0.25, text)
        end
    end)
end

-- Funkcija išvalyti prompt tekstą
local function clearPrompt()
    showingPrompt = false
end

-- 
Citizen.CreateThread(function()
    local location = Config.StockMarketLocation

    while true do
        Citizen.Wait(0)

        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = Vdist(playerCoords, location.x, location.y, location.z)

        if distance < 2.0 then
            if not promptActive then
                promptActive = true
                displayPrompt(location.promptText)
            end

            if IsControlJustReleased(0, Config.keys["G"]) then -- 0x760A9C6F = "G"
                if not isMenuOpen then
                    isMenuOpen = true
                    freezePlayer(true) -- Užšaldome žaidėją
                    MenuData.CloseAll()
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
                            local stockId = data.current.value:gsub("buy_", "")
                            TriggerServerEvent('stockmarket:buyStock', stockId, 1)
                        elseif data.current.value:find("sell_") then
                            local stockId = data.current.value:gsub("sell_", "")
                            TriggerServerEvent('stockmarket:sellStock', stockId, 1)
                        end
                    end, function(data, menu)
                        menu.close()
                        isMenuOpen = false
                        freezePlayer(false) -- Atšildome žaidėją
                    end)
                end
            end
        elseif distance >= 2.0 and promptActive then
            promptActive = false
            clearPrompt()
        end
    end
end)


-- Sukuriamas blipas

local initBlips = {}
Citizen.CreateThread(
	function()
		for _, data in pairs(BlipData.blips) do
			local blipId = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, data.x, data.y, data.z)
			SetBlipSprite(blipId, data.sprite, 1);
			Citizen.InvokeNative(0x662D364ABF16DE2F, blipId, data.color or 0);
			local varString = CreateVarString(10, 'LITERAL_STRING', data.name);
			Citizen.InvokeNative(0x9CB1A1623062F402, blipId, varString)
			table.insert(initBlips, blipId)
		end
	end
)
AddEventHandler(
	"onResourceStop",
	function(resourceName)
		if resourceName == GetCurrentResourceName() then
			for _, blip in pairs(initBlips) do
				RemoveBlip(blip)
			end
		end
	end
)




-- Kliento pranešimų sistema
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
