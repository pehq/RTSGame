--PehqDev
--Loads the starting positions
local Players = game:GetService("Players")
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
--| \-EntityName (CFrameValue)
--\-Team2
--Any team in a preset witht the same name will be merged
--Any player controlling two teams will have the teams be merged

function Presets.LoadPreset(container:Folder, owner:Player, parent:Folder, IdIntVal:IntValue)
	local CreatedEntities = {}
	
	for i, v:CFrameValue in ipairs(container:GetChildren()) do
		if v:IsA("CFrameValue") == true then
			local NewEntity = nil
			if EntityModule.EntitiesDirectory[v.Name].Values.EntityType == "Building" then
				NewEntity = BuildingModule.new(v.Name, owner, IdIntVal.Value)
			elseif EntityModule.EntitiesDirectory[v.Name].Values.EntityType == "Unit" then
				NewEntity = UnitModule.new(v.Name, owner, IdIntVal.Value)
			end
			IdIntVal.Value += 1
			
			NewEntity.Object.Parent = parent
			NewEntity.Object.PrimaryPart.CFrame = v.Value
			
			CreatedEntities[NewEntity.Id] = NewEntity
		end
	end
	
	return CreatedEntities
end

return Presets