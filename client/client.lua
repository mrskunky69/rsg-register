local RSGCore = exports['rsg-core']:GetCoreObject()
local isBusy = false
local hasSpawned = false
local InRange = false
local SpawnedProps = {}

local function InputStoreName()
    local input = lib.inputDialog('Store Name', {
        { type = 'input', label = 'Enter store name (leave blank for default)', required = false }
    })
    return input and input[1] or ""
end



---------------------------------------------
-- check to see if prop can be place here
---------------------------------------------
local function CanPlacePropHere(pos)
    local canPlace = true

    local ZoneTypeId = 1
    local x,y,z =  table.unpack(GetEntityCoords(PlayerPedId()))
    local town = Citizen.InvokeNative(0x43AD8FC02B429D33, x,y,z, ZoneTypeId)
    if town ~= true then
        canPlace = true
    end

    for i = 1, #Config.PlayerProps do
        local checkprops = vector3(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z)
        local dist = #(pos - checkprops)
        if dist < Config.PlaceMinDistance then
            canPlace = false
        end
    end
    
    return canPlace
end

RegisterNetEvent('rex-register:client:placenewprop', function(prophash, item, coords, heading)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    
    if item == 'register' and PlayerData.job.name ~= "shopkeeper" then
        TriggerEvent('rNotify:NotifyLeft', "YOU ARE NOT A SHOPKEEPER", "DAMN", "generic_textures", "tick", 4000)
        return
    end

    RSGCore.Functions.TriggerCallback('rex-register:server:countprop', function(result)
        if item == 'register' and result >= Config.MaxStalls then
            lib.notify({ title = Lang:t('client.lang_1'), type = 'error', duration = 7000 })
            return
        end

        if not CanPlacePropHere(coords) then
            lib.notify({ title = Lang:t('client.lang_2'), type = 'error', duration = 7000 })
            return
        end

        if isBusy then
            lib.notify({ title = Lang:t('client.lang_3'), type = 'error', duration = 7000 })
            return
        end

        -- Prompt for store name
        local storeName = InputStoreName()

        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true) -- lock inventory
        local anim1 = `WORLD_HUMAN_CROUCH_INSPECT`
        FreezeEntityPosition(cache.ped, true)
        TaskStartScenarioInPlace(cache.ped, anim1, 0, true)
        Wait(10000)
        ClearPedTasks(cache.ped)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-register:server:newprop', prophash, item, coords, heading, storeName)
        LocalPlayer.state:set("inv_busy", false, true) -- unlock inventory
        isBusy = false

    end, item)
end)

---------------------------------------------
-- update props
---------------------------------------------
RegisterNetEvent('rex-register:client:updatePropData')
AddEventHandler('rex-register:client:updatePropData', function(data)
    Config.PlayerProps = data
end)

---------------------------------------------
-- spawn props
---------------------------------------------
CreateThread(function()
    while true do
        Wait(150)

        local pos = GetEntityCoords(cache.ped)

        for i = 1, #Config.PlayerProps do
            local prop = vector3(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z)
            local dist = #(pos - prop)
            if dist >= Config.SpawnDistance then goto continue end

            InRange = true

            for z = 1, #SpawnedProps do
                local p = SpawnedProps[z]

                if p.marketid == Config.PlayerProps[i].marketid then
                    hasSpawned = true
                end
            end

            if hasSpawned then goto continue end

            local modelHash = Config.PlayerProps[i].prophash
            local data = {}
            
            if not HasModelLoaded(modelHash) then
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do
                    Wait(1)
                end
            end
            
            -- set data objects
            data.marketid = Config.PlayerProps[i].marketid
            data.citizenid = Config.PlayerProps[i].citizenid
            data.owner = Config.PlayerProps[i].owner
            data.quality = Config.PlayerProps[i].quality

            data.obj = CreateObject(modelHash, Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z -1.2, false, false, false)
            SetEntityHeading(data.obj, Config.PlayerProps[i].h)
            SetEntityAsMissionEntity(data.obj, true)
            Wait(1000)
            FreezeEntityPosition(data.obj, true)
            SetModelAsNoLongerNeeded(data.obj)


            if Config.PlayerProps[i].item == 'register' then
			local blip = BlipAddForEntity(1664425300, data.obj)
			SetBlipSprite(blip, joaat(Config.Blip.blipSprite), true)
			SetBlipName(blip, data.storeName or Config.Blip.blipName) -- Use custom name if available
			SetBlipScale(blip, Config.Blip.blipScale)
			BlipAddModifier(blip, joaat(Config.Blip.blipColour))
end

            SpawnedProps[#SpawnedProps + 1] = data
            hasSpawned = false

            -- create target for the entity
            exports['rsg-target']:AddTargetEntity(data.obj, {
                options = {
                    {
                        type = 'client',
                        event = 'rex-register:client:openmarketstall',
                        icon = 'fa-solid fa-basket-shopping',
                        label = data.owner..Lang:t('client.lang_4'),
                        action = function()
                            TriggerEvent('rex-register:client:openmarket', data.marketid, data.citizenid, data.quality)
                        end,
                    },
                },
                distance = 5
            })
            -- end of target

            ::continue::
        end

        if not InRange then
            Wait(5000)
        end
    end
end)

RegisterNetEvent('rex-register:client:openmarket', function(marketid, owner_citizenid)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local player_citizenid = PlayerData.citizenid
    if player_citizenid == owner_citizenid then
        lib.registerContext({
            id = 'market_owner_menu',
            title = 'Market Owner Menu',
            options = {
                {
                    title = Lang:t('client.lang_5'),
                    icon = 'fa-solid fa-store',
                    event = 'rex-register:client:viewshopitems',
                    args = { 
                        marketid = marketid,
                    },
                    arrow = true
                },
                {
                    title = Lang:t('client.lang_6'),
                    icon = 'fa-solid fa-circle-plus',
                    iconColor = 'green',
                    event = 'rex-register:client:newstockitem',
                    args = {
                        marketid = marketid
                    },
                    arrow = true
                },
                {
                    title = Lang:t('client.lang_7'),
                    icon = 'fa-solid fa-circle-minus',
                    iconColor = 'red',
                    event = 'rex-register:client:removestockitem',
                    args = {
                        marketid = marketid
                    },
                    arrow = true
                },
                {
                    title = Lang:t('client.lang_8'),
                    icon = 'fa-solid fa-sack-dollar',
                    event = 'rex-register:client:checkmoney',
                    args = {
                        marketid = marketid
                    },
                    arrow = true
                },
                {
                    title = Lang:t('client.lang_9'),
                    icon = 'fa-solid fa-circle-info',
                    event = 'rex-register:client:maintenance',
                    args = {
                        marketid = marketid
                    },
                    arrow = true
                },
                {
                    title = Lang:t('client.lang_10'),
                    icon = 'fa-solid fa-box',
                    event = 'rex-register:client:packupmarket',
                    args = {
                        marketid = marketid,
                        owner_citizenid = owner_citizenid
                    },
                    arrow = true
                }
            }
        })
        lib.showContext('market_owner_menu')
    else
        -- For non-owners, directly trigger the view shop items event
        TriggerEvent('rex-register:client:viewshopitems', { marketid = marketid })
    end
end)

-------------------------------------------------------------------------------------------
-- view/buy shop items
-------------------------------------------------------------------------------------------
RegisterNetEvent('rex-register:client:viewshopitems', function(data)
    RSGCore.Functions.TriggerCallback('rex-register:server:checkstock', function(result)
        if result == nil then
			TriggerEvent('rNotify:NotifyLeft', "no stock available", "DAMN", "generic_textures", "tick", 4000)
            return
        end

        local options = {}
        for k,v in ipairs(result) do
            options[#options + 1] = {
                title = RSGCore.Shared.Items[result[k].item].label..' ($'..result[k].price..')',
                description = Lang:t('client.lang_15')..result[k].stock,
                icon = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                image = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                event = 'rex-register:client:buyshopitem',
                args = {
                    item = result[k].item,
                    stock = result[k].stock,
                    price = result[k].price,
                    label = RSGCore.Shared.Items[result[k].item].label,
                    marketid = result[k].marketid
                },
                arrow = true,
            }
        end
        
        -- Add a 'Close' option for non-owners
        options[#options + 1] = {
            title = 'closeshop',
            icon = 'fa-solid fa-times',
            onSelect = function()
                -- This will close the context menu
            end
        }

        lib.registerContext({
            id = 'market_items_menu',
            title = Lang:t('client.lang_16'),
            options = options
        })
        lib.showContext('market_items_menu')
    end, data.marketid)
end)

---------------------------------------------
-- buy item amount
---------------------------------------------
RegisterNetEvent('rex-register:client:buyshopitem', function(data)

    local input = lib.inputDialog(Lang:t('client.lang_17')..data.label, {
        { 
            label = Lang:t('client.lang_18'),
            type = 'input',
            required = true,
            icon = 'fa-solid fa-hashtag'
        },
    })
    
    if not input then
        return
    end
    
    local amount = tonumber(input[1])
    
    if data.stock >= amount then
        local newstock = (data.stock - amount)
        TriggerServerEvent('rex-register:server:buyitemamount', amount, data.item, newstock, data.price, data.label, data.marketid)
    else
        lib.notify({ title = Lang:t('client.lang_19'), type = 'error', duration = 7000 })
    end

end)

-------------------------------------------------------------------
-- sort table function
-------------------------------------------------------------------
local function compareNames(a, b)
    return a.value < b.value
end

-------------------------------------------------------------------
-- setup new stock item (authorised items)
-------------------------------------------------------------------
RegisterNetEvent('rex-register:client:newstockitem', function(data)

    local items = {}
    local PlayerData = RSGCore.Functions.GetPlayerData()

    for k,v in pairs(PlayerData.items) do
        local content = { value = v.name, label = v.label..' ('..v.amount..')' }
        items[#items + 1] = content
    end

    table.sort(items, compareNames)

    local item = lib.inputDialog(Lang:t('client.lang_20'), {
        { 
            type = 'select',
            options = items,
            label = Lang:t('client.lang_21'),
            required = true
        },
        { 
            type = 'number',
            label = Lang:t('client.lang_22'),
            required = true
        },
        { 
            type = 'input',
            label = Lang:t('client.lang_23'),
            required = true
        },
    })
    
    if not item then 
        return 
    end
    
    local hasItem = RSGCore.Functions.HasItem(item[1], item[2])
    
    if hasItem then
        TriggerServerEvent('rex-register:server:newstockitem', data.marketid, item[1], item[2], tonumber(item[3]))
    else
        lib.notify({ title = Lang:t('client.lang_24'), type = 'error', duration = 7000 })
    end

end)

RegisterNetEvent('rex-register:client:spawnNewProp')
AddEventHandler('rex-register:client:spawnNewProp', function(propData)
    local pos = GetEntityCoords(cache.ped)
    local propCoords = vector3(propData.x, propData.y, propData.z)
    
    if #(pos - propCoords) <= Config.SpawnDistance then
        -- Spawn the prop
        local modelHash = propData.prophash
        
        if not HasModelLoaded(modelHash) then
            RequestModel(modelHash)
            while not HasModelLoaded(modelHash) do
                Wait(1)
            end
        end
        
        local obj = CreateObject(modelHash, propData.x, propData.y, propData.z - 1.2, false, false, false)
        SetEntityHeading(obj, propData.h)
        SetEntityAsMissionEntity(obj, true)
        FreezeEntityPosition(obj, true)
        SetModelAsNoLongerNeeded(obj)
        
        -- Add blip for 'register' item with custom store name
        if propData.item == 'register' then
            local blip = BlipAddForEntity(1664425300, obj)
            SetBlipSprite(blip, joaat(Config.Blip.blipSprite), true)
            
            -- Set custom blip name or use default if not provided
            local blipName = propData.storeName and propData.storeName ~= "" and propData.storeName or Config.Blip.blipName
            SetBlipName(blip, blipName)
            
            SetBlipScale(blip, Config.Blip.blipScale)
            BlipAddModifier(blip, joaat(Config.Blip.blipColour))
        end
        
        -- Add to SpawnedProps table
        table.insert(SpawnedProps, {
            marketid = propData.marketid,
            citizenid = propData.citizenid,
            owner = propData.owner,
            obj = obj,
            storeName = propData.storeName -- Add storeName to SpawnedProps
        })
        
        -- Add target for the entity
        exports['rsg-target']:AddTargetEntity(obj, {
            options = {
                {
                    type = 'client',
                    event = 'rex-register:client:openmarketstall',
                    icon = 'fa-solid fa-basket-shopping',
                    label = (propData.storeName and propData.storeName ~= "" and propData.storeName or propData.owner) .. Lang:t('client.lang_4'),
                    action = function()
                        TriggerEvent('rex-register:client:openmarket', propData.marketid, propData.citizenid, propData.quality)
                    end,
                },
            },
            distance = 5
        })

        -- Notify player of successful prop spawn
        lib.notify({
            title = 'Store Placed',
            description = 'Your store "' .. (propData.storeName and propData.storeName ~= "" and propData.storeName or "Store") .. '" has been placed successfully.',
            type = 'success'
        })
    end
end)


-------------------------------------------------------------------------------------------
-- remove stock item
-------------------------------------------------------------------------------------------
RegisterNetEvent('rex-register:client:removestockitem', function(data)

    RSGCore.Functions.TriggerCallback('rex-register:server:checkstock', function(result)
        if result == nil then
            lib.registerContext({
                id = 'market_no_stock',
                title = Lang:t('client.lang_25'),
                menu = 'market_owner_menu',
                options = {
                    {
                        title = Lang:t('client.lang_26'),
                        icon = 'fa-solid fa-box',
                        disabled = true,
                        arrow = false
                    }
                }
            })
            lib.showContext('market_no_stock')
        else
            local options = {}
            for k,v in ipairs(result) do
                options[#options + 1] = {
                    title = RSGCore.Shared.Items[result[k].item].label,
                    description = Lang:t('client.lang_27')..result[k].stock,
                    icon = 'fa-solid fa-box',
                    serverEvent = 'rex-register:server:removestockitem',
                    icon = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                    image = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                    args = {
                        item = result[k].item,
                        marketid = result[k].marketid
                    },
                    arrow = true,
                }
            end
            lib.registerContext({
                id = 'market_stock_menu',
                title = Lang:t('client.lang_28'),
                menu = 'market_owner_menu',
                position = 'top-right',
                options = options
            })
            lib.showContext('market_stock_menu')
        end
    end, data.marketid)

end)

-------------------------------------------------------------------------------------------
-- withdraw market money 
-------------------------------------------------------------------------------------------
RegisterNetEvent('rex-register:client:checkmoney', function(data)
    RSGCore.Functions.TriggerCallback('rex-register:server:getmoney', function(data)
        local input = lib.inputDialog(Lang:t('client.lang_29'), {
            { 
                type = 'input',
                label = Lang:t('client.lang_30')..data.money,
                icon = 'fa-solid fa-dollar-sign',
                required = true
            },
        })
        
        if not input then
            return
        end

        local withdraw = tonumber(input[1])

        if withdraw <= data.money then
            TriggerServerEvent('rex-register:server:withdrawfunds', withdraw, data.marketid)
        else
            lib.notify({ title = Lang:t('client.lang_31'), type = 'error', duration = 7000 })
        end

    end, data.marketid)
end)

---------------------------------------------
-- market maintenance
---------------------------------------------
RegisterNetEvent('rex-register:client:maintenance', function(data)
    RSGCore.Functions.TriggerCallback('rex-register:server:getmarketstalldata', function(result)

        local quality = result[1].quality
        local repaircost = (100 - result[1].quality) * Config.RepairCost
        local colorScheme = nil
        
        if quality > 50 then 
            colorScheme = 'green'
        end
        
        if quality <= 50 and quality > 10 then
            colorScheme = 'yellow'
        end
        
        if quality <= 10 then
            colorScheme = 'red'
        end
    
        lib.registerContext({
            id = 'market_maintenance',
            title = Lang:t('client.lang_32'),
            options = {
                {
                    title = Lang:t('client.lang_33')..quality..Lang:t('client.lang_34'),
                    progress = quality,
                    colorScheme = colorScheme,
                },
                {
                    title = Lang:t('client.lang_35')..repaircost..Lang:t('client.lang_36'),
                    icon = 'fa-solid fa-screwdriver-wrench',
                    event = 'rex-register:client:repairmarketstall',
                    args = { 
						marketid = data.marketid,
						repaircost = repaircost
					},
                    arrow = true
                }
            }
        })
        lib.showContext('market_maintenance')

    end, data.marketid)

end)

---------------------------------------------
-- packup market stall
---------------------------------------------
RegisterNetEvent('rex-register:client:packupmarket', function(data)

    -- confirm action
    local input = lib.inputDialog(Lang:t('client.lang_37'), {
        {
            label = Lang:t('client.lang_38'),
            description = Lang:t('client.lang_39'),
            type = 'select',
            options = {
                { value = 'yes', label = Lang:t('client.lang_40') },
                { value = 'no',  label = Lang:t('client.lang_41') }
            },
            required = true
        },
    })
        
    if not input then
        return
    end
    
    if input[1] == 'no' then
        return
    end

    -- progress bar
    LocalPlayer.state:set("inv_busy", true, true)
    lib.progressBar({
        duration = Config.PackupTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disableControl = true,
        disable = {
            move = true,
            mouse = true,
        },
        label = Lang:t('client.lang_42'),
    })
    LocalPlayer.state:set("inv_busy", false, true)

    TriggerServerEvent('rex-register:server:packupmarketstall', data.marketid)
end)

---------------------------------------------
-- repair market stall
---------------------------------------------
RegisterNetEvent('rex-register:client:repairmarketstall', function(data)

    -- confirm repair action
    local input = lib.inputDialog(Lang:t('client.lang_37'), {
        {
            label = Lang:t('client.lang_38'),
            description = Lang:t('client.lang_43')..data.repaircost,
            type = 'select',
            options = {
                { value = 'yes', label = Lang:t('client.lang_40') },
                { value = 'no',  label = Lang:t('client.lang_41') }
            },
            required = true
        },
    })
        
    if not input then
        return
    end
    
    if input[1] == 'no' then
        return
    end

    -- progress bar
    LocalPlayer.state:set("inv_busy", true, true)
    lib.progressBar({
        duration = (1000 * data.repaircost),
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disableControl = true,
        disable = {
            move = true,
            mouse = true,
        },
        label = Lang:t('client.lang_44'),
    })
    LocalPlayer.state:set("inv_busy", false, true)

    TriggerServerEvent('rex-register:server:repairmarketstall', data.marketid, data.repaircost)
end)

---------------------------------------------
-- remove prop object
---------------------------------------------
RegisterNetEvent('rex-register:client:removePropObject')
AddEventHandler('rex-register:client:removePropObject', function(marketid)
    for i = 1, #SpawnedProps do
        local o = SpawnedProps[i]
        if o.marketid == marketid then
            -- Remove the blip if it exists
            local blip = GetBlipFromEntity(o.obj)
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end

            -- Remove the prop
            SetEntityAsMissionEntity(o.obj, false)
            FreezeEntityPosition(o.obj, false)
            DeleteObject(o.obj)

            -- Remove from SpawnedProps table
            table.remove(SpawnedProps, i)
            break
        end
    end

    -- Remove from Config.PlayerProps
    for k, v in pairs(Config.PlayerProps) do
        if v.marketid == marketid then
            table.remove(Config.PlayerProps, k)
            break
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- Sync every 5 minutes
        TriggerServerEvent('rex-register:server:requestPropSync')
    end
end)

RegisterNetEvent('rex-register:client:syncProps')
AddEventHandler('rex-register:client:syncProps', function(serverProps)
    -- Remove any props that are no longer on the server
    for i = #SpawnedProps, 1, -1 do
        local found = false
        for _, serverProp in ipairs(serverProps) do
            if SpawnedProps[i].marketid == serverProp.marketid then
                found = true
                break
            end
        end
        if not found then
            -- Remove the blip if it exists
            local blip = GetBlipFromEntity(SpawnedProps[i].obj)
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end

            -- Remove the prop
            SetEntityAsMissionEntity(SpawnedProps[i].obj, false)
            FreezeEntityPosition(SpawnedProps[i].obj, false)
            DeleteObject(SpawnedProps[i].obj)

            table.remove(SpawnedProps, i)
        end
    end

    Config.PlayerProps = serverProps
end)

---------------------------------------------
-- clean up
---------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for i = 1, #SpawnedProps do
        local props = SpawnedProps[i].obj

        SetEntityAsMissionEntity(props, false)
        FreezeEntityPosition(props, false)
        DeleteObject(props)
    end
	
	SpawnedProps = {}
end)
