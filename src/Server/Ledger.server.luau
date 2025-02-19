--repeat task.wait() until shared.StrategisStatus.Installed
--PehqDev
--Stores and takes care of all entities
shared.Strategis = {}
shared.Strategis.EntityIdCount = 1

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")

local RemoteEvents = ReplicatedStorage.Events
local RemoteFunctions = ReplicatedStorage.Functions
local ServerEvents = ServerStorage.Events
local ServerConfigs = ServerStorage:FindFirstChildWhichIsA("Configuration")

local EntityModule 	= require(ReplicatedStorage.Modules.Entitiy)
local UnitModule 	= require(ReplicatedStorage.Modules.Entitiy.Unit)
local BuildingModule= require(ReplicatedStorage.Modules.Entitiy.Building)
local PresetModule 	= require(ReplicatedStorage.Modules.StartingPresets)
local PseudoTables 	= require(ReplicatedStorage.Modules["Pseudo-Dimensional Table"])

local EntityDataArray = ReplicatedStorage.EntityData:GetChildren()
local EntityDataList = {}
for i, v in pairs(EntityDataArray) do
	if v:IsA("ModuleScript") ~= true then
		continue
	end
	EntityDataList[v.Name] = require(v)
end
print(EntityDataList)

local EntityList = {}

local MIN_PLAYERS = 1
local TEAM_PRESET_PACK = ServerStorage.Presets.TestPreset

local function GetEntityFromId(id:number)
	local Entity = nil
	
	Entity = EntityList[id]	
	
	return Entity
end

local function GetEntityFromInstance(obj:Instance)
	local Entity = nil
	
	if obj:IsA("Model") == false then
		return Entity
	end
	
	--try to find by config values
	local objConfigs = obj:FindFirstChildWhichIsA("Configuration")
	if objConfigs ~= nil and objConfigs:FindFirstChild("Id") then
		Entity = GetEntityFromId(objConfigs.Id)
		if Entity ~= nil then
			return Entity
		end
	end
	
	--Bruteforce method
	for i, v in pairs(EntityList) do
		if v.Object == obj then
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

local function GetEntitiesFromTag(tagname:string)
	local EntitiesFromTag = {}
	
	for i, v in ipairs(CollectionService:GetTagged(tagname)) do
		local EntityValue = GetEntityFromInstance(v)
		EntitiesFromTag[EntityValue.Id] = EntityValue
	end
	
	return EntitiesFromTag
end

--Start up
local plrCount = #Players:GetPlayers()
repeat
	Players.PlayerAdded:Wait()
	plrCount = #Players:GetPlayers()
until plrCount >= MIN_PLAYERS

task.wait(5)
print("Started")
local PlayingPlrs = Players:GetPlayers()

--Create folder for containing entities
local MiscEntitiesFolder = Instance.new("Folder")
MiscEntitiesFolder.Name = "MiscEntities"
MiscEntitiesFolder.Parent = workspace

for i, v in pairs(PlayingPlrs) do
	local Folder = Instance.new("Folder")
	Folder.Name = v.UserId
	Folder.Parent = workspace
end

--Presets
local PresetsFromPack = TEAM_PRESET_PACK:GetChildren()
for i, plr in pairs(PlayingPlrs) do
	local EntitiesFromPreset = PresetModule.LoadPreset(PresetsFromPack[i], plr, workspace[tostring(plr.UserId)], ServerConfigs.EntityIdValue)
	for i, v in pairs(EntitiesFromPreset) do
		EntityList[v.Id] = v
	end
end

--Misc preset for playtesting --TODO: remove later, this is only used for debugging.
local EntitiesFromPreset = PresetModule.LoadPreset(ServerStorage.Presets.MiscPreset["3Units"], nil, MiscEntitiesFolder, ServerConfigs.EntityIdValue)
for i, v in pairs(EntitiesFromPreset) do
	EntityList[v.Id] = v
end

--At this point, there should be entities.
--Set Building's waypoint
for i, v in pairs(EntityList) do
	v:ApplyTeamColors()
	if v.EntityType == "Building" then
		v:ResetUnitWaypoint()
	end
end

--Remote Events
	--Unit Events
RemoteEvents.MoveUnit.OnServerEvent:Connect(function(plr, EntityIds, TarPos)
	for i, Id in pairs(EntityIds) do
		local Entity = GetEntityFromId(Id)
		if Entity.EntityType ~= "Unit" or Entity.Owner ~= plr then
			continue
		end
		task.spawn(function()
			Entity:WalkTo(TarPos)
		end)
	end
end)

RemoteEvents.BuildBuilding.OnServerEvent:Connect(function(plr, BuilderId, BuildingDataName, TargetCFrame)
	local BuilderUnit = GetEntityFromId(BuilderId) --TODO: work on this
end)

ServerEvents.SpawnUnit.Event:Connect(function(BuildingId:number, Owner, UnitDataName:string, SpawnEdge:Vector3)
	local Building = GetEntityFromId(BuildingId)
	local NewUnit = UnitModule.new(UnitDataName, Building.Owner)
	NewUnit.Object.PrimaryPart.CFrame = CFrame.new(SpawnEdge)
	EntityList[NewUnit.Id] = NewUnit
	NewUnit.Object.Parent = workspace:FindFirstChild(Building.Owner.UserId)
	NewUnit.Object.PrimaryPart.CollisionGroup = "InactiveUnit"
	task.delay(1, function()
		NewUnit.Object.PrimaryPart.CollisionGroup = "Unit"
	end)
	NewUnit:WalkTo(Building.UnitWaypoint)
end)

--Building Events
RemoteEvents.BuildUnit.OnServerEvent:Connect(function(plr, BuildingEntityId, UnitDataName, BuildTime)
	if EntityDataList[UnitDataName] == nil then
		error("Unit's data not found, consider having the Unit's data's value the same as the name of the module.")
	end
	
	local BuildingEntity = GetEntityFromId(BuildingEntityId)
	BuildingEntity:AddUnitToQueue(UnitDataName, BuildTime)
end)

RemoteEvents.SetBuildingWaypoint.OnServerEvent:Connect(function(plr, EntityIds, TarPos)
	for i, Id in pairs(EntityIds) do
		local Entity = GetEntityFromId(Id)
		if Entity.EntityType ~= "Building" or Entity.Owner ~= plr then
			continue
		end
		Entity:SetUnitWaypoint(TarPos)
	end
end)

--Remote functions
RemoteFunctions.GetEntityFromInstance.OnServerInvoke = function(plr, obj) return GetEntityFromInstance(obj) end
RemoteFunctions.RequestUnitData.OnServerInvoke = function(plr, EntityKey, Key) return GetEntityDataFromKey(EntityKey, Key) end