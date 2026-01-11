local RemoteService = {}


function RemoteService:HandleAddEntry(player, mode, targetUID, reason, value, dataStore, HistoryModule)
	local copData = dataStore:getCache(player.UserId)

	if not copData or not copData.isLoggedIn or copData.status ~= "inservice" then
		return false, "Musisz być zalogowany i na służbie!"
	end

	local targetData = dataStore:getCache(targetUID)
	if not targetData then
		return false, "Obywatel o tym PESEL nie istnieje w bazie!"
	end

	if mode == "Fine" then
		HistoryModule:addEntry(targetUID, "Fine", value, reason, false)
	elseif mode == "Wanted" then
		HistoryModule:addEntry(targetUID, "Wanted", value, reason, true)
	elseif mode == "Sentence" then
		HistoryModule:addEntry(targetUID, "Sentence", value, reason, true)
	end

	return true
end


return RemoteService