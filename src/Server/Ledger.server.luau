--PehqDev
--Stores all entities
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local EntityModule =  require(ReplicatedStorage.Modules.Entitiy)
local UnitModule =  require(ReplicatedStorage.Modules.Entitiy.Unit)
local BuildingModule =  require(ReplicatedStorage.Modules.Entitiy.Building)
local PresetModule = require(ReplicatedStorage.Modules.StartingPresets)

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
task.wait(5)
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

print(PresetChosen)
print(FormattedPreset)
print(TeamAssignedPlrs)
print(EntitiesCreatedFromPreset)
table.move(EntitiesCreatedFromPreset, 1, #EntitiesCreatedFromPreset, 1, EntityList)
print(EntityList)

--At this point, there should be entities.