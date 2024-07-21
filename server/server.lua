local RSGCore = exports['rsg-core']:GetCoreObject()
local PropsLoaded = false

---------------------------------------------
-- update prop data
---------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)
        if PropsLoaded then
            TriggerClientEvent('rex-register:client:updatePropData', -1, Config.PlayerProps)
        end
    end
end)

---------------------------------------------
-- get props
---------------------------------------------
CreateThread(function()
    TriggerEvent('rex-register:server:getProps')
    PropsLoaded = true
end)

---------------------------------------------
-- get props
---------------------------------------------
RegisterServerEvent('rex-register:server:getProps')
AddEventHandler('rex-register:server:getProps', function()
    local result = MySQL.query.await('SELECT * FROM player_stores')

    if not result[1] then return end

    for i = 1, #result do
        local propData = json.decode(result[i].properties)
        propData.storeName = result[i].storeName -- Ensure storeName is included
        if Config.EnableServerNotify then
            print(Lang:t('server.lang_1')..propData.item..Lang:t('server.lang_2')..propData.marketid)
        end
        table.insert(Config.PlayerProps, propData)
    end
end)

---------------------------------------------
-- use prop
---------------------------------------------
RSGCore.Functions.CreateUseableItem('register', function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.name == "shopkeeper" then
        TriggerClientEvent('rex-register:client:createprop', src, 'register', Config.UseProp)
    else
        TriggerClientEvent('rNotify:NotifyLeft', src, "YOU ARE NOT A SHOPKEEPER", "DAMN", "generic_textures", "tick", 4000)
    end
end)

---------------------------------------------
-- count props
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-register:server:countprop', function(source, cb, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM player_stores WHERE citizenid = ? AND item = ?", { citizenid, item })
    if result then
        cb(result)
    else
        cb(nil)
    end
end)

---------------------------------------------
-- create new market stall
---------------------------------------------
RegisterNetEvent('rex-register:server:newprop', function(prophash, item, coords, heading, storeName)
    local src = source
    local marketid = math.random(111111, 999999)
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    local owner = firstname .. ' ' .. lastname

    -- Use the provided store name or default to the config name
    storeName = storeName ~= "" and storeName or Config.Blip.blipName

    local PropData = {
        marketid = marketid,
        item = item,
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = heading,
        prophash = prophash,
        owner = owner,
        citizenid = citizenid,
        buildttime = os.time(),
        storeName = storeName,
        quality = 100  -- Add an initial quality value
    }

    table.insert(Config.PlayerProps, PropData)

    local properties = json.encode(PropData)  -- Encode the PropData to JSON

    MySQL.Async.execute('INSERT INTO player_stores (properties, marketid, citizenid, owner, item, storeName) VALUES (@properties, @marketid, @citizenid, @owner, @item, @storeName)',
    {
        ['@properties'] = properties,  -- Use the encoded JSON string
        ['@marketid'] = marketid,
        ['@citizenid'] = citizenid,
        ['@owner'] = owner,
        ['@item'] = item,
        ['@storeName'] = storeName
    })

    Player.Functions.RemoveItem(item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "remove")
    TriggerEvent('rex-register:server:updateProps')
    TriggerClientEvent('rex-register:client:spawnNewProp', -1, PropData)
end)

---------------------------------------------
-- update props
---------------------------------------------
RegisterServerEvent('rex-register:server:updateProps')
AddEventHandler('rex-register:server:updateProps', function()
    local src = source
    TriggerClientEvent('rex-register:client:updatePropData', src, Config.PlayerProps)
	
end)

---------------------------------------------
-- check stock
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-register:server:checkstock', function(source, cb, marketid)
    MySQL.query('SELECT * FROM player_market_store WHERE marketid = ?', { marketid }, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- check stock
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-register:server:getmarketstalldata', function(source, cb, marketid)
    MySQL.query('SELECT * FROM player_stores WHERE marketid = ?', { marketid }, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- buy item amount / add to market money
---------------------------------------------
RegisterNetEvent('rex-register:server:buyitemamount', function(amount, item, newstock, price, label, marketid)

    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local money = Player.PlayerData.money[Config.Money]

    local totalcost = (price * amount)

    if money >= totalcost then
        MySQL.update('UPDATE player_market_store SET stock = ? WHERE marketid = ? AND item = ?', {newstock, marketid, item})

        Player.Functions.RemoveMoney(Config.Money, totalcost)
        Player.Functions.AddItem(item, amount)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "add")

        MySQL.query('SELECT * FROM player_stores WHERE marketid = ?', { marketid }, function(data2)
            local moneyupdate = (data2[1].money + totalcost)
            MySQL.update('UPDATE player_stores SET money = ? WHERE marketid = ?',{moneyupdate, marketid})
        end)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = Lang:t('server.lang_3')..Config.Money, type = 'error', duration = 7000 })
    end

end)

---------------------------------------------
-- update stock or add new stock
---------------------------------------------
RegisterNetEvent('rex-register:server:newstockitem', function(marketid, item, amount, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local itemcount = MySQL.prepare.await("SELECT COUNT(*) as count FROM player_market_stock WHERE marketid = ? AND item = ?", { marketid, item })
    if itemcount == 0 then
        MySQL.Async.execute('INSERT INTO player_market_store (marketid, item, stock, price) VALUES (@marketid, @item, @stock, @price)',
        {
            ['@marketid'] = marketid,
            ['@item'] = item,
            ['@stock'] = amount,
            ['@price'] = price
        })
        Player.Functions.RemoveItem(item, amount)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "remove")
    else
        MySQL.query('SELECT * FROM player_market_store WHERE marketid = ? AND item = ?', { marketid, item }, function(data)
            local stockupdate = (amount + data[1].stock)
            MySQL.update('UPDATE player_market_store SET stock = ? WHERE marketid = ? AND item = ?',{stockupdate, marketid, item})
            MySQL.update('UPDATE player_market_store SET price = ? WHERE marketid = ? AND item = ?',{price, marketid, item})
            Player.Functions.RemoveItem(item, amount)
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "remove")
        end)
    end
end)

---------------------------------------------
-- remove stock item
---------------------------------------------
RegisterNetEvent('rex-register:server:removestockitem', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    MySQL.query('SELECT * FROM player_market_store WHERE marketid = ? AND item = ?', { data.marketid, data.item }, function(result)
        Player.Functions.AddItem(result[1].item, result[1].stock)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[result[1].item], "add")
        MySQL.Async.execute('DELETE FROM player_market_store WHERE id = ?', { result[1].id })
    end)
end)

---------------------------------------------
-- get market money
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-register:server:getmoney', function(source, cb, marketid)
    MySQL.query('SELECT * FROM player_stores WHERE marketid = ?', { marketid }, function(result)
        if result[1] then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- withdraw market money
---------------------------------------------
RegisterNetEvent('rex-register:server:withdrawfunds', function(amount, marketid)

    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    MySQL.query('SELECT * FROM player_stores WHERE marketid = ?',{marketid} , function(result)
        if result[1] ~= nil then
            if result[1].money >= amount then
                local updatemoney = (result[1].money - amount)
                MySQL.update('UPDATE player_stores SET money = ? WHERE marketid = ?', { updatemoney, marketid })
                Player.Functions.AddMoney(Config.Money, amount)
            end
        end
    end)
end)

---------------------------------------------
-- packup market stall
---------------------------------------------
RegisterServerEvent('rex-register:server:packupmarketstall')
AddEventHandler('rex-register:server:packupmarketstall', function(marketid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    for k, v in pairs(Config.PlayerProps) do
        if v.marketid == marketid then
            table.remove(Config.PlayerProps, k)
        end
    end

    TriggerClientEvent('rex-register:client:removePropObject', src, marketid)
    TriggerEvent('rex-register:server:updateProps')
    Player.Functions.AddItem('register', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['register'], "add")
    MySQL.Async.execute('DELETE FROM player_stores WHERE marketid = ?', { marketid })
    MySQL.Async.execute('DELETE FROM player_market_store WHERE marketid = ?', { marketid })
	TriggerClientEvent('rex-register:client:removePropObject', -1, marketid)
	
	

end)

---------------------------------------------
-- repair trap
---------------------------------------------
RegisterNetEvent('rex-register:server:repairmarketstall', function(marketid, repaircost)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveMoney(Config.Money, repaircost)
    MySQL.update('UPDATE player_stores SET quality = ? WHERE marketid = ?', {100, marketid})
end)

---------------------------------------------
-- market upkeep system
---------------------------------------------
lib.cron.new(Config.UpkeepCronJob, function ()

    local result = MySQL.query.await('SELECT * FROM player_stores')

    if not result then goto continue end

    for i = 1, #result do

        local marketid = result[i].marketid
        local quality = result[i].quality
        local owner = result[i].owner

        -- check market maintanance
        if quality > 0 then
            MySQL.update('UPDATE player_stores SET quality = ? WHERE marketid = ?', {quality-1, marketid})
        else
            for k,v in pairs(Config.PlayerProps) do
                if v.marketid == marketid then
                    table.remove(Config.PlayerProps, k)
                end
            end

            TriggerClientEvent('rex-register:client:removePropObject', -1, marketid)
            TriggerEvent('rex-register:server:updateProps')
            MySQL.Async.execute('DELETE FROM player_stores WHERE marketid = ?', { marketid })
            MySQL.Async.execute('DELETE FROM player_market_store WHERE marketid = ?', { marketid })
            TriggerEvent('rsg-log:server:CreateLog', 'rexmarket', Lang:t('server.lang_4'), 'red', Lang:t('server.lang_5')..marketid..Lang:t('server.lang_6')..owner..Lang:t('server.lang_7'))
        end

    end

    ::continue::

    if Config.EnableServerNotify then
        print(Lang:t('server.lang_8'))
    end

end)

RegisterServerEvent('rex-register:server:requestPropSync')
AddEventHandler('rex-register:server:requestPropSync', function()
    local src = source
    TriggerClientEvent('rex-register:client:syncProps', src, Config.PlayerProps)
end)

---------------------------------------------
-- market stock system
---------------------------------------------
lib.cron.new(Config.StockCronJob, function ()

    local result = MySQL.query.await('SELECT * FROM player_market_store')

    if not result then goto continue end
    
    for i = 1, #result do

        local marketid = result[i].marketid
        local item = result[i].item
        local stock = result[i].stock

        -- check stock at zero and remove
        if stock == 0 then
            MySQL.Async.execute('DELETE FROM player_market_store WHERE marketid = ? AND item = ?', { marketid, item })
        end

    end

    ::continue::

    if Config.EnableServerNotify then
        print(Lang:t('server.lang_9'))
    end

end)
