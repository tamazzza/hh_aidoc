local QBCore = exports['qb-core']:GetCoreObject()

local Active = false
local test = nil
local test1 = nil
local spam = true

RegisterCommand(Config.Command, function(source, args, raw)
    if (QBCore.Functions.GetPlayerData().metadata["isdead"]) or (QBCore.Functions.GetPlayerData().metadata["inlaststand"]) and spam then
        QBCore.Functions.TriggerCallback('ai:docOnline', function(EMSOnline, hasEnoughMoney)
            if EMSOnline <= Config.Doctor and hasEnoughMoney and spam then
                SpawnVehicle(GetEntityCoords(PlayerPedId()))
                TriggerServerEvent('ai:charge')
                Notify("თქვენ გამოიძახეთ სამედიცინო დახმარების გუნდი", "success")
            else
                if EMSOnline > Config.Doctor then
                    Notify("სერვერზე არის აქტიური პერსონალი", "error")
                elseif not hasEnoughMoney then
                    Notify("არ გაქვთ საკმარისი თანხა", "error")
                else
                    Notify("მოითმინეთ, დახმარების ჯგუფი გზაშია", "primary")
                end	
            end
        end)
    else
        Notify("ვერ გამოიძახებთ დახმარებას სანამ ცოცხალი ხართ", "error")
    end
end)

function SpawnVehicle(x, y, z)  
    spam = false
    local vehhash = GetHashKey(Config.Vehicle)                                                     
    local loc = GetEntityCoords(PlayerPedId())
    RequestModel(vehhash)
    while not HasModelLoaded(vehhash) do
        Wait(1)
    end
    RequestModel(Config.Ped)
    while not HasModelLoaded(Config.Ped) do
        Wait(1)
    end
    local spawnRadius = Config.SpawnRadius
    local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(loc.x + math.random(-spawnRadius, spawnRadius), loc.y + math.random(-spawnRadius, spawnRadius), loc.z, 0, 3, 0)

    if not DoesEntityExist(vehhash) then
        mechVeh = CreateVehicle(vehhash, spawnPos, spawnHeading, true, false)                         
        ClearAreaOfVehicles(GetEntityCoords(mechVeh), 5000, false, false, false, false, false)  
        SetVehicleOnGroundProperly(mechVeh)
        SetVehicleNumberPlateText(mechVeh, Config.Plate)
        SetEntityAsMissionEntity(mechVeh, true, true)
        SetVehicleEngineOn(mechVeh, true, true, false)
        
        SetVehicleSiren(mechVeh, true)
        
        mechPed = CreatePedInsideVehicle(mechVeh, 26, GetHashKey(Config.Ped), -1, true, false)              
        mechBlip = AddBlipForEntity(mechVeh)                                                        	
        SetBlipFlashes(mechBlip, true)  
        SetBlipColour(mechBlip, 5)

        PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
        Wait(2000)

        local drivingStyle = 524863

        TaskVehicleDriveToCoord(mechPed, mechVeh, loc.x, loc.y, loc.z, 20.0, 0, GetEntityModel(mechVeh), drivingStyle, 2.0)

        SetEntityInvincible(mechVeh, true) 

        test = mechVeh
        test1 = mechPed
        Active = true
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200)
        if Active then
            local player = GetPlayerPed(-1)
            local loc = GetEntityCoords(player)
            local lc = GetEntityCoords(test)
            local ld = GetEntityCoords(test1)
            local dist = Vdist(loc.x, loc.y, loc.z, lc.x, lc.y, lc.z)
            local dist1 = Vdist(loc.x, loc.y, loc.z, ld.x, ld.y, ld.z)

            if dist <= 10 then
                if IsPedInAnyVehicle(player, false) then
                    local veh = GetVehiclePedIsIn(player, false)
                    TaskLeaveVehicle(player, veh, 0)
                    Wait(2000)
                end

                if Active then
                    TaskGoToCoordAnyMeans(test1, loc.x, loc.y, loc.z, 1.0, 0, 0, 786603, 0xbf800000)
                end
                if dist1 <= 1 then 
                    Active = false
                    ClearPedTasksImmediately(test1)
                    DoctorNPC()
                end
            end
        end
    end
end)

function DoctorNPC()
    RequestAnimDict("mini@cpr@char_a@cpr_str")
    while not HasAnimDictLoaded("mini@cpr@char_a@cpr_str") do
        Citizen.Wait(1000)
    end

    TaskPlayAnim(test1, "mini@cpr@char_a@cpr_str", "cpr_pumpchest", 1.0, 1.0, -1, 9, 1.0, 0, 0, 0)
    QBCore.Functions.Progressbar("revive_doc", "ექიმი გიწევთ პირველად დახმარებას", Config.ReviveTime, false, false, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        ClearPedTasks(test1)
        Citizen.Wait(500)
        TriggerEvent("hospital:client:Revive")
        StopScreenEffect('DeathFailOut')	
        Notify("თქვენ სრულიად გამოჯანმრთელდით", "success")
        RemovePedElegantly(test1)
        
        DeleteEntity(test)
        Wait(5000)
        DeleteEntity(test1)
        
        spam = true
    end)
end

function Notify(msg, state)
    QBCore.Functions.Notify(msg, state)
end
