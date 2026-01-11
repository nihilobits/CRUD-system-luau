--! strict
local DataStoreModule = {}
DataStoreModule.__index = DataStoreModule
local Instance = nil
local maxRetries = 3
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CopNumberRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CopNumberRemote")
local defaultData = {
	isDefaultData = true,
	name = "",
	surname = "",
	rank = "",
	password = "",
	isLoggedIn = false,
	status = "outofservice",
}


function DataStoreModule.new()
	if Instance then return Instance end
	local self = setmetatable({}, DataStoreModule)
	self.DataStoreService = game:GetService("DataStoreService")
	self.DataStore = self.DataStoreService:GetDataStore("TabletDataStore_v1")
	self.data = {}
	Instance = self
	return self
end


function DataStoreModule:getData(UID: number)
	local sUID: string = tostring(UID)
	if self.data[sUID] then return self.data[sUID] end
	local retries: number = 0
	while retries < maxRetries do
		local success, result = pcall(function() return self.DataStore:GetAsync(sUID) end)
		if success then
			if result == nil then
				local newData = table.clone(defaultData)
				self.data[sUID] = newData
				return newData
			else
				self.data[sUID] = result
				return result
			end
		else
			retries += 1
			task.wait(1)
		end
	end
	local fallbackData = table.clone(defaultData)
	self.data[sUID] = fallbackData
	return fallbackData
end


function DataStoreModule:getCache(UID: number)
	return self.data[tostring(UID)]
end


function DataStoreModule:saveData(UID: number, data: {})
	local sUID = tostring(UID)
	local retries = 0
	while retries < maxRetries do
		local success, err = pcall(function() self.DataStore:SetAsync(sUID, data) end)
		if success then
			self.data[sUID] = data
			return true
		else
			retries += 1
			task.wait(1)
		end
	end
	return false
end


function DataStoreModule:clearData(UID: number)
	self.data[tostring(UID)] = nil
end


function DataStoreModule:GetCops()
	local cops = {}
	for uid, userData in pairs(self.data) do
		if userData.isLoggedIn then
			table.insert(cops, {
				userData.name or "Unknown", 
				userData.surname or "User", 
				userData.status or "outofservice"
			})
		end
	end
	return cops
end


function DataStoreModule:UpdateGlobalCopsCount()
	local activeCops = 0
	local allCops = 0
	for _, userData in pairs(self.data) do
		if userData.isLoggedIn == true then
			allCops += 1
			if userData.status == "inservice" then activeCops += 1 end
		end
	end
	local copsList = self:GetCops()
	CopNumberRemote:FireAllClients(activeCops, allCops, copsList)
end


function DataStoreModule:ChangeStatus(player: Player, newStatus: string)
	local data = self:getCache(player.UserId)
	if data then
		data.status = newStatus
		self:UpdateGlobalCopsCount()
		return true
	end
	return false
end


return DataStoreModule