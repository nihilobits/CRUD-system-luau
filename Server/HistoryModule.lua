--!strict
type HistoryEntry = {
	Type: string,
	Value: any,
	Reason: string,
	Timestamp: number,
	IsWanted: boolean
}


local HistoryDataModule = {}
HistoryDataModule.__index = HistoryDataModule
local Instance: any = nil
local MaxRetries = 3
local HistoryStoreName = "PlayerHistoryStore"
local DataStoreService = game:GetService("DataStoreService")
local RefreshRemote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RefreshRemote")
HistoryDataModule.cache = {} :: { [string]: { HistoryEntry } }
local PoliceService = require(script.Parent:WaitForChild("PoliceService"))
local JailModule = require(script.Parent:WaitForChild("JailModule")).new()
local EconomyModule = require(game:GetService("ServerScriptService"):WaitForChild("EconomyServer"):WaitForChild("Economy"))

function HistoryDataModule.new()
	if Instance then return Instance end
	
	local self = setmetatable({}, HistoryDataModule)
	Instance = self
	self.HistoryStore = DataStoreService:GetDataStore(HistoryStoreName)
	
	return self
end


function HistoryDataModule:getData(userId: number): { HistoryEntry }
	local key = tostring(userId)
	local retries = 0

	while retries < MaxRetries do
		local success, result = pcall(function()
			return self.HistoryStore:GetAsync(key)
		end)
		if success then
			local dataToCache = (result or {}) :: {HistoryEntry}
			if type(dataToCache) == "table" then
				self.cache[key] = dataToCache
				self:broadcastUpdate()
				return dataToCache
			else
				warn("HistoryDataModule: data corrupted for: " .. key .. ". Loading empty table.")
				self.cache[key] = {}
				return {}
			end
		else
			retries += 1
			warn("HistoryDataModule: getAsync failed for " .. key .. ". Retrying (" .. retries .. "/" .. MaxRetries .. ")")
			if retries < MaxRetries then
				task.wait(2^retries)
			end
		end
	end

	warn("HistoryDataModule: getAsync failed after " .. MaxRetries .. " retries for " .. key .. ". Loading empty table.")
	self.cache[key] = self.cache[key] or {}
	
	return self.cache[key]
end


function HistoryDataModule:getCache(userId: number)
	return self.cache[tostring(userId)] or self:getData(userId)
end


function HistoryDataModule:saveData(userId: number)
	local key : string = tostring(userId)
	local data : HistoryEntry = self.cache[key]

	if not data then return false end
	local retries : number = 0
	
	while retries < MaxRetries do
		local success : boolean = pcall(function()
			self.HistoryStore:SetAsync(key, data)
		end)
		if success then
			return true
		else
			retries += 1
			warn("HistoryDataModule: saveAsync failed for " .. key .. ". retry: " .. retries)
			if retries < MaxRetries then
				task.wait(2^retries)
			end
		end
	end
	
	return false
end


function HistoryDataModule:saveAndClear(userId: number)
	local key : string = tostring(userId)
	
	if self.cache[key] then
		self:saveData(userId)
		self.cache[key] = nil
		self:broadcastUpdate()
	end
end


function HistoryDataModule:broadcastUpdate()
	local allData = {}
	
	for uid,history in pairs(self.cache) do
		allData[uid] = history
	end
	
	RefreshRemote:FireAllClients(allData)
end


function HistoryDataModule:addEntry(userId: number, entryType: string, value: any, reason: string, isWanted: boolean)
	local key = tostring(userId)
	local history = self.cache[key] or self:getData(userId) or {}

	local newEntry = {
		Type = entryType,
		Value = value,
		Reason = reason or "Brak powodu",
		Timestamp = os.time(),
		IsWanted = isWanted or false
	}
	table.insert(history, newEntry)
	self.cache[key] = history
	self:broadcastUpdate()
	if entryType == "Fine" then
		local targetPlayer = game:GetService("Players"):GetPlayerByUserId(userId)
		if targetPlayer then
			EconomyModule.getHandler(targetPlayer):changeMoney(-value)
		end
	elseif entryType == "Sentence" then
		if JailModule then
			JailModule:CheckAndArrest(userId,reason, self)
		end
	end
	task.spawn(function()
		local playerName = "Nieznany (" .. userId .. ")"
		local player = game:GetService("Players"):GetPlayerByUserId(userId)
		if player then playerName = player.Name end
		if entryType == "Sentence" then
			PoliceService:SendDiscordLog(
				"Wstawiono wyrok:",
				"**Obywatel:** " .. playerName .. "\n**Powód:** " .. (reason or "Brak") .. "\n**czas:** ".. value.."s",
				0xFF0000,
				playerName, 
				userId
			)
		elseif entryType == "Fine" then
			PoliceService:SendDiscordLog(
				"Wystawiono Mandat",
				"**Obywatel:** " .. playerName .. "\n**Kwota:** " .. tostring(value) .. "$\n**Powód:** " .. (reason or "Brak"),
				0xFFA500,
				playerName, 
				userId
			)
		elseif entryType == "Wanted" then
			PoliceService:SendDiscordLog(
				"Wystawiono poszukiwanie",
				"**Obywatel:** " .. playerName .. "\n**Powód:** " .. (reason or "Brak"),
				0xFF0000,
				playerName, 
				userId
			)
		end
	end)
	return true
end

function HistoryDataModule:removeWantedStatus(userId: number)
	local key = tostring(userId)
	local history = (self.cache[key] or self:getData(userId)):: { HistoryEntry }
	local changed = false
	
	for _, entry in ipairs(history) do
		if entry.IsWanted == true then
			entry.IsWanted = false
			changed = true
		end
	end

	if changed then
		self:broadcastUpdate()
		return true
	end

	return false
end


return HistoryDataModule