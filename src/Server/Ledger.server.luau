--PehqDev
--Stores all entities
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")

local RemoteEvents = ReplicatedStorage.Events
local RemoteFunctions = ReplicatedStorage.Functions
local ServerEvents = ServerStorage.Events

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

local function GetEntityFromId(id:number)
	local Entity = nil
	for i, v in pairs(EntityList) do
		if v.EntityId == id then
			Entity = v
			break
		end
	end
	
	return Entity
end

local function GetEntityDataFromKey(EntityKey:string, Key)
	local Value = nil
	
	if EntityDataList[EntityKey] ~= nil and EntityDataList[EntityKey][Key] ~= nil then
		Value = EntityDataList[EntityKey][Key]
	end
	
	return Value
end

--At this point, there should be entities.
--Set Building's waypoint
for i, v in pairs(EntityList) do
	if v.EntityType == "Building" then
		print(v)
		v:ResetUnitWaypoint()
	end
end

--Remote Events
	--Unit Events
RemoteEvents.MoveEntity.OnServerEvent:Connect(function(plr, TarPos, EntityId)
	local Entity = GetEntityFromId(EntityId) 
	Entity:WalkTo(TarPos)
end)

	--Building Events
RemoteEvents.BuildUnit.OnServerEvent:Connect(function(plr, BuildingEntityId, UnitDataName)
	if EntityDataList[UnitDataName] == nil then
		error("Unit's data not found, consider having the Unit's data's value the same as the name of the module.")
	end
	
	BuildingModule:AddUnitToQueue()
end)

ServerEvents.SpawnUnit.Event:Connect(function(BuildingId:number, UnitDataName:string, SpawnEdge:CFrame)
	local Building = GetEntityFromId(BuildingId)
	local NewUnit = UnitModule.new(EntityDataList[UnitDataName], Building.Owner)
	NewUnit.Object.PrimaryPart.CFrame = SpawnEdge
	NewUnit.Object.Parent = workspace:FindFirstChild(Building.Owner.UserId)
	NewUnit:WalkTo(Building.UnitWaypoint)
end)

--Remote functions
RemoteFunctions.GetEntityFromInstance.OnServerInvoke = function(plr, obj) return GetEntityFromInstance(obj) end
RemoteFunctions.RequestUnitData.OnServerInvoke = function(plr, EntityKey, Key) return GetEntityDataFromKey(EntityKey, Key) end