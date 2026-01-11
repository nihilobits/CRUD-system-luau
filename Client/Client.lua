local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local UIManager = require(script:WaitForChild("UIManager"))
local IncidentManager = require(script:WaitForChild("IncidentManager"))
local DatabaseManager = require(script:WaitForChild("DatabaseManager"))
local NetworkHandler = require(script:WaitForChild("NetworkHandler"))
local FormManager = require(script:WaitForChild("FormManager"))
local RemoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local IncidentRemote = RemoteFolder:WaitForChild("IncidentRemote")
local FeedRemote = RemoteFolder:WaitForChild("FeedRemote")
local LoginRemote = RemoteFolder:WaitForChild("LoginRemote")
local LogoutRemote = RemoteFolder:WaitForChild("LogoutRemote")
local AFKRemote = RemoteFolder:WaitForChild("AFKRemote")
local CopNumberRemote = RemoteFolder:WaitForChild("CopNumberRemote")
local RefreshRemote = RemoteFolder:WaitForChild("RefreshRemote")
local AddEntryRemote = RemoteFolder:WaitForChild("AddEntryRemote")
local ArrestRemote = RemoteFolder:WaitForChild("ArrestRemote")
local buttonMap = {
	[UIManager.GetUI("MainFrame/SidebarFrame/SideButtonsFrame/MainMenuButton")] = UIManager.GetUI("MainFrame/MenuFrame"),
	[UIManager.GetUI("MainFrame/SidebarFrame/SideButtonsFrame/CopsButton")] = UIManager.GetUI("MainFrame/CopsFrame"),
	[UIManager.GetUI("MainFrame/SidebarFrame/SideButtonsFrame/DatabaseButton")] = UIManager.GetUI("MainFrame/DatabaseFrame"),
	[UIManager.GetUI("MainFrame/SidebarFrame/SideButtonsFrame/EventsButton")] = UIManager.GetUI("MainFrame/EventsFrame"),
	[UIManager.GetUI("MainFrame/SidebarFrame/SideButtonsFrame/FormsButton")] = UIManager.GetUI("MainFrame/FormsFrame"),
	[UIManager.GetUI("MainFrame/MenuFrame/NewsAndEventsFrame/NewsFrame/BottomFrame/RightButtonsFrame/WriteCheckButton")] = UIManager.GetUI("MainFrame/FormsFrame"),
	[UIManager.GetUI("MainFrame/MenuFrame/NewsAndEventsFrame/NewsFrame/BottomFrame/RightButtonsFrame/CheckCarButton")] = UIManager.GetUI("MainFrame/DatabaseFrame")
}


for button, frame in pairs(buttonMap) do
	button.MouseButton1Click:Connect(function()
		UIManager.SwitchFrame(buttonMap, frame)
	end)
end


UIManager.GetUI("MainFrame/TopbarFrame/UserMenuButton").MouseButton1Click:Connect(function()
	local dropdown = UIManager.GetUI("MainFrame/UserDropdownFrame")
	dropdown.Visible = not dropdown.Visible
end)


local options = UIManager.GetUI("MainFrame/FormsFrame/TopFrame/OptionsFrame")
options.FineButton.MouseButton1Click:Connect(function() FormManager.SetMode("Fine") end)
options.WantedButton.MouseButton1Click:Connect(function() FormManager.SetMode("Wanted") end)
options.SentenceButton.MouseButton1Click:Connect(function() FormManager.SetMode("Sentence") end)

UIManager.GetUI("MainFrame/FormsFrame/MainFormFrame/SubmitButton").MouseButton1Click:Connect(function()
	FormManager.Submit(AddEntryRemote, ArrestRemote)
end)


UIManager.GetUI("LoginFrame/InnerLoginFrame/LoginButton").MouseButton1Click:Connect(function()
	LoginRemote:FireServer(
		UIManager.GetUI("LoginFrame/InnerLoginFrame/LastNameTextBox").Text,
		UIManager.GetUI("LoginFrame/InnerLoginFrame/PasswordTextBox").Text
	)
end)


UIManager.GetUI("MainFrame/UserDropdownFrame/LogoutButton").MouseButton1Click:Connect(function()
	LogoutRemote:FireServer()
end)

local isAFK = false
UIManager.GetUI("MainFrame/UserDropdownFrame/AFKButton").MouseButton1Click:Connect(function()
	isAFK = not isAFK
	UIManager.GetUI("MainFrame/UserDropdownFrame/AFKButton/AFKLabel").Text = isAFK and "Return to Duty" or "Go on Break"
	AFKRemote:FireServer()
end)


IncidentRemote.OnClientEvent:Connect(IncidentManager.ProcessIncident)
LoginRemote.OnClientEvent:Connect(NetworkHandler.HandleLogin)
LogoutRemote.OnClientEvent:Connect(function()
	UIManager.GetUI("MainFrame").Visible = false
	UIManager.GetUI("LoginFrame").Visible = true
end)


CopNumberRemote.OnClientEvent:Connect(function(active, total, list)
	NetworkHandler.UpdateCops(active, total, list, script:WaitForChild("CopInformationFrame"))
end)


RefreshRemote.OnClientEvent:Connect(function(db)
	DatabaseManager.Refresh(db, script:WaitForChild("DatabaseEntry"))
end)

local isOpen = false
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or game.Players.LocalPlayer.Team ~= game.Teams.Policja then return end
	if input.KeyCode == Enum.KeyCode.Q and game.Players.LocalPlayer.Character:WaitForChild("Humanoid").Health > 0 then
		UIManager.ToggleMainUI()
		isOpen = not isOpen
	end
end)


task.spawn(function()
	while task.wait(1) do
		local timeLabel = UIManager.GetUI("MainFrame/MenuFrame/NewsAndEventsFrame/NewsFrame/BottomFrame/TimeFrame/TimeLabel")
		if timeLabel then timeLabel.Text = os.date("%H:%M:%S") end
	end
end)


game.Players.LocalPlayer.Character:WaitForChild("Humanoid").Died:Connect(function()
	if isOpen then
		UIManager.ToggleMainUI()
		isOpen = false
	end
end)

game.Players.LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	if isOpen then
		UIManager.ToggleMainUI()
		isOpen = false
	end
end)


local function setupCategory(btnPath, category)
	local btn = UIManager.GetUI(btnPath)
	btn.MouseButton1Click:Connect(function()
		DatabaseManager.ActiveCategories[category] = not DatabaseManager.ActiveCategories[category]
		btn.BackgroundColor3 = DatabaseManager.ActiveCategories[category] and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(255, 255, 255)
		DatabaseManager.UpdateFilters()
	end)
end


UIManager.GetUI("MainFrame/DatabaseFrame/FiltersFrame/UIDSearch"):GetPropertyChangedSignal("Text"):Connect(function()
	DatabaseManager:UpdateFilters()
end)
setupCategory("MainFrame/DatabaseFrame/FiltersFrame/InnerFilterFrame/CarsButton", "Cars")
setupCategory("MainFrame/DatabaseFrame/FiltersFrame/InnerFilterFrame/ArrestsButton", "Wanted")
setupCategory("MainFrame/DatabaseFrame/FiltersFrame/InnerFilterFrame/FinesButton", "Fine")
setupCategory("MainFrame/DatabaseFrame/FiltersFrame/InnerFilterFrame/SentenceButton", "Sentence")

UIManager.GetUI("MainFrame/MenuFrame/NewsAndEventsFrame/NewsFrame/NewsFrame/TextLabel").LayoutOrder = -2147483648
FeedRemote.OnClientEvent:Connect(function(message: string)
	local container = UIManager.GetUI("MainFrame/MenuFrame/NewsAndEventsFrame/NewsFrame/NewsFrame")
	local newFeed = script.NewsFeedFrame:Clone()
	newFeed.FeedLabel.Text = message
	newFeed.timestamp.Text = os.date("%H:%M:%S")
	newFeed.LayoutOrder = -os.time() 
	newFeed.Parent = container
	local allFeeds = {}

	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") or child.Name == "NewsFeedFrame" then
			table.insert(allFeeds, child)
		end
	end
	table.sort(allFeeds, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	if #allFeeds > 3 then
		for i = 4, #allFeeds do
			allFeeds[i]:Destroy()
		end
	end
end)