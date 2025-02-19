local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events

local VFX_Mod = require(Modules.VFX_Handler)

local function VFX_Func(owner, VFX_Name, ...)
	VFX_Mod[VFX_Name](owner, ...)
end

Events.VFX.OnClientEvent:Connect(VFX_Func)
Events.UnreliableVFX.OnClientEvent:Connect(VFX_Func)