local FormManager = {}
local UIManager = require(script.Parent.UIManager)
local currentMode = "Fine"


function FormManager.UpdateUI()
	local mainForm = UIManager.GetUI("MainFrame/FormsFrame/MainFormFrame")
	local valueInput = mainForm:WaitForChild("ValueTextBox")
	local valueLabel = mainForm:WaitForChild("ValueLabel")
	local reasonInput = mainForm:WaitForChild("ReasonTextBox")
	local errorLabel = mainForm:WaitForChild("ErrorLabel")

	errorLabel.Text = ""
	valueInput.Visible = true
	valueLabel.Visible = true

	if currentMode == "Fine" then
		valueLabel.Text = "Wysokość kary finansowej"
		valueInput.PlaceholderText = "Wysokość kary finansowej"
		reasonInput.PlaceholderText = "Powód wydania kary"
	elseif currentMode == "Sentence" then
		valueLabel.Text = "Długość odsiadki"
		valueInput.PlaceholderText = "Czas odsiadki (np. 300)"
		reasonInput.PlaceholderText = "Powód wydania wyroku"
	elseif currentMode == "Wanted" then
		valueInput.Visible = false
		valueLabel.Visible = false
		reasonInput.PlaceholderText = "Powód wszczęcia poszukiwania"
	end
end


function FormManager.SetMode(mode)
	currentMode = mode
	FormManager.UpdateUI()
end


function FormManager.Submit(addEntryRemote, arrestRemote)
	local mainForm = UIManager.GetUI("MainFrame/FormsFrame/MainFormFrame")
	local uidText = mainForm:WaitForChild("UIDTextBox").Text
	local reason = mainForm:WaitForChild("ReasonTextBox").Text
	local value = mainForm:WaitForChild("ValueTextBox").Text
	local errorLabel = mainForm:WaitForChild("ErrorLabel")
	if uidText == "" or reason == "" or (currentMode ~= "Wanted" and value == "") then
		errorLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		errorLabel.Text = "Wypełnij wszystkie pola!"
		return
	end

	if not string.match(uidText, "^%d+$") then
		errorLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		errorLabel.Text = "PESEL musi zawierać tylko cyfry!"
		return
	end

	local uid = tonumber(uidText)
	local success, message

	success, message = addEntryRemote:InvokeServer(currentMode, uid, reason or "", value)


	if success then
		errorLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		errorLabel.Text = "Pomyślnie dodano do bazy!"
		if currentMode == "Sentence" then
			errorLabel.Text = "Pomyślnie wydano wyrok!"
		end
		mainForm:WaitForChild("UIDTextBox").Text = ""
		mainForm:WaitForChild("ReasonTextBox").Text = ""
		mainForm:WaitForChild("ValueTextBox").Text = ""
		task.delay(2, function() errorLabel.Text = "" end)
	else
		errorLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		errorLabel.Text = message or "Wystąpił błąd!"
	end
end

return FormManager