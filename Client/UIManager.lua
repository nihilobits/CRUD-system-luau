local UIManager = {}
local TweenService = game:GetService("TweenService")
local cache = {}
local BackgroundImage = script.Parent.Parent:WaitForChild("BackgroundImage")
local MainGroup = BackgroundImage:WaitForChild("MainGroup")


function UIManager.GetUI(path)
	if cache[path] then return cache[path] end
	local current = MainGroup
	for segment in string.gmatch(path, "[^/]+") do
		current = current:WaitForChild(segment, 5)
		if not current then return nil end
	end
	cache[path] = current
	return current
end


local isEnabled = false
function UIManager.ToggleMainUI()
	isEnabled = not isEnabled

	local targetPos = isEnabled and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 2, 0)
	local easing = isEnabled and Enum.EasingStyle.Circular or Enum.EasingStyle.Circular
	local direction = isEnabled and Enum.EasingDirection.Out or Enum.EasingDirection.In

	local tween = TweenService:Create(BackgroundImage, TweenInfo.new(1, easing, direction), {
		Position = targetPos
	})
	tween:Play()

	return isEnabled
end


function UIManager.SwitchFrame(buttonMap, frameToShow)
	for _, frame in pairs(buttonMap) do
		frame.Visible = false
	end
	if frameToShow then frameToShow.Visible = true end
end

return UIManager