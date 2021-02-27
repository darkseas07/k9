ESX = nil
local PlayerData = {}
local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local spawnedK9 = nil
local onScene = false
local canSpawn = false
local canRest = false
local onAction = false

Citizen.CreateThread(function()
	while ESX == nil do TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) Wait(0) end
    while ESX.GetPlayerData().job == nil do Wait(0) end
    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

RegisterNetEvent("k9:spawnK9")
AddEventHandler("k9:spawnK9", function ()
	if canSpawn then
		onAction = true
		TriggerEvent("mythic_progressbar:client:progress",{
			name = "spawnk9",
			duration = 3000,
			label = "K9 çağrıyorsun!",
			useWhileDead = false,
			canCancel = true,
			controlDisables = {
				disableMovement = false,
				disableCarMovement = false,
				disableMouse = false,
				disableCombat = false,
			}, 
			animation = {
				animDict = "mp_common",
				anim = "givetake1_a",
			}
			},function(status)
			if not status then
				local k9ped = GetHashKey(Config.Model)
				RequestModel(k9ped)
				while not HasModelLoaded(k9ped) do
					Citizen.Wait(1)
					RequestModel(k9ped)
				end
				playerCoords = GetEntityCoords(PlayerPedId())
				playerHeading = GetEntityHeading(PlayerPedId())
				spawnedK9 = CreatePed(28, k9ped, playerCoords.x,  playerCoords.y, playerCoords.z, playerHeading, false, true)
				AddBlip()
				SetBlockingOfNonTemporaryEvents(spawnedK9, true)
				SetPedFleeAttributes(spawnedK9, 0, false)
				SetPedRelationshipGroupHash(spawnedK9, GetHashKey("k9"))
				SetCanAttackFriendly(spawnedK9, true, false)
				SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedK9), GetPedRelationshipGroupHash(PlayerPedId()))
				onAction = false
				exports['mythic_notify']:DoHudText('inform', 'K9 çağrıldı!')
			else
				exports['mythic_notify']:DoHudText('error', 'K9 çağırmayı iptal ettin!')
			end
		end)
	else
		exports['mythic_notify']:DoHudText('error', 'K9\'u burada çağıramazsın!')
	end
end)

function isNearPlayer()
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if  closestDistance <= 1.0 and closestPlayer ~= -1 then
        return true
    else
        return false
    end
end

RegisterNetEvent("k9:command")
AddEventHandler("k9:command", function (command)
	if command == "follow" then
		onScene = true
		TaskFollowToOffsetOfEntity(spawnedK9, PlayerPedId(), 0.0, 0.0, 0.0, 5.0, -1, 0.25, 1)
		exports['mythic_notify']:DoHudText('inform', 'K9 seni takip ediyor!')
	elseif command == "stop" then
		onScene = true
		ClearPedTasksImmediately(spawnedK9)
		exports['mythic_notify']:DoHudText('inform', 'K9 durdu!')
	elseif command == "sit" then
		onScene = true
		local animDict = "creatures@rottweiler@amb@world_dog_sitting@idle_a"
        local anim = "idle_c"
		PlayAnim(animDict, anim)
		exports['mythic_notify']:DoHudText('inform', 'K9 oturuyor!')
	elseif command == "barf" then
		onScene = true
		local animDict = "creatures@rottweiler@amb@world_dog_barking@idle_a"
        local anim = "idle_a"
		PlayAnim(animDict, anim)
		exports['mythic_notify']:DoHudText('inform', 'K9 havlıyor!')
	elseif command == "getInOutCar" then
		onScene = true
		local playerInVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
		local k9InVehicle = IsPedInAnyVehicle(spawnedK9, false)
		if playerInVehicle and not k9InVehicle then
			if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(spawnedK9)) <= 5.0 then
				local veh = GetVehiclePedIsIn(PlayerPedId(), false)
				local passengers = GetVehicleMaxNumberOfPassengers(veh)
				for i = 0, passengers do
					if IsVehicleSeatFree(veh, i) then
						TaskEnterVehicle(spawnedK9, veh, -1, i, 1.0, 1, 0)
						break
					end
				end
				exports['mythic_notify']:DoHudText('inform', 'K9 araca biniyor!')
			else
				exports['mythic_notify']:DoHudText('error', 'K9 sana çok uzak!')
			end		
		elseif not playerInVehicle and k9InVehicle then
			local veh = GetVehiclePedIsIn(spawnedK9, false)
			TaskLeaveVehicle(spawnedK9, veh, 0)
			exports['mythic_notify']:DoHudText('inform', 'K9 araçtan iniyor!')
		elseif not playerInVehicle and not k9InVehicle then
			if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(spawnedK9)) <= 5.0 then
				local veh = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 7.0, 0, 70)
				if DoesEntityExist(veh) then
					local passengers = GetVehicleMaxNumberOfPassengers(veh)
					for i = 0, passengers do
						if IsVehicleSeatFree(veh, i) then
							TaskEnterVehicle(spawnedK9, veh, -1, i, 1.0, 1, 0)
							exports['mythic_notify']:DoHudText('inform', 'K9 araca biniyor!')
							break
						end
					end
				else
					exports['mythic_notify']:DoHudText('error', 'Yakında araç yok!')
				end
			else
				exports['mythic_notify']:DoHudText('error', 'K9 sana çok uzak!')
			end		
		elseif playerInVehicle and k9InVehicle then
			local veh = GetVehiclePedIsIn(spawnedK9, false)
			TaskLeaveVehicle(spawnedK9, veh, 0)
			exports['mythic_notify']:DoHudText('inform', 'K9 araçtan iniyor!')
		end
	elseif command == "searchplayer" then
		onScene = true
		local player, distance = ESX.Game.GetClosestPlayer()
		if player and player ~= nil and player ~= -1 and distance ~= -1 then
			local plyrCoords = GetEntityCoords(GetPlayerPed(player))
			TaskGoToCoordAnyMeans(spawnedK9, plyrCoords.x, plyrCoords.y, plyrCoords.z, 5.0, 0, 0, 1, 2.0)
			Citizen.Wait(5000)
			PlayAnim('missexile2', 'fra0_ig_12_chop_waiting_a')
			Citizen.Wait(4000)
			PlayAnim('missfra0_chop_find', 'fra0_ig_14_chop_sniff_fwds')
			Citizen.Wait(4000)
			TriggerServerEvent("k9:checkItems", 1)
		else
			exports['mythic_notify']:DoHudText('error', 'Yakınında oyuncu yok!')
		end
	elseif command == "searchvehicle" then
		onScene = true
		if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(spawnedK9)) > 5.0 then
			exports['mythic_notify']:DoHudText('inform', 'K9 sana çok uzak!')
			return
		end

		local veh = GetClosestVehicle(GetEntityCoords(spawnedK9), 7.0, 0, 70)
		if veh and veh ~= nil and veh ~= 0 then
			if DoesEntityExist(veh) then
				if GetVehicleDoorAngleRatio(veh, 0) <= 0.45 then
					exports['mythic_notify']:DoHudText('error', 'Sürücü kapısı kapalı. Açmadan arayamaz!')
				end
				if GetVehicleDoorAngleRatio(veh, 1) <= 0.45 then
					exports['mythic_notify']:DoHudText('error', 'Yolcu kapısı kapalı. Açmadan arayamaz!')
				end
				if GetVehicleDoorAngleRatio(veh, 5) <= 0.45 then
					exports['mythic_notify']:DoHudText('error', 'Bagaj kapalı. Açmadan arayamaz!')
					return
				end

				exports['mythic_notify']:DoHudText('inform', 'K9 aracı aramaya başladı!')

				local firstCoord = GetOffsetFromEntityInWorldCoords(veh, -1.75, 1.75, 0.0)
				TaskGoToCoordAnyMeans(spawnedK9, firstCoord.x, firstCoord.y, firstCoord.z, 5.0, 0, 0, 1, 10.0)
				Citizen.Wait(8000)

				local secondCoord = GetOffsetFromEntityInWorldCoords(veh, -2.0, -2.0, 0.0)
				TaskGoToCoordAnyMeans(spawnedK9, secondCoord.x, secondCoord.y, secondCoord.z, 5.0, 0, 0, 1, 10.0)
				Citizen.Wait(8000)

				local thirdCoord = GetOffsetFromEntityInWorldCoords(veh, 2.0, -2.0, 0.0)
				TaskGoToCoordAnyMeans(spawnedK9, thirdCoord.x, thirdCoord.y, thirdCoord.z, 5.0, 0, 0, 1, 10.0)
				Citizen.Wait(8000)

				local fourthCoord = GetOffsetFromEntityInWorldCoords(veh, 1.75, 1.75, 0.0)
				TaskGoToCoordAnyMeans(spawnedK9, fourthCoord.x, fourthCoord.y, fourthCoord.z, 5.0, 0, 0, 1, 10.0)
				Citizen.Wait(8000)

				Citizen.Wait(5000)
				ClearPedTasks(spawnedK9)
				TaskFollowToOffsetOfEntity(spawnedK9, PlayerPedId(), 0.0, 0.0, 0.0, 5.0, -1, 0.25, 1)
			else
				exports['mythic_notify']:DoHudText('error', 'K9\'un yakınında araç yok!')
			end
		else
			exports['mythic_notify']:DoHudText('error', 'K9\'un yakınında araç yok!')
		end
	elseif command == "rest" then
		if canRest then
			onAction = true
			TriggerEvent("mythic_progressbar:client:progress",{
				name = "pickCotton",
				duration = 3000,
				label = "K9'u dinlenmeye yolluyorsun!",
				useWhileDead = false,
				canCancel = true,
				controlDisables = {
				disableMovement = false,
				disableCarMovement = false,
				disableMouse = false,
				disableCombat = false,
			}, 
			animation = {
				animDict = "mp_common",
				anim = "givetake1_a",
			}
			},function(status)
				if not status then
					DeleteEntity(spawnedK9) spawnedK9 = nil
					onAction = false
					exports['mythic_notify']:DoHudText('inform', 'K9 dinlenmesi için gönderildi!')
				else
					exports['mythic_notify']:DoHudText('error', 'K9\'u göndermeyi iptal ettin!')
				end
			end)
		else
			local playerCoords = GetEntityCoords(PlayerPedId(), false)
			local k9Coords = GetEntityCoords(spawnedK9, false)
			if Vdist2(playerCoords, k9Coords) > 3.0 then
				exports['mythic_notify']:DoHudText('error', 'K9 sana çok uzak!')
			else
				exports['mythic_notify']:DoHudText('error', 'K9\' u burada gönderemezsin!')
			end
		end
	end
	onScene = false
end)

RegisterNetEvent("k9:attack")
AddEventHandler("k9:attack", function (enemy)
	if IsPedAPlayer(enemy) then
		local player = GetPlayerFromServerId(GetplayerId(enemy))
		TaskPutPedDirectlyIntoMelee(spawnedK9, GetPlayerPed(player), 0.0, -1.0, 0.0, false)
	else
		TaskPutPedDirectlyIntoMelee(spawnedK9, enemy, 0.0, -1.0, 0.0, false)
	end
	exports['mythic_notify']:DoHudText('inform', 'K9 saldırıyor!')
end)

RegisterNetEvent("k9:illegalItems")
AddEventHandler("k9:illegalItems", function (hasIllegalItem)
	if hasIllegalItem then
		PlayAnim("missfra0_chop_find", "chop_bark_at_ballas")
		exports['mythic_notify']:DoHudText('inform', 'Aranan kişide illegal madde bulundu!')
		Citizen.Wait(5000)
		ClearPedTasks(spawnedK9)
		TaskFollowToOffsetOfEntity(spawnedK9, PlayerPedId(), 0.0, 0.0, 0.0, 5.0, -1, 0.25, 1)
	else
		exports['mythic_notify']:DoHudText('inform', 'Aranan kişide illegal madde bulunamadı!')
	end
end)

function PlayAnim(animDict, anim)
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(1)
	end
	TaskPlayAnim(spawnedK9, animDict, anim, 8.0, 8.0, -1, 2, 0.0, false, false, false)
end

function AddBlip()
	local blip = AddBlipForEntity(spawnedK9)
	SetBlipAsFriendly(blip, true)
	SetBlipSprite(blip, 1)
	SetBlipColour(blip, 29)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("[K9] Garip Kont")
	EndTextCommandSetBlipName(blip)
	NetworkRegisterEntityAsNetworked(spawnedK9)
	while not NetworkGetEntityIsNetworked(spawnedK9) do
		NetworkRegisterEntityAsNetworked(spawnedK9)
		Citizen.Wait(1)
	end
end

local isK9MenuOpen = false
local isK9ControlMenuOpen = false

local options = {
	{label = "Get a K9", value = "spawnK9"},
}

local optionsControl = {
	{label = "Follow!", value = "follow"},
	{label = "Stop!", value = "stop"},
	{label = "Sit!", value = "sit"},
	{label = "Barf!", value = "barf"},
	{label = "Attack! (Aim at player then press 'H')", value = "attack"},
	{label = "Search player!", value = "searchplayer"},
	{label = "Search vehicle!", value = "searchvehicle"},
	{label = "Get in / out the car!", value = "getInOutCar"},
	{label = "Send K9 to rest!", value = "rest"}
}


function K9Menu()
	isK9MenuOpen = true
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'general_menu',{
		title = "K9 Panel v1.0",
		align = "top-left",
		elements = options
	}, function (data, menu) -- Select item
		menu.close()
		isK9MenuOpen = false
		if data.current.value == 'spawnK9' then
			TriggerEvent("k9:spawnK9")
		end
	end,
	function (data,menu) -- Close menu
		menu.close()
		isK9MenuOpen = false
	end)
end

function K9ControlMenu()
	isK9ControlMenuOpen = true
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'general_menu',{
		title = "K9 Panel v1.0",
		align = "top-left",
		elements = optionsControl
	}, function (data, menu) -- Select item
		menu.close()
		isK9ControlMenuOpen = false
		TriggerEvent("k9:command", data.current.value)
	end,
	function (data,menu) -- Close menu
		menu.close()
		isK9ControlMenuOpen = false
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsControlJustPressed(1, Keys["H"]) and IsPlayerFreeAiming(PlayerId()) and spawnk9 ~= nil then
			local isAiming, enemy = GetEntityPlayerIsFreeAimingAt(PlayerId())
			if isAiming then
				TriggerEvent("k9:attack", enemy)
			end
		end

		if IsControlJustPressed(1, Keys["X"]) and not IsPlayerFreeAiming(PlayerId()) then
			ClearPedTasksImmediately(spawnedK9)
			TaskFollowToOffsetOfEntity(spawnedK9, PlayerPedId(), 0.0, 0.0, 0.0, 5.0, -1, 10.0, 1)
		end

	end
end)

Citizen.CreateThread(function ()
	while true do
		Citizen.Wait(10)
		if spawnedK9 ~= nil and IsEntityDead(spawnedK9) then Citizen.Wait(1500) DeleteEntity(spawnedK9) spawnedK9 = nil end
		if IsControlJustReleased(1, Keys["Y"]) and PlayerData.job.name == Config.Job and PlayerData.job.grade >= Config.Grade and not isK9MenuOpen and spawnedK9 == nil and canSpawn and not onAction then
			K9Menu()
		elseif IsControlJustReleased(1, Keys["Y"]) and PlayerData.job.name == Config.Job and PlayerData.job.grade >= Config.Grade and spawnedK9 ~= nil and not onAction then
			K9ControlMenu()
		end
	end
end)

Citizen.CreateThread(function ()
	while true do
		Citizen.Wait(1)
		if not Config.isSpawningOpen then canRest = true canSpawn = true return end
		for k,v in pairs(Config.Spawning_Points) do
			DrawMarker(v.type, v.x, v.y, v.z-1, 0, 0, 0, 0, 0, 0, v.scale, v.scale, v.scale, v.r, v.g, v.b, v.a, false, true, 2, nil, nil, false)
			local playerCoords = GetEntityCoords(PlayerPedId(), false)
			local markerVector = vector3(v.x, v.y, v.z)
			if Vdist2(playerCoords, markerVector) < v.scale * 1.12 then
				canSpawn = true
			else
				canSpawn = false
			end
			if spawnedK9 ~= nil then
				local k9Coords = GetEntityCoords(spawnedK9, false)
				if Vdist2(k9Coords, markerVector) < v.scale * 1.12 and Vdist2(playerCoords, markerVector) < v.scale * 1.12 then
					canRest = true
				else 
					canRest = false
				end
			end
		end		
	end
end)