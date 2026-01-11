local IncidentManager = {}
IncidentManager.__index = IncidentManager

local IncidentRemote = game:GetService("ReplicatedStorage").RemoteEvents:WaitForChild("IncidentRemote")
local Incidents = {}
local counter = 1


local Instance = nil
function IncidentManager.new()
	if Instance then return Instance end
	local self = setmetatable({}, IncidentManager)
	Instance = self
	self.Incidents = Incidents
	return self
end


function IncidentManager:StartIncident(IncidentName: string, Duration:number, Position:string, Type:string)
	local NewIncident = {
		Name = IncidentName,
		Type = Type,
		Duration = Duration,
		ID = counter,
		Position = Position,
		StartTime = os.time()
	}
	table.insert(self.Incidents, NewIncident)
	counter += 1
	IncidentRemote:FireAllClients("NewIncident", NewIncident, #Incidents)
end


function IncidentManager:GetFiveIncidents()
	local Incidents = {}
	for i = #self.Incidents, math.max(1, #self.Incidents - 4), -1 do
		table.insert(Incidents, self.Incidents[i])
	end
	return Incidents
end


function IncidentManager:GetAllIncidents()
	return self.Incidents
end


function IncidentManager:CheckIncidents()
	for i = #self.Incidents, 1, -1 do
		local Incident = self.Incidents[i]
		local TimeElapsed = os.time() - Incident.StartTime
		if TimeElapsed >= Incident.Duration then
			table.remove(self.Incidents, i)
			IncidentRemote:FireAllClients("RemoveIncident", Incident, #Incidents)
			if Incident.Callback then
				Incident.Callback()
			end
		end
	end
end

return IncidentManager