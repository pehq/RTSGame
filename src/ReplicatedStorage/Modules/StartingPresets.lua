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
		elseif v.Name == "Priority" then
			continue
		end
	end
	--Look over modifiers
	for i, v in pairs(Result) do
		if PresetInstances:FindFirstChild(i) then
			if PresetInstances[i]:FindFirstChild("isTeam") and PresetInstances[i].Value == true then
				Result[i] = nil
				continue
			end
		end
	end
	
	--Prioritizes teams
	local TeamPriority = {}
	local PrioritizedTeams = 0
	for i, v in pairs(Result) do
		if PresetInstances:FindFirstChild("Priority") then
			TeamPriority[PresetInstances.Priority.Value] = i
		else
			TeamPriority[#Result - PrioritizedTeams] = i
			PrioritizedTeams += 1
		end
	end
	
	return Result, TeamPriority
end

function Presets.AssignPlayersToTeams(preset:Instance)
	local AssignedTeams = {}
	
	local PlayerList = Players:GetChildren()
	local TeamList = preset:GetChildren()
	
	for i = 1, #PlayerList do
		local RandomPlayer = math.random(1, #PlayerList)
		AssignedTeams[TeamList[1].Name] = PlayerList[RandomPlayer]
		table.remove(PlayerList, RandomPlayer)
		table.remove(TeamList, 1) --Questionable..?
	end
	
	return AssignedTeams
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
			if Entity.Values.EntityType == "Unit" then
				NewEntity = UnitModule.new(Entity.Values, PlayerTeams[i])
			elseif Entity.Values.EntityType == "Building" then
				NewEntity = BuildingModule.new(Entity.Values, PlayerTeams[i])
			end
			table.insert(EntityCreated, NewEntity)
			
			NewEntity.Object.PrimaryPart.CFrame = y
			NewEntity.Object.Parent = workspace[tostring(NewEntity.Owner.UserId)]
		end
	end
	
	EntityData = nil
	
	return EntityCreated
end

return Presets