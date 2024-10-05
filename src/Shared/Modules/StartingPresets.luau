--PehqDev
--Loads the starting positions
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PresetsContainer = ServerStorage.Presets

local EntityModule =  require(ReplicatedStorage.Modules.Entitiy)
local UnitModule =  require(ReplicatedStorage.Modules.Entitiy.Unit)
local BuildingModule =  require(ReplicatedStorage.Modules.Entitiy.Building)

local Presets = {}
--This is how a preset is gonna be
--Team Colour
--|-Team1
--| \-EntityName
--|   \-CFrameValue
--\-Team2
--Any team in a preset witht the same name will be merged
--Any player controlling two teams will have the teams be merged

function Presets.FormatCFrameValues(PresetInstances:Instance):{[string]:{[string]:CFrame}}
	if PresetInstances.Parent ~= PresetsContainer then
		error("Presets isn't contained in ServerStorage.Presets")
		return
	end
	
	local Result = {}
	
	for i, v:Instance in pairs(PresetInstances:GetDescendants()) do
		if v:IsA("CFrameValue") then
			if Result[v.Parent.Name] == nil then
				Result[v.Parent.Name] = {}
			end
			Result[v.Parent.Name][v.Name] = v.Value
		elseif v:IsA("Folder") then
			if Result[v.Name] == nil then
				Result[v.Name] = {}
			end
		end
	end
	
	return Result
end

function Presets.Setup(Preset:{[string]:{[string]:CFrame}}, PlayerTeams:{string:Player})
	local EntityCreated = {}
	--Get EntityData
	local EntityData = {}
	for i, v in pairs(ReplicatedStorage.EntityData:GetChildren()) do
		if v:IsA("ModuleScript") then
			EntityData[v.Name] = require(v)
		end
	end

	
	for i, x in pairs(Preset) do
		--check if player is assigned to this team
		if PlayerTeams[i] == nil then
			continue
		end
		
		for j, y in pairs(x) do
			local Entity = EntityData[j]
			if Entity == nil then
				error("EntityData for "..j.." doesn't exist")
			end
			local NewEntity
			if Entity.Type == "Unit" then
				NewEntity = UnitModule.new(EntityData[j].Values)
			elseif Entity.Type == "Building" then
				NewEntity = BuildingModule.new(EntityData[j].Values)
			end
			table.insert(EntityCreated, NewEntity)
			
			NewEntity.Owner = PlayerTeams[i]
			NewEntity.Object.Parent = workspace[tostring(NewEntity.Owner.UserId)]
		end
	end
	
	EntityData = nil
	
	return EntityCreated
end

return Presets