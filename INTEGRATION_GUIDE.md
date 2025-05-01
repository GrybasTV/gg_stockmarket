# Kaip Naudoti `vorp_inventory` UI Kitų Skriptų Poreikiams

Šis dokumentas aprašo, kaip kiti RedM resursai (skriptai), pavyzdžiui, akcijų biržos (`gg_stockmarket`), gali tiesiogiai naudoti `vorp_inventory` teikiamą parduotuvės vartotojo sąsają (UI), kad atvaizduotų savo duomenis (pvz., akcijas kaip prekes su pirkimo/pardavimo kainomis), nekeičiant `vorp_inventory` kodo ir nebandant integruotis su `syn_stores`.

**Tikslas:** Tik atvaizduoti duomenis standartinėje `vorp_inventory` pirkimo/pardavimo sąsajoje. Visa pirkimo/pardavimo **logika** lieka jūsų originaliame skripte.

## Pagrindinis Principas

1.  **Klientas Inicijuoja:** Kai žaidėjas aktyvuoja jūsų funkciją (pvz., prieina prie akcijų brokerio), kliento skriptas išsiunčia įvykį į *jūsų pačių* serverio skriptą.
2.  **Jūsų Serveris Ruošia Duomenis:** Jūsų serverio skriptas, gavęs įvykį:
    *   Surenka visus reikiamus duomenis (pvz., akcijų sąrašą, dabartines pirkimo/pardavimo kainas).
    *   Formatuoja šiuos duomenis į specialią lentelę (`shopData`), kurios tikisi `vorp_inventory`.
    *   Tiesiogiai iškviečia `exports.vorp_inventory:openInventory(source, 'shop', shopData)`, nurodydamas žaidėją (`source`) ir paruoštus duomenis.
3.  **`vorp_inventory` Rodo UI:** `vorp_inventory` atidaro žaidėjui standartinę parduotuvės sąsają, rodydamas jūsų pateiktus `buyItems` (parduodamos prekės žaidėjui) ir `sellItems` (perkamos prekės iš žaidėjo).
4.  **Jūsų Serveris Tvarko Veiksmus:** Kai žaidėjas UI paspaudžia "Pirkti" ar "Parduoti":
    *   `vorp_inventory` (tikėtina) išsiunčia standartinį serverio įvykį atgal *jūsų skriptui* (pvz., `inventory:shopBuyItem` arba `inventory:shopSellItem`), perduodamas prekės pavadinimą ir kiekį.
    *   Jūsų serverio skriptas turi klausyti šių įvykių.
    *   Gavęs tokį įvykį, jūsų skriptas **vykdo savo specifinę logiką** (pvz., kviečia `stockmarket:buyStock` ar `stockmarket:sellStock` vidinę funkciją ar logiką).

## Diegimas (Pvz., `gg_stockmarket` Adaptavimas)

Šie žingsniai rodo, kaip adaptuoti `gg_stockmarket`, kad jis naudotų `vorp_inventory` UI tiesiogiai.

**1. `gg_stockmarket` Kliento Pakeitimai (`client.lua`):**

Modifikuokite funkciją, kuri atidaro meniu (pvz., `openStockMarketMenu`). Vietoj `MenuData.Open`, ji dabar turi siųsti įvykį į *jūsų* serverį:

```lua
-- client.lua

local function openStockMarketMenu(location)
    -- Nebereikia kviesti requestPricesFromServer() čia
    -- Nebereikia MenuData.Open

    -- Tiesiog pranešame serveriui, kad reikia atidaryti UI šiai lokacijai
    TriggerServerEvent('gg_stockmarket:server_openStockUI', location.name) -- Perduodame lokacijos pavadinimą

    -- freezePlayer(true) turėtų būti kviečiamas prieš TriggerServerEvent
    -- freezePlayer(false) turės būti valdomas kai inventorius uždaromas (žr. žemiau)
end

-- Reikia klausyti inventoriaus uždarymo įvykio, kad atšaldytume žaidėją
-- (Pavadinimas gali skirtis priklausomai nuo jūsų inventoriaus)
AddEventHandler("syn:closeinv", function()
    -- Įsitikinkite, kad atšaldoma tik tada, kai buvo atidarytas būtent akcijų UI
    -- (Gali prireikti papildomos būsenos kintamojo)
    freezePlayer(false)
end)
-- Arba jei naudojate standartinį vorp_inventory:
-- AddEventHandler("vorp_inventory:inventory_closed", function()
--    freezePlayer(false)
-- end)
```

**2. `gg_stockmarket` Serverio Pakeitimai (`server.lua`):**

*   **Pridėkite Naują Įvykio Klausytoją:** Sukurkite funkciją, kuri reaguos į kliento įvykį, paruoš duomenis ir iškvies `vorp_inventory`.
*   **Pridėkite `vorp_inventory` Atsakomųjų Įvykių Klausytojus:** Pridėkite klausytojus standartiniams `vorp_inventory` įvykiams (`inventory:shopBuyItem`, `inventory:shopSellItem`).
*   **(Pasirinktinai) Refaktoruokite Logiką:** Gali būti patogiau dabartinę `stockmarket:buyStock` ir `stockmarket:sellStock` įvykių logiką perkelti į atskiras funkcijas, kad jas būtų galima kviesti tiek iš senųjų įvykių (jei norite juos palikti), tiek iš naujųjų `vorp_inventory` atsakomųjų įvykių klausytojų.

```lua
-- server.lua

-- Įsitikinkite, kad VorpInv yra inicializuotas
-- VorpInv = exports.vorp_inventory:vorp_inventoryApi()

-- Funkcija, kuri paruošia ir atidaro UI per vorp_inventory
RegisterNetEvent('gg_stockmarket:server_openStockUI')
AddEventHandler('gg_stockmarket:server_openStockUI', function(locationName)
    local _source = source
    local User = VorpCore.getUser(_source)
    if not User then return end

    -- Raskite lokacijos konfigūraciją
    local locationConfig = nil
    for _, loc in pairs(Config.StockMarketLocations) do
        if loc.name == locationName then
            locationConfig = loc
            break
        end
    end

    if not locationConfig then
        print("[Stock Market] Nerasta lokacijos konfigūracija: " .. locationName)
        return
    end

    -- Paruošiame prekių sąrašus vorp_inventory formatu
    local buyItemsList = {}  -- Prekės, kurias žaidėjas gali PARDUOTI (rodomos dešinėje)
    local sellItemsList = {} -- Prekės, kurias žaidėjas gali PIRKTI (rodomos kairėje)

    for _, stockId in pairs(locationConfig.stocks) do
        local stockConfig = Config.Stocks[stockId]
        local currentPrice = stockPrices[stockId] or stockConfig.price -- Gauname dabartinę kainą

        if stockConfig then
            local buyPrice = currentPrice -- Kaina, už kurią žaidėjas PERKA
            local sellPrice = math.max(stockConfig.minPrice, currentPrice - stockConfig.priceChange.decrease) -- Kaina, už kurią žaidėjas PARDUODA

            -- Prekė PIRKIMUI (sellItems, rodoma kairėje)
            table.insert(sellItemsList, {
                name = stockConfig.item,      -- Akciją reprezentuojantis daiktas
                label = stockConfig.label,    -- Pavadinimas
                price = buyPrice,           -- Pirkimo kaina
                type = "item_standard",       -- Tipas
                weight = 0,                 -- Svoris (jei reikia)
                description = "",            -- Aprašymas (jei reikia)
                metadata = {}               -- Meta duomenys (jei reikia)
                -- Kiekis čia nenurodomas, vorp_inventory paprastai leidžia pasirinkti
            })

            -- Prekė PARDAVIMUI (buyItems, rodoma dešinėje)
            table.insert(buyItemsList, {
                name = stockConfig.item,      -- Akciją reprezentuojantis daiktas
                label = stockConfig.label,    -- Pavadinimas
                price = sellPrice,          -- PARDAVIMO kaina
                type = "item_standard",
                weight = 0,
                description = "",
                metadata = {}
                -- Kiekis čia nenurodomas
            })
        end
    end

    -- Sukuriame shopData lentelę
    local shopData = {
        shopName = locationName, -- Parduotuvės pavadinimas UI
        buyItems = buyItemsList,  -- Prekės, kurias parduotuvė perka (rodomos dešinėje)
        sellItems = sellItemsList -- Prekės, kurias parduotuvė parduoda (rodomos kairėje)
        -- Galimi papildomi parametrai priklausomai nuo vorp_inventory versijos
    }

    -- Atidarome inventorių
    -- Svarbu: 'shop' tipas nurodo vorp_inventory naudoti pirkimo/pardavimo sąsają
    exports.vorp_inventory:openInventory(_source, 'shop', shopData)
end)

-- Klausome vorp_inventory atsakomųjų įvykių

-- Tikėtinas įvykis, kai žaidėjas UI paspaudžia PIRKTI
-- Pastaba: Tikslus įvykio pavadinimas gali skirtis! Patikrinkite savo vorp_inventory versiją.
RegisterNetEvent('inventory:shopBuyItem')
AddEventHandler('inventory:shopBuyItem', function(itemName, amount)
    local _source = source
    DebugPrint(string.format("[Stock Market] UI Buy Triggered: Player %s, Item: %s, Amount: %s", _source, itemName, amount))

    -- Raskite akcijos ID pagal daikto pavadinimą (itemName)
    local stockId = nil
    local locationName = nil -- Reikia būdo gauti lokacijos pavadinimą (galbūt iš žaidėjo būsenos)
    for id, stockCfg in pairs(Config.Stocks) do
        if stockCfg.item == itemName then
            stockId = id
            break
        end
    end

    if stockId and locationName then
        -- Kviečiame savo originalią pirkimo logiką (arba refaktoruotą funkciją)
        -- Pastaba: Perduodame 'amount', kurį grąžino vorp_inventory
        -- Reikia locationName, kurį reikės gauti (galbūt iš kliento būsenos prieš atidarant UI)
        ExecuteStockBuyLogic(_source, stockId, amount, locationName) -- Sukurkite šią funkciją iš esamos logikos
    else
        print(string.format("[Stock Market] Klaida: Nerastas stockId pagal item '%s' arba negauta lokacija pirkimui.", itemName))
    end
end)

-- Tikėtinas įvykis, kai žaidėjas UI paspaudžia PARDUOTI
-- Pastaba: Tikslus įvykio pavadinimas gali skirtis! Patikrinkite savo vorp_inventory versiją.
RegisterNetEvent('inventory:shopSellItem')
AddEventHandler('inventory:shopSellItem', function(itemName, amount)
    local _source = source
    DebugPrint(string.format("[Stock Market] UI Sell Triggered: Player %s, Item: %s, Amount: %s", _source, itemName, amount))

    -- Raskite akcijos ID pagal daikto pavadinimą (itemName)
    local stockId = nil
    local locationName = nil -- Reikia būdo gauti lokacijos pavadinimą
    for id, stockCfg in pairs(Config.Stocks) do
        if stockCfg.item == itemName then
            stockId = id
            break
        end
    end

    if stockId and locationName then
        -- Kviečiame savo originalią pardavimo logiką (arba refaktoruotą funkciją)
        -- Pastaba: Perduodame 'amount', kurį grąžino vorp_inventory
        ExecuteStockSellLogic(_source, stockId, amount, locationName) -- Sukurkite šią funkciją iš esamos logikos
    else
        print(string.format("[Stock Market] Klaida: Nerastas stockId pagal item '%s' arba negauta lokacija pardavimui.", itemName))
    end
end)

-- (Refaktoruotos logikos pavyzdys)
function ExecuteStockBuyLogic(source, stockId, amount, locationName)
    -- Čia įdėkite logiką iš RegisterNetEvent('stockmarket:buyStock')
    -- ... patikrinimai, kainos skaičiavimas, mokesčiai ...
    -- Character.removeCurrency(...)
    -- VorpInv.addItem(...)
    -- TriggerClientEvent('stockmarket:notify', ...)
    -- ... etc ...
end

function ExecuteStockSellLogic(source, stockId, amount, locationName)
    -- Čia įdėkite logiką iš RegisterNetEvent('stockmarket:sellStock')
    -- ... patikrinimai, būklės tikrinimas (GetItemDegradation) ...
    -- Character.addCurrency(...)
    -- VorpInv.subItem(...)
    -- TriggerClientEvent('stockmarket:notify', ...)
    -- ... etc ...
end

-- Palikite senus įvykius (pasirinktinai), jei norite juos naudoti kitur
-- RegisterNetEvent('stockmarket:buyStock')
-- AddEventHandler('stockmarket:buyStock', function(stockId, amount, locationName)
--    ExecuteStockBuyLogic(source, stockId, amount, locationName)
-- end)
-- RegisterNetEvent('stockmarket:sellStock')
-- AddEventHandler('stockmarket:sellStock', function(stockId, amount, locationName)
--    ExecuteStockSellLogic(source, stockId, amount, locationName)
-- end)

```

**Svarbios Pastabos:**

*   **`vorp_inventory` Atsakomieji Įvykiai:** **Būtinai patikrinkite**, kokius tiksliai serverio įvykius (`RegisterNetEvent`) siunčia jūsų naudojama `vorp_inventory` versija, kai paspaudžiami pirkimo/pardavimo mygtukai 'shop' tipo inventoriuje. Pavadinimai `inventory:shopBuyItem` ir `inventory:shopSellItem` yra tik spėjimas.
*   **Lokacijos Gavimas:** Atsakomuosiuose įvykiuose (`inventory:shopBuyItem`, `inventory:shopSellItem`) gali prireikti gauti lokacijos pavadinimą (`locationName`), kad galėtumėte pritaikyti teisingą logiką. `vorp_inventory` greičiausiai jo neperduos. Reikės sugalvoti būdą, kaip jį išsaugoti serveryje ar kliente prieš atidarant UI ir gauti atsakomajame įvykyje.
*   **Logikos Refaktoravimas:** Rekomenduojama pirkimo/pardavimo logiką iškelti į atskiras serverio funkcijas (`ExecuteStockBuyLogic`, `ExecuteStockSellLogic`), kad išvengtumėte kodo dubliavimo.
*   **UI Išvaizda:** `vorp_inventory` rodys jūsų akcijas kaip įprastus daiktus. UI išvaizda priklausys nuo jūsų `vorp_inventory` stiliaus.
*   **Alternatyvos:** Jei šis metodas atrodo per sudėtingas arba `vorp_inventory` negrąžina reikiamų įvykių, gali tekti grįžti prie originalios `MenuData` sąsajos arba ieškoti kitų UI bibliotekų. 