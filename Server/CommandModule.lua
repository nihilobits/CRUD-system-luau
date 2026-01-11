local CommandModule = {}
local Players = game:GetService("Players")
local Config = require(script.Parent:WaitForChild("Config"))


function CommandModule:CanUseCommand(playerUID)
	return table.find(Config.AUTHORIZED_COPS, playerUID) ~= nil
end


function CommandModule:GetRankIndex(rankName)
	if not rankName or rankName == "" then return 0 end
	for i, v in ipairs(Config.RANKS) do
		if v == rankName then
			return i
		end
	end
	return 0
end


function CommandModule:ProcessRegister(unfilteredText, adminId, dataStore)
	if not self:CanUseCommand(adminId) then return end
	local args = string.split(unfilteredText, " ")
	local targetName, firstName, lastName, password = args[2], args[3], args[4], args[5]
	if not (targetName and firstName and lastName and password) then return end
	local targetId = nil
	local onlinePlayer = Players:FindFirstChild(targetName)
	if onlinePlayer then targetId = onlinePlayer.UserId
	else
		local success, fetchedId = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
		if success then targetId = fetchedId end
	end
	if targetId then
		local userData = dataStore:getData(targetId)
		userData.name = firstName
		userData.surname = lastName
		userData.password = password
		userData.isDefaultData = false
		userData.rank = Config.RANKS[1]
		dataStore:saveData(targetId, userData)
	end
end


function CommandModule:ProcessPromotion(unfilteredText, adminId, dataStore)
	if not self:CanUseCommand(adminId) then return end
	local args = string.split(unfilteredText, " ")
	local targetName = args[2] or args[1]
	if not targetName or targetName == "" then return end
	local targetId = nil
	local onlinePlayer = Players:FindFirstChild(targetName)
	if onlinePlayer then targetId = onlinePlayer.UserId
	else
		local success, fetchedId = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
		if success then targetId = fetchedId end
	end
	if not targetId or (targetId == adminId and adminId ~= -1) then return end
	local adminData = dataStore:getData(adminId)
	local targetData = dataStore:getData(targetId)
	local adminRankIndex = self:GetRankIndex(adminData.rank)
	if self:CanUseCommand(adminId) then adminRankIndex = 999 end
	local targetRankIndex = self:GetRankIndex(targetData.rank)
	local nextRankIndex = targetRankIndex + 1
	if nextRankIndex <= #Config.RANKS and nextRankIndex < adminRankIndex then
		targetData.rank = Config.RANKS[nextRankIndex]
		dataStore:saveData(targetId, targetData)
		dataStore:UpdateGlobalCopsCount()
	else
		warn("CommandModule: Cannot rank up due to current hierarchy or no permissions.")
	end
end


return CommandModule