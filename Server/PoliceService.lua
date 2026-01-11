local PoliceService = {}
local HttpService = game:GetService("HttpService")
local Config = require(script.Parent:WaitForChild("Config"))


function PoliceService:SendDiscordLog(title, description, color, playerName, userId)
	local data = HttpService:JSONEncode({
		["embeds"] = {{
			["title"] = title,
			["description"] = description,
			["color"] = color,
			["footer"] = {
				["text"] = "System Policyjny • " .. os.date("%d/%m/%Y %H:%M:%S")
			},
			["author"] = {
				["name"] = playerName .. " (ID: " .. userId .. ")",
				["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
			}
		}}
	})

	task.spawn(function()
		local success, err = pcall(function()
			HttpService:PostAsync(Config.WEBHOOK_URL, data)
		end)
		if not success then
			warn("Error while sending a webhook: " .. tostring(err))
		end
	end)
end


function PoliceService:HandleLogin(player, lastname, password, dataStore, LoginRemote)
	local userData = dataStore:getCache(player.UserId)
	if userData and userData.isDefaultData == false then
		if userData.password == password and userData.surname == lastname then 
			userData.isLoggedIn = true
			userData.status = "inservice"
			self:SendDiscordLog("Rozpoczęcie służby", "Funkcjonariusz zalogował się do systemu i rozpoczął służbę.", Config.COLORS.SUCCESS, player.Name, player.UserId)
			LoginRemote:FireClient(player, true, userData.name, userData.surname, userData.rank)
			dataStore:UpdateGlobalCopsCount()
		else
			LoginRemote:FireClient(player, false)
		end
	end
end


function PoliceService:HandleLogout(player, dataStore, LogoutRemote)
	local userData = dataStore:getCache(player.UserId)
	if userData and userData.isLoggedIn == true then
		userData.status = "outofservice"
		userData.isLoggedIn = false
		self:SendDiscordLog("Zakończenie służby", "Funkcjonariusz wylogował się i opuścił służbę.", Config.COLORS.ERROR, player.Name, player.UserId)
		
		pcall(function()
			LogoutRemote:FireClient(player)
		end)
		
		dataStore:UpdateGlobalCopsCount()
		dataStore:saveData(player.UserId, userData)
	end
end


return PoliceService