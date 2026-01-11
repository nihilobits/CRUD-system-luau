local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Config = require(script:WaitForChild("Config"))
local DataStoreModule = require(script:WaitForChild("DataStoreModule"))
local IncidentManager = require(script:WaitForChild("IncidentManager")).new()
local HistoryModule = require(script:WaitForChild("HistoryModule")).new()
local JailModule = require(script:WaitForChild("JailModule")).new()
local RemoteService = require(script:WaitForChild("RemoteService"))
local PoliceService = require(script:WaitForChild("PoliceService"))
local AdminService = require(script:WaitForChild("CommandModule"))
local dataStore = DataStoreModule.new()
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local LoginRemote = remoteEvents:WaitForChild("LoginRemote")
local LogoutRemote = remoteEvents:WaitForChild("LogoutRemote")
local AFKRemote = remoteEvents:WaitForChild("AFKRemote")
local registerCommand = TextChatService:WaitForChild("ZarejestrujCommand")
local awansCommand = TextChatService:WaitForChild("AwansCommand")
local ArrestRemote = remoteEvents:WaitForChild("ArrestRemote")


task.spawn(function()
	while task.wait(1) do
		IncidentManager:CheckIncidents()
		JailModule:UpdateJails(1)
	end
end)


Players.PlayerAdded:Connect(function(player)
	dataStore:getData(player.UserId)
	HistoryModule:getData(player.UserId)
	dataStore:UpdateGlobalCopsCount()
	JailModule:CheckAndArrest(player.UserId,reason, HistoryModule)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		local userData = dataStore:getCache(player.UserId)
		if userData and userData.isLoggedIn then
			PoliceService:HandleLogout(player, dataStore, LogoutRemote)
		end
	end)

	player.CharacterAdded:Connect(function(character)
		if JailModule.ActiveJails[tostring(player.UserId)] then
			task.wait(0.5)
			JailModule:TeleportToJail(player)
		end
	end)
end)


local function handlePlayerLeaving(player)
	local jailData = JailModule.ActiveJails[tostring(player.UserId)]
	if jailData	then
		if jailData.timeLeft then
			JailModule:SaveToStore(player.UserId, jailData.timeLeft, jailData.reason)
		end
	end
	
	local userData = dataStore:getCache(player.UserId)
	if userData and userData.isLoggedIn then
		PoliceService:HandleLogout(player, dataStore, LogoutRemote)
	end

	HistoryModule:saveAndClear(player.UserId)
	dataStore:clearData(player.UserId)
end


game.Players.PlayerRemoving:Connect(handlePlayerLeaving)
game:BindToClose(function()
	for _, player in ipairs(game.Players:GetPlayers()) do
		handlePlayerLeaving(player)
	end
end)


LoginRemote.OnServerEvent:Connect(function(player, lastname, password)
	PoliceService:HandleLogin(player, lastname, password, dataStore, LoginRemote)
end)


LogoutRemote.OnServerEvent:Connect(function(player)
	PoliceService:HandleLogout(player, dataStore, LogoutRemote)
end)


AFKRemote.OnServerEvent:Connect(function(player)
	local userData = dataStore:getCache(player.UserId)
	if not userData or userData.isLoggedIn ~= true then return end
	if userData.status == "inservice" then
		dataStore:ChangeStatus(player, "AFK")
		PoliceService:SendDiscordLog("AFK", "Funkcjonariusz przeszedł na przerwę.", Config.COLORS.WARNING, player.Name, player.UserId)
	else
		dataStore:ChangeStatus(player, "inservice")
		PoliceService:SendDiscordLog("AFK", "Funkcjonariusz powrócił z przerwy.", Config.COLORS.WARNING, player.Name, player.UserId)
	end
end)


registerCommand.Triggered:Connect(function(originatingTextSource, unfilteredText)
	AdminService:ProcessRegister(unfilteredText, originatingTextSource.UserId, dataStore)
end)


awansCommand.Triggered:Connect(function(originatingTextSource, unfilteredText)
	AdminService:ProcessPromotion(unfilteredText, originatingTextSource.UserId, dataStore)
end)


remoteEvents.AddEntryRemote.OnServerInvoke = function(player, mode, targetUID, reason, value)
	local success, result, msg = pcall(function()
		if not dataStore or not HistoryModule then
			error("TabletServer: No modules sent to HandleAddEntry!")
		end
		return RemoteService:HandleAddEntry(player, mode, targetUID, reason, value, dataStore, HistoryModule)
	end)

	if not success then
		return false, "Internal problem with the server."
	end
	return result, msg
end


remoteEvents.ArrestRemote.OnServerEvent:Connect(function(player, targetPlayer, reason)
	local success, timeInJail = JailModule:CheckAndArrest(targetPlayer, reason, HistoryModule)
end)