local RSGCore = exports['rsg-core']:GetCoreObject()

math.randomseed(GetGameTimer())
local CancelPrompt
local SetPrompt
local RotateLeftPrompt
local RotateRightPrompt
local MoveUpPrompt
local MoveDownPrompt
local active = false
local Props = {}

local PromptPlacerGroup = GetRandomIntInRange(0, 0xffffff)

Citizen.CreateThread(function()
    Set()
    Del()
    RotateLeft()
    RotateRight()
	MoveUp()
    MoveDown()
    MoveForward()
    MoveBackward()
end)

function Del()
    Citizen.CreateThread(function()
        local str = Config.PromptCancelName
        CancelPrompt = PromptRegisterBegin()
        PromptSetControlAction(CancelPrompt, 0xF84FA74F)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(CancelPrompt, str)
        PromptSetEnabled(CancelPrompt, true)
        PromptSetVisible(CancelPrompt, true)
        PromptSetHoldMode(CancelPrompt, true)
        PromptSetGroup(CancelPrompt, PromptPlacerGroup)
        PromptRegisterEnd(CancelPrompt)
    end)
end

function Set()
    Citizen.CreateThread(function()
        local str = Config.PromptPlaceName
        SetPrompt = PromptRegisterBegin()
        PromptSetControlAction(SetPrompt, 0x07CE1E61)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(SetPrompt, str)
        PromptSetEnabled(SetPrompt, true)
        PromptSetVisible(SetPrompt, true)
        PromptSetHoldMode(SetPrompt, true)
        PromptSetGroup(SetPrompt, PromptPlacerGroup)
        PromptRegisterEnd(SetPrompt)
    end)
end

function RotateLeft()
    Citizen.CreateThread(function()
        local str = Config.PromptRotateLeft
        RotateLeftPrompt = PromptRegisterBegin()
        PromptSetControlAction(RotateLeftPrompt, 0xA65EBAB4)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RotateLeftPrompt, str)
        PromptSetEnabled(RotateLeftPrompt, true)
        PromptSetVisible(RotateLeftPrompt, true)
        PromptSetStandardMode(RotateLeftPrompt, true)
        PromptSetGroup(RotateLeftPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RotateLeftPrompt)
    end)
end

function RotateRight()
    Citizen.CreateThread(function()
        local str = Config.PromptRotateRight
        RotateRightPrompt = PromptRegisterBegin()
        PromptSetControlAction(RotateRightPrompt, 0xDEB34313)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RotateRightPrompt, str)
        PromptSetEnabled(RotateRightPrompt, true)
        PromptSetVisible(RotateRightPrompt, true)
        PromptSetStandardMode(RotateRightPrompt, true)
        PromptSetGroup(RotateRightPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RotateRightPrompt)

    end)
end

function MoveUp()
    Citizen.CreateThread(function()
        local str = Config.PromptMoveUp
        MoveUpPrompt = PromptRegisterBegin()
        PromptSetControlAction(MoveUpPrompt, RSGCore.Shared.Keybinds['UP'])
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(MoveUpPrompt, str)
        PromptSetEnabled(MoveUpPrompt, true)
        PromptSetVisible(MoveUpPrompt, true)
        PromptSetStandardMode(MoveUpPrompt, true)
        PromptSetGroup(MoveUpPrompt, PromptPlacerGroup)
        PromptRegisterEnd(MoveUpPrompt)
    end)
end

function MoveDown()
    Citizen.CreateThread(function()
        local str = Config.PromptMoveDown
        MoveDownPrompt = PromptRegisterBegin()
        PromptSetControlAction(MoveDownPrompt, RSGCore.Shared.Keybinds['DOWN'])
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(MoveDownPrompt, str)
        PromptSetEnabled(MoveDownPrompt, true)
        PromptSetVisible(MoveDownPrompt, true)
        PromptSetStandardMode(MoveDownPrompt, true)
        PromptSetGroup(MoveDownPrompt, PromptPlacerGroup)
        PromptRegisterEnd(MoveDownPrompt)
    end)
end

function MoveForward()
    Citizen.CreateThread(function()
        local str = Config.PromptMoveForward
        MoveForwardPrompt = PromptRegisterBegin()
        PromptSetControlAction(MoveForwardPrompt, RSGCore.Shared.Keybinds['DEL'])
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(MoveForwardPrompt, str)
        PromptSetEnabled(MoveForwardPrompt, true)
        PromptSetVisible(MoveForwardPrompt, true)
        PromptSetStandardMode(MoveForwardPrompt, true)
        PromptSetGroup(MoveForwardPrompt, PromptPlacerGroup)
        PromptRegisterEnd(MoveForwardPrompt)
    end)
end

function MoveBackward()
    Citizen.CreateThread(function()
        local str = Config.PromptMoveBackward
        MoveBackwardPrompt = PromptRegisterBegin()
        PromptSetControlAction(MoveBackwardPrompt, RSGCore.Shared.Keybinds['PGDN'])
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(MoveBackwardPrompt, str)
        PromptSetEnabled(MoveBackwardPrompt, true)
        PromptSetVisible(MoveBackwardPrompt, true)
        PromptSetStandardMode(MoveBackwardPrompt, true)
        PromptSetGroup(MoveBackwardPrompt, PromptPlacerGroup)
        PromptRegisterEnd(MoveBackwardPrompt)
    end)
end

function modelrequest( model )
    Citizen.CreateThread(function()
        RequestModel( model )
    end)
end

function PropPlacer(item, prop)
    local pHead = GetEntityHeading(cache.ped)
    local pos = GetEntityCoords(cache.ped)
    local PropHash = prop
    local coords = GetEntityCoords(cache.ped)
    local _x, _y, _z = table.unpack(coords)
    local forward = GetEntityForwardVector(cache.ped)
    local x, y, z = table.unpack(pos + forward * Config.ForwardDistance)
    local ox = x - _x
    local oy = y - _y
    local oz = z - _z
    local heading = pHead

    SetCurrentPedWeapon(cache.ped, -1569615261, true)
    while not HasModelLoaded(PropHash) do
        Wait(500)
        modelrequest(PropHash)
    end

    local tempObj = CreateObject(PropHash, pos.x, pos.y, pos.z, false, false, false)
    local tempObj2 = CreateObject(PropHash, pos.x, pos.y, pos.z, false, false, false)
    AttachEntityToEntity(tempObj2, cache.ped, 0, ox, oy, 1.2, 0.0, 0.0, 0, true, false, false, false, false)
    SetEntityAlpha(tempObj, 180)
    SetEntityAlpha(tempObj2, 2)

    while true do
        Wait(5)
        local PropPlacerGroupName = CreateVarString(10, 'LITERAL_STRING', Config.PromptGroupName)
        PromptSetActiveGroupThisFrame(PromptPlacerGroup, PropPlacerGroupName)

        AttachEntityToEntity(tempObj, cache.ped, 0, ox, oy, oz - 1.2, 0.0, 0.0, heading, true, false, false, false, false)

        if IsControlPressed(1, RSGCore.Shared.Keybinds['LEFT']) then
            heading = heading - 1
            print("Rotating left, new heading: " .. heading)
        end

        if IsControlPressed(1, RSGCore.Shared.Keybinds['RIGHT']) then
            heading = heading + 1
            print("Rotating right, new heading: " .. heading)
        end

        if IsControlPressed(1, RSGCore.Shared.Keybinds['DOWN']) then
            oz = oz - 0.01
            print("Moving down, new oz: " .. oz)
        end

        if IsControlPressed(1, RSGCore.Shared.Keybinds['UP']) then
            oz = oz + 0.05
            print("Moving up, new oz: " .. oz)
        end

        if IsControlPressed(1, RSGCore.Shared.Keybinds['DEL']) then
            oy = oy - 0.01
            print("Moving backward, new oy: " .. oy)
        end

        if IsControlPressed(1, RSGCore.Shared.Keybinds['PGDN']) then
            oy = oy + 0.01
            print("Moving forward, new oy: " .. oy)
        end

        local pPos = vector3(pos.x + ox, pos.y + oy, pos.z + oz)

        if PromptHasHoldModeCompleted(SetPrompt) then
            -- Freeze the prop's position and trigger the event to handle the placed prop
            TriggerEvent('rex-register:client:placenewprop', PropHash, item, pPos, heading)
            DeleteEntity(tempObj) -- Delete the tempObj object
            DeleteEntity(tempObj2)
            FreezeEntityPosition(cache.ped, false)
            break
        end

        if PromptHasHoldModeCompleted(CancelPrompt) then
            DeleteEntity(tempObj2)
            DeleteEntity(tempObj)
            SetModelAsNoLongerNeeded(PropHash)
            break
        end
    end
end




RegisterNetEvent('rex-register:client:createprop', function(item, prop)
    PropPlacer(item, prop)
end)
