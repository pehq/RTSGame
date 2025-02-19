local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage.Events
local LocalPlayer = Players.LocalPlayer

local TarAtt = Instance.new("Attachment")
TarAtt.Name = "WaypointPathTarAtt"
TarAtt.Parent = workspace.Terrain

local Beam = Instance.new("Beam")
Beam.Name = "WaypointPathBeam"
Beam.Attachment1 = TarAtt
Beam.Parent = workspace.Terrain


local function Run(owner:Player, Model:Model, TarPos:Vector3)
	if owner ~= LocalPlayer then --this effect is only visible to the owner
		return
	end
	
	local Att0 = Model.PrimaryPart:FindFirstChild("OriginAttachment")
	if Att0 == nil then
		for i, v:Attachment in pairs(Model.PrimaryPart:GetChildren()) do --Failsafe: find other attachments with origin
			if v:IsA("Attachment") == false then
				continue
			end
			
			if v.CFrame == CFrame.new() then
				Att0 = v
				break
			end
		end
	end
	
	if Att0 == nil then --Failsafe: Create the attachment (bruuuuhhhh)
		warn(`No Center attachment found for {Model.Name}. Please create an attachment called \"OriginAttachment\" and place it under {Model.PrimaryPart}.`)
		Att0 = Instance.new("Attachment")
		Att0.Name = "CenterAttachment"
		Att0.Parent = Model.PrimaryPart
	end
	
	TarAtt.WorldCFrame = CFrame.new(TarPos)
	
	Beam.Attachment0 = Att0
	
	Events.EntityDeselected.Event:Wait()

	Beam.Attachment0 = nil
end

return Run