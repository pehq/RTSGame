local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events
local ServerEvents = ServerStorage.Events

local function ServerEvent(Event:RemoteEvent, owner, ...)
	for i, plr in pairs(Players:GetPlayers()) do
		if plr == owner then
			continue
		end
		
		Event:FireClient(plr, owner, ...)
	end
end

Events.VFX.OnServerEvent:Connect(function(...)
	ServerEvent(Events.VFX, ...)
end)
Events.UnreliableVFX.OnServerEvent:Connect(function(...)
	ServerEvent(Events.UnreliableVFX, ...)
end)
ServerEvents.VFX.Event:Connect(function(...)
	Events.VFX:FireAllClients(...)
end)
ServerStorage.Events.UnreliableVFX.Event:Connect(function(...)
	Events.UnreliableVFX:FireAllClients(...)
end)