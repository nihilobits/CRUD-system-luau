local NetworkHandler = {}
local UIManager = require(script.Parent.UIManager)


function NetworkHandler.HandleLogin(status, name, lastName, rank)
	local loginFrame = UIManager.GetUI("LoginFrame")
	local mainFrame = UIManager.GetUI("MainFrame")
	local errorLabel = UIManager.GetUI("LoginFrame/InnerLoginFrame/ErrorLabel")

	if status then
		UIManager.GetUI("MainFrame/TopbarFrame/UserMenuButton/NameFrame/NameRankLabel").Text = name.." - "..rank
		UIManager.GetUI("MainFrame/TopbarFrame/UserMenuButton/NameFrame/LastNameLabel").Text = lastName
		loginFrame.Visible = false
		mainFrame.Visible = true
		errorLabel.Text = ""
	else
		errorLabel.Text = "Incorrect password, please try again."
	end
end


function NetworkHandler.UpdateCops(active, total, list, infoTemplate)
	local container = UIManager.GetUI("MainFrame/CopsFrame/CopsListFrame")
	UIManager.GetUI("MainFrame/MenuFrame/StatsFrame/ActiveCopsFrame/ActiveCopsLabel").Text = tostring(active)
	UIManager.GetUI("MainFrame/MenuFrame/StatsFrame/CopsOverallFrame/CopsOverallLabel").Text = tostring(total)

	for _, child in pairs(container:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	for _, v in pairs(list) do
		local cloned = infoTemplate:Clone()
		cloned.CopNameLabel.Text = v[1] .. " " .. v[2]
		cloned.CopStatusLabel.Text = (v[3] == "inservice") and "On Duty" or "AFK"
		cloned.Parent = container
	end
end

return NetworkHandler