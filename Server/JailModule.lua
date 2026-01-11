--!strict
local JailModule = {}
JailModule.__index = JailModule

local DataStoreService = game:GetService("DataStoreService")
local arrestRemote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ArrestRemote")
local Players = game:GetService("Players")
local Instance = nil
local jailpart = "JailPart"
local outofjailpart = "OutOfJailPart"
local datastorename = "JailDataStore_v1"

function JailModule.new()
	if Instance then return Instance end
	local self = setmetatable({}, JailModule)
	self.JailStore = DataStoreService:GetDataStore(datastorename)
	self.ActiveJails = {} 
	Instance = self
	return self
end

function JailModule:CheckAndArrest(userId: number, reason: string, historyModule: any)
	local history = historyModule:getCache(userId)
	local totalSeconds = 0
	local foundInHistory = false

	if history then
		for i, entry in ipairs(history) do
			if entry.IsWanted == true or entry.IsWanted == "true" then
				local val = tonumber(entry.Value)
				if val then
					totalSeconds += val
					foundInHistory = true
				end
			end
		end
	end

	local savedData = self:GetSavedData(userId)

	if totalSeconds <= 0 and savedData then
		totalSeconds = savedData.time or 0
		reason = savedData.reason or reason
	end

	if totalSeconds > 0 then
		self:Arrest(userId, reason, totalSeconds)
		if foundInHistory then
			historyModule:removeWantedStatus(userId)
		end
		return true, totalSeconds
	end
	return false, "JailModule: No wanted status or saved time found for " .. userId
end

function JailModule:Arrest(UID: number, reason: string, duration: number)
	local sUID = tostring(UID)
	self.ActiveJails[sUID] = {timeLeft = duration, reason = reason}
	self:TeleportToJail(UID)

	local player = Players:GetPlayerByUserId(UID)
	if player then
		arrestRemote:FireClient(player, reason, duration)
	end

	self:SaveToStore(UID, duration, reason)
end

function JailModule:TeleportToJail(userId: number)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local jailPart = workspace:FindFirstChild(jailpart)
	if not jailPart then return end

	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")
	task.defer(function()
		root.CFrame = jailPart.CFrame + Vector3.new(0, 3, 0)
	end)
end

function JailModule:TeleportOutOfJail(userId: number)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local exitPart = workspace:FindFirstChild(outofjailpart)
	if not exitPart then return end

	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		task.defer(function()
			character.HumanoidRootPart.CFrame = exitPart.CFrame + Vector3.new(0, 3, 0)
		end)
	end
end

function JailModule:SaveToStore(userId: number, time: number, reason: string)
	pcall(function()
		if time > 0 then
			self.JailStore:SetAsync(tostring(userId), {time = math.floor(time), reason = reason})
		else
			self.JailStore:RemoveAsync(tostring(userId))
		end
	end)
end

function JailModule:GetSavedData(userId: number)
	local success, result = pcall(function()
		return self.JailStore:GetAsync(tostring(userId))
	end)
	return if success then result else nil
end

function JailModule:UpdateJails(dt: number)
	for sUID, data in pairs(self.ActiveJails) do
		local newTime = data.timeLeft - dt
		local player = Players:GetPlayerByUserId(tonumber(sUID))

		if newTime <= 0 then
			self.ActiveJails[sUID] = nil
			if player then 
				self:TeleportOutOfJail(tonumber(sUID)) 
				self:SaveToStore(player.UserId, 0, "") 
			end
		else
			self.ActiveJails[sUID].timeLeft = newTime
			if player and player.Character then
				local root = player.Character:FindFirstChild("HumanoidRootPart")
				local jailPart = workspace:FindFirstChild(jailpart)
				if root and jailPart and (root.Position - jailPart.Position).Magnitude > 30 then
					self:TeleportToJail(tonumber(sUID))
				end
			end
		end
	end
end

return JailModule