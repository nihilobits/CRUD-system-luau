local FeedManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FeedRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("FeedRemote")


function FeedManager:Publish(message: string)
	if typeof(message) ~= "string" then
		message = tostring(message)
	end
	FeedRemote:FireAllClients(message)
end


return FeedManager