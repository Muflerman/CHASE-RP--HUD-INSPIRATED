local isLoggedIn = false
local playerHUDActive = false
local vehicleHUDActive = false
local seatbelt = false
local thirst = 100
local hunger = 100

-- Evento cuando el jugador selecciona personaje y entra al juego
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(500)
    isLoggedIn = true
    startHUD()
end)

-- Evento cuando el jugador cierra sesión o vuelve al multisede
RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    isLoggedIn = false
    SendNUIMessage({ action = 'hidePlayerHUD' })
    SendNUIMessage({ action = 'hideVehicleHUD' })
end)

-- Evento cuando el recurso se reinicia
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)
    -- Verificar si ya estamos logueados (útil al reiniciar el script en vivo)
    local QBCore = exports['qb-core']:GetCoreObject()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.citizenid then
        isLoggedIn = true
        startHUD()
    end
end)

-- Función para inicializar el HUD y el radar
function startHUD()
    if not isLoggedIn then return end -- No hacer nada si no ha entrado al juego

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped) then
        DisplayRadar(false) -- Ocultar minimapa si no está en vehículo
    else
        DisplayRadar(true)  -- Mostrar minimapa si está en vehículo
        SendNUIMessage({ action = 'showVehicleHUD' })
    end
    TriggerEvent('hud:client:LoadMap') -- Configurar el mapa cuadrado
    SendNUIMessage({ action = 'showPlayerHUD' })
    playerHUDActive = true
end

local lastCrossroadUpdate = 0
local lastCrossroadCheck = {}

-- Función para obtener los nombres de las calles actuales
function getCrossroads(vehicle)
    local updateTick = GetGameTimer()
    if updateTick - lastCrossroadUpdate > 1500 then
        local pos = GetEntityCoords(vehicle)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        lastCrossroadUpdate = updateTick
        lastCrossroadCheck = { GetStreetNameFromHashKey(street1), GetStreetNameFromHashKey(street2) }
    end
    return lastCrossroadCheck
end

local seatbeltTimer = 0

-- Comando para ponerse/quitarse el cinturón
RegisterCommand('toggleseatbelt', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        seatbelt = not seatbelt
        LocalPlayer.state:set('seatbelt', seatbelt, true) -- Guardar estado en State Bag

        if seatbelt then
            TriggerEvent('seatbelt:client:ToggleSeatbelt', true)
            lib.notify({ title = 'Cinturón', description = 'Te has puesto el cinturón', type = 'success' })
        else
            TriggerEvent('seatbelt:client:ToggleSeatbelt', false)
            lib.notify({ title = 'Cinturón', description = 'Te has quitado el cinturón', type = 'error' })
        end
    end
end, false)
-- Asignación de la tecla 'B' para el cinturón
RegisterKeyMapping('toggleseatbelt', 'Alternar Cinturon HUD', 'keyboard', 'B')

-- Hilo principal de actualización del HUD
CreateThread(function()
    while true do
        local stamina = 0
        local playerId = PlayerId()
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        -- Si el juego no está en pausa y el jugador ha entrado al mundo
        if not IsPauseMenuActive() and isLoggedIn then
            if not playerHUDActive then
                SendNUIMessage({ action = 'showPlayerHUD' })
                playerHUDActive = true
            end

            -- Calcular estados del jugador
            stamina = (100 - GetPlayerSprintStaminaRemaining(playerId))
            local oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10

            -- Enviar datos del jugador a la interfaz
            SendNUIMessage({
                action = 'updatePlayerHUD',
                health = (GetEntityHealth(ped) - 100),
                armor = GetPedArmour(ped),
                thirst = thirst,
                hunger = hunger,
                stamina = stamina,
                oxygen = oxygen,
                voice = LocalPlayer.state['proximity'] and LocalPlayer.state['proximity'].distance or 3.0,
                talking = NetworkIsPlayerTalking(PlayerId()),
            })

            -- Si el jugador está dentro de un coche
            if IsPedInAnyVehicle(ped) then
                if not vehicleHUDActive then
                    vehicleHUDActive = true
                    DisplayRadar(true)
                    TriggerEvent('hud:client:LoadMap')
                    SendNUIMessage({ action = 'showVehicleHUD' })
                end

                -- Obtener dirección y calles para la brújula (SOLO EN VEHÍCULO)
                local heading = GetEntityHeading(ped)
                local crossroads = getCrossroads(ped)
                SendNUIMessage({
                    action = 'updateLocationHUD',
                    heading = heading,
                    street1 = crossroads[1],
                    street2 = crossroads[2],
                })

                -- Enviar datos del coche a la interfaz
                local vehicleLock = GetVehicleDoorLockStatus(vehicle)
                SendNUIMessage({
                    action = 'updateVehicleHUD',
                    speed = math.ceil(GetEntitySpeed(vehicle) * Config.speedMultiplier),
                    fuel = math.ceil(GetVehicleFuelLevel(vehicle)),
                    gear = GetVehicleCurrentGear(vehicle),
                    rpm = GetVehicleCurrentRpm(vehicle),
                    seatbelt = seatbelt,
                    locked = (vehicleLock == 2 or vehicleLock == 3), -- 2 = Cerrado, 3 = Solo para el jugador
                    engine = GetIsVehicleEngineRunning(vehicle),
                })
            else
                -- Si sale del vehículo
                if vehicleHUDActive then
                    vehicleHUDActive = false
                    DisplayRadar(false)
                    SendNUIMessage({ action = 'hideVehicleHUD' })
                    seatbelt = false
                    LocalPlayer.state:set('seatbelt', false, true) -- Quitar cinturón automáticamente
                end
            end
        else
            -- Si el juego está en pausa, ocultar todo
            vehicleHUDActive = false
            DisplayRadar(false)
            SendNUIMessage({ action = 'hideVehicleHUD' })
            SendNUIMessage({ action = 'hidePlayerHUD' })
            playerHUDActive = false
        end

        -- Configuración constante del radar
        SetBigmapActive(false, false)
        SetRadarZoom(1000)
        Wait(Config.updateDelay)
    end
end)

-- Evento para actualizar hambre y sed desde el servidor
RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    thirst = newThirst
    hunger = newHunger
end)

-- Configuración profesional del minimapa cuadrado
RegisterNetEvent("hud:client:LoadMap", function()
    Wait(50)
    local defaultAspectRatio = 1920 / 1080
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end

    RequestStreamedTextureDict("squaremap", false)
    if not HasStreamedTextureDictLoaded("squaremap") then Wait(150) end

    -- Aplicar máscara cuadrada al minimapa
    SetMinimapClipType(0)
    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')

    -- Ajustar posición y tamaño del minimapa
    SetMinimapComponentPosition('minimap', 'L', 'B', 0.0 + minimapOffset, -0.040, 0.180, 0.200)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0 + minimapOffset, 0.010, 0.140, 0.220)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + minimapOffset, 0.035, 0.280, 0.320)

    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetMinimapClipType(0)
    SetRadarBigmapEnabled(true, false)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
end)

-- Hilo para ocultar componentes nativos de GTA (Nombre de vehículo, Calle, etc.)
CreateThread(function()
    while true do
        -- 6: Nombre del vehículo
        -- 7: Nombre de la zona
        -- 8: Clase del vehículo
        -- 9: Nombre de la calle (nativo)
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
        Wait(0)
    end
end)
