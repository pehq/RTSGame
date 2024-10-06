local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Events = ReplicatedStorage.Events

local EntityModule = require(script.Parent)
local UnitModule = require(script.Parent.Unit)

local Building = {}
Building.__index = Building

function Building.new(values, owner)
	local self = EntityModule.new(values, owner)
	setmetatable(self, Building)
	
	self.BuildingState = "Idle"
	self.ActionState = "Idle"
	self.Queue = {}
	self.BuildProgress = 0
	self.UnitWaypoint =  self.Object.PrimaryPart.Position - Vector3.new(0,0, -self.Object.PrimaryPart.Size.Z)
	
	return self
end

function Building:SpawnUnit(UnitName)
	--Spawn on edge of hitbox
	local Model:Model = self.Object
	local Hitbox = Model.PrimaryPart
	local Rot = (self.UnitWaypoint - Hitbox.Position)
	local Rot2d = Vector2.new(Rot.X, Rot.Z).Unit
	--Convert unit circle to square
	local SpawningEdgeOffset = Vector2.new(0.5 * (2 + Rot2d.X^2 - Rot2d.Y^2 + 2 * Rot2d.X * 2^0.5)^0.5 - 0.5 * (2 + Rot2d.X^2 - Rot2d.Y^2 - 2* Rot2d.X * 2^0.5)^0.5,
		0.5 * (2 - Rot2d.X^2 + Rot2d.Y^2 + 2 * Rot2d.Y * 2^0.5)^0.5 - 0.5 * (2 - Rot2d.X^2 + Rot2d.Y^2 - 2 * Rot2d.Y * 2^0.5)^0.5)
	local SpawningEdge = Hitbox.Position + Vector3.new(SpawningEdgeOffset.X * Hitbox.Size.X/2, Hitbox.Position.Y, SpawningEdgeOffset.Y * Hitbox.Size.Z)
	
	Events.SpawnUnit:Fire(self.EntityId, UnitName, SpawningEdge)
	return self
end

local Cancelled = false
function Building:BuildFromQueue()
	--Builds the first thing on the queue'
	if #self.Queue == 0 then
		return
	end
	
	self.BuildingState = "Building"
	
	local SelectedQueue = self.Queue[1]
	local StartTime = os.time()
	
	repeat
		self.BuildProgress = os.time() - StartTime
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

function Building:AddUnitToQueue(UnitName)
	local UnitQueued = EntityModule.EntitiesDirectory[UnitName]
	if EntityModule.EntitiesDirectory[UnitName] == nil then
		warn("Entity doesn't exists!")
		return
	end
	
	table.insert(self.Queue, {
		["BuildTime"] = UnitQueued.Values.BuildTime,
		["Name"] = UnitName,
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

return Building
