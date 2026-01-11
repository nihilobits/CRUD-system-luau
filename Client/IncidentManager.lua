local IncidentManager = {}
local UIManager = require(script.Parent.UIManager)
local activeIncidents = {}
local currentIncidentOrder = 0
local MainScript = script.Parent
local templatesMap = {
	Car      = { Menu = MainScript:WaitForChild("CarEventFrame"),       Full = MainScript:WaitForChild("FullAccidentFrame") },
	Fight    = { Menu = MainScript:WaitForChild("FightEventFrame"),     Full = MainScript:WaitForChild("FullFightFrame")    },
	Theft    = { Menu = MainScript:WaitForChild("TheftEventFrame"),     Full = MainScript:WaitForChild("FullTheftFrame")    },
	Shooting = { Menu = MainScript:WaitForChild("ShootingEventFrame"),  Full = MainScript:WaitForChild("FullShootingFrame") },
}


function IncidentManager.UpdateArchiveToPast(incidentID)
	local list = UIManager.GetUI("MainFrame/EventsFrame/EventsListFrame")
	local fullFrame = list:FindFirstChild("Full_" .. incidentID)
	if fullFrame then
		local title = fullFrame.TitleLabel
		title.Text = string.gsub(title.Text, "Active", "Outdated")
		title.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end


function IncidentManager.ProcessIncident(action, data, numberOfEvents)
	local menuContainer = UIManager.GetUI("MainFrame/MenuFrame/NewsAndEventsFrame/NewEventsFrame/EventInnerFrame")
	local countLabel = UIManager.GetUI("MainFrame/MenuFrame/StatsFrame/CurrentEventsFrame/NumberOfEventsLabel")
	countLabel.Text = numberOfEvents
	if action == "NewIncident" then
		local templates = templatesMap[data.Type]
		if not templates then return end
		local clonedMenu = templates.Menu:Clone()
		local clonedFull = templates.Full:Clone()
		currentIncidentOrder -= 1
		table.insert(activeIncidents, data)
		clonedMenu.Name = tostring(data.ID)
		clonedMenu.TitleLabel.Text = data.Name
		clonedMenu.PositionLabel.Text = data.Position
		clonedMenu.LayoutOrder = currentIncidentOrder
		clonedMenu.Parent = menuContainer
		clonedFull.Name = "Full_" .. data.ID
		clonedFull.TitleLabel.Text = string.format("%s - %s - Active", data.Name, os.date("%H:%M"))
		clonedFull.PositionLabel.Text = string.format("%s - ID: %s", data.Position, data.ID)
		clonedFull.TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		clonedFull.LayoutOrder = currentIncidentOrder
		clonedFull.Parent = UIManager.GetUI("MainFrame/EventsFrame/EventsListFrame")
		if #activeIncidents > 5 then
			local old = table.remove(activeIncidents, 1)
			local oldFrame = menuContainer:FindFirstChild(tostring(old.ID))
			if oldFrame then oldFrame:Destroy() end
		end
	elseif action == "RemoveIncident" then
		local id = tostring(data.ID or data)
		local menuFrame = menuContainer:FindFirstChild(id)
		if menuFrame then menuFrame:Destroy() end
		IncidentManager.UpdateArchiveToPast(id)
	end
end

return IncidentManager