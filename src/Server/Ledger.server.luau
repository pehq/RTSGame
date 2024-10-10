--PehqDev
--Stores all entities
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")

local EntityModule =  require(ReplicatedStorage.Modules.Entitiy)
local UnitModule =  require(ReplicatedStorage.Modules.Entitiy.Unit)
local BuildingModule =  require(ReplicatedStorage.Modules.Entitiy.Building)
local PresetModule = require(ReplicatedStorage.Modules.StartingPresets)

local RemoteEvents = ReplicatedStorage.Events
local RemoteFunctions = ReplicatedStorage.Functions

local EntityDataList = {}
for i, v in pairs(ReplicatedStorage.EntityData:GetChildren()) do
	if v:IsA("ModuleScript") ~= true then
		continue
	end
	EntityDataList[v.Name] = require(v)
end

local EntityList = {}

--Start up
print("Started")
task.wait(10)
for i, v in pairs(Players:GetPlayers()) do
	local Folder = Instance.new("Folder")
	Folder.Name = v.UserId
	Folder.Parent = workspace
end


--Preset
local PresetChosen = ServerStorage.Presets.TestPreset --TODO: Make this per map
local FormattedPreset = PresetModule.FormatCFrameValues(PresetChosen)
local TeamAssignedPlrs = PresetModule.AssignPlayersToTeams(PresetChosen)
local EntitiesCreatedFromPreset = PresetModule.Setup(FormattedPreset, TeamAssignedPlrs)

table.move(EntitiesCreatedFromPreset, 1, #EntitiesCreatedFromPreset, 1, EntityList)

local function GetEntityFromInstance(obj:Instance)
	local Entity = nil
	if obj:IsA("Model") == false then
		return Entity
	end
	
	for i, v in pairs(EntityList) do
		if v.Object == obj then
			Entity = v
			break
		end
	end
	
	return Entity
end

--At this point, there should be entities.
--Remote functions
RemoteFunctions.GetEntityFromInstance.OnServerInvoke = function(plr, obj) return GetEntityFromInstance(obj) end