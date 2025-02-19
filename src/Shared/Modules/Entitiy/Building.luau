local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Events = ReplicatedStorage.Events
local ServerEvents = ServerStorage.Events

local EntityModule = require(script.Parent)
local UnitModule = require(script.Parent.Unit)

local Building = {}
Building.__index = Building
setmetatable(Building, EntityModule)

function Building.new(EntityDataName, owner, id)
	local self = EntityModule.new(EntityDataName, owner, id)
	setmetatable(self, Building)
	
	for i, v in pairs(self.Object:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Building"
			v.Anchored = false
		end
	end
	self.Object.PrimaryPart.Anchored = true

	self.BuildingState = "Idle"
	self.ActionState = "Idle"
	self.Queue = {}
	self.BuildProgress = 0
	self.UnitWaypoint = self.Object.PrimaryPart.Position + Vector3.new(0,0, -math.clamp(self.Object.PrimaryPart.Size.Z, 0, 5))
	
	return self
end

function Building:SpawnUnit(UnitDataName)
	--Spawn on edge of hitbox
	local Model:Model = self.Object
	local Hitbox = Model.PrimaryPart
	local Rot = (self.UnitWaypoint - Hitbox.Position)
	local Rot2d = Vector2.new(Rot.X, Rot.Z).Unit
	--Convert unit circle to square
	local SpawningEdgeOffset = Vector2.new(0.5 * (2 + Rot2d.X^2 - Rot2d.Y^2 + 2 * Rot2d.X * 2^0.5)^0.5 - 0.5 * (2 + Rot2d.X^2 - Rot2d.Y^2 - 2* Rot2d.X * 2^0.5)^0.5, 0.5 * (2 - Rot2d.X^2 + Rot2d.Y^2 + 2 * Rot2d.Y * 2^0.5)^0.5 - 0.5 * (2 - Rot2d.X^2 + Rot2d.Y^2 - 2 * Rot2d.Y * 2^0.5)^0.5)
	local SpawningEdge = Hitbox.Position + Vector3.new(SpawningEdgeOffset.X * Hitbox.Size.X/2, Hitbox.Position.Y, SpawningEdgeOffset.Y * Hitbox.Size.Z)
	
	--TODO: add orientation
	
	ServerEvents.SpawnUnit:Fire(self.Id, self.Owner, UnitDataName, SpawningEdge)
	
	return self
end

local Cancelled = false
function Building:BuildFromQueue() --I am considering turning this into a local functions :/
	--Builds the first thing on the queue'
	if #self.Queue == 0 then
		return
	end
	
	self.BuildingState = "Building"
	
	local SelectedQueue = self.Queue[1]
	local StartTime = os.time()
	
	repeat
		self.BuildProgress = (os.time() - StartTime) / SelectedQueue.BuildTime
		task.wait()
	until Cancelled == true or os.time() - StartTime >= SelectedQueue.BuildTime
	
	if Cancelled == true then
		Cancelled = false
	else
		self:SpawnUnit(SelectedQueue.Name)
	end
	table.remove(self.Queue, 1)
	
	if #self.Queue ~= 0 then --Recurse if there are still stuff to build
		self:BuildFromQueue()
	else
		self.BuildingState = "Idle"
	end
	
	return self
end

function Building:RemoveFromQueue(index)
	if index == 1 then
		Cancelled = true
	else
		table.remove(self.Queue, index)
	end
	--TODO: Issue refunds
	
	return self
end

function Building:AddUnitToQueue(UnitName, BuildTime)
	if ReplicatedStorage.EntityData:FindFirstChild(UnitName) == nil then --WHY
		warn("Entity doesn't exists!")
		return
	end
	
	table.insert(self.Queue, {
		["Name"] = UnitName,
		["BuildTime"] = BuildTime,
	})
	
	if self.BuildingState ~= "Building" then
		self:BuildFromQueue()
	end
	
	return self
end

function Building:SetUnitWaypoint(position:Vector3)
	self.UnitWaypoint = position
	return self
end

function Building:ResetUnitWaypoint()
	self.UnitWaypoint = self.Object.PrimaryPart.Position + Vector3.new(0,0, -self.Object.PrimaryPart.Size.Z)
	return self
end

return Building