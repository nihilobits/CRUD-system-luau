local DatabaseManager = {}
local UIManager = require(script.Parent.UIManager)

DatabaseManager.ActiveCategories = { ["Cars"] = false, ["Wanted"] = false, ["Sentence"] = false, ["Fine"] = false }

function DatabaseManager.UpdateFilters()
	local container = UIManager.GetUI("MainFrame/DatabaseFrame/EventsListFrame")
	local searchInput = UIManager.GetUI("MainFrame/DatabaseFrame/FiltersFrame/UIDSearch")
	local searchText = searchInput.Text:lower()

	local anySelected = false
	for _, active in pairs(DatabaseManager.ActiveCategories) do
		if active then anySelected = true break end
	end

	for _, row in pairs(container:GetChildren()) do
		if row:IsA("GuiObject") then
			local matchesUID = searchText == "" or string.find(row.UIDLabel.Text:lower(), searchText)
			local matchesCat = not anySelected or DatabaseManager.ActiveCategories[row.TypeLabel.Text]
			row.Visible = matchesUID and matchesCat
		end
	end
end

function DatabaseManager.Refresh(fullDatabase, template)
	local container = UIManager.GetUI("MainFrame/DatabaseFrame/EventsListFrame")
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	for userId, history in pairs(fullDatabase) do
		for _, entry in pairs(history) do
			local row = template:Clone()
			row.UIDLabel.Text = tostring(userId)
			row.TypeLabel.Text = entry.Type
			row.ReasonLabel.Text = entry.Reason
			row.ValueLabel.Text = tostring(entry.Value)

			if entry.IsWanted then
				row.TimeLabel.Text = "WANTED"
				row.TimeLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
				row.LayoutOrder = -2000000000 + (os.time() - entry.Timestamp)
			else
				row.TimeLabel.Text = os.date("%H:%M", entry.Timestamp)
				row.LayoutOrder = -entry.Timestamp
			end
			row.Parent = container
		end
	end
	DatabaseManager.UpdateFilters()
end

return DatabaseManager