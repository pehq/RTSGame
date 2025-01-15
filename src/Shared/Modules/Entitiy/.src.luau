local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local EntityData = ReplicatedStorage.EntityData

local ServerConfigs = ServerStorage:FindFirstChildWhichIsA("Configuration")

local EntityDataIdsContainer = ServerConfigs.EntityDataIds

local ObjValModule = require(ReplicatedStorage.Modules.ObjectValues)

local Entity = {}
Entity.__index = Entity

Entity.EntitiesDirectory = {}
for i, v in pairs(EntityData:GetChildren()) do
	local Required
	
	if v:IsA("ModuleScript") then
		Required = require(v)
		Entity.EntitiesDirectory[Required.Values.Name] = Required
	end
	
	Required = nil
end

function Entity.new(Values, owner)
	local self = {}
	setmetatable(self, Entity)
	
	local EntityDataId = EntityDataIdsContainer:FindFirstChild(Values.DataName)
	if not EntityDataId then
		EntityDataId = Instance.new("IntValue")
		EntityDataId.Name = Values.DataName
		EntityDataId.Value = 0
		EntityDataId.Parent = EntityDataIdsContainer
	end
	self.Id = EntityDataId.Value
	EntityDataId.Value += 1
	--self.Id = shared.Strategis.EntityIdCount
	--shared.Strategis.EntityIdCount += 1
	
	self.Owner = owner
	self.Team = self.Owner ~= nil and self.Owner.Team or nil
	self.Object = Values.Object:Clone()
	self.Object.Parent = workspace
	Entity.ApplyCollisionsOnObj(self.Object)
	
	self.EntityType = Values.EntityType
	self.DataName = Values.DataName
	
	self.Health = Values.Health
	self.MaxHealth = Values.MaxHealth
	self.Shield = Values.Shield
	self.MaxShield = Values.MaxShield
	self.Queue = {}
	
	local ConfigsObj = Instance.new("Configuration") --Read-only way to share info with client without remotes
	ConfigsObj.Parent = self.Object
	self:NewConfig("Owner",		Instance.new("ObjectValue"))
	self:NewConfig("Id",		Instance.new("IntValue"))
	self:NewConfig("DataName",	Instance.new("StringValue"))
	self:NewConfig("Health",	Instance.new("NumberValue"))
	self:NewConfig("MaxHealth",	Instance.new("NumberValue"))
	self:NewConfig("Shield",	Instance.new("NumberValue"))
	self:NewConfig("MaxShield",	Instance.new("NumberValue"))
	self:NewConfig("Queue",		Instance.new("StringValue"))
	
	--TODO: This is very memory costly. If used a lot, then server might crash.
	for i, v in pairs(Values) do
		if typeof(v) == "table" then
			v = table.clone(v) --Copy the table rather than reference it
		end
		if self[i] == nil then
			self[i] = v
		end
	end
	
	return self
end

function Entity.ApplyCollisionsOnObj(Object:Model)
	for i, v in pairs(Object:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Entity"
		end
	end
	
	return Object
end

--vv-- Configs --vv--
function Entity:NewConfig(Key, ValueType:ValueBase)
	local Model:Model = self.Object
	local ConfigsObj = Model:FindFirstChildWhichIsA("Configuration")
	
	ValueType.Value = typeof(self[Key]) == "table" and HttpService:JSONEncode(self[Key]) or self[Key]
	ValueType.Name = Key
	ValueType.Parent = ConfigsObj
	
	return self
end

function Entity:UpdateConfigs()
	local Model:Model = self.Object
	local ConfigsObj = Model:FindFirstChildWhichIsA("Configuration")
	
	for i, v in pairs(ConfigsObj:GetChildren()) do
		v.Value = typeof(self[v.Name]) == "table" and HttpService:JSONEncode(self[v.Name]) or self[v.Name]
	end
	
	return self
end

function Entity:UpdateConfigkey(Key:string)
	local Model:Model = self.Object
	local ConfigsObj = Model:FindFirstChildWhichIsA("Configuration")
	
	ConfigsObj:FindFirstChild(Key).Value = typeof(self[Key]) == "table" and HttpService:JSONEncode(self[Key]) or self[Key]
	
	return self
end

function Entity:SetConfig(key, Value)
	local Model:Model = self.Object
	local ConfigsObj = Model:FindFirstChildWhichIsA("Configuration")
	
	ConfigsObj:FindFirstChild(key).Value = typeof(Value) == "table" and HttpService:JSONEncode(Value) or Value
	
	return self
end
--^^-------------^^--

function Entity:ApplyTeamColors()
	local Model:Model = self.Object
	local Team = self.Team
	if Team == nil or not Team:IsA("Team") then
		warn("No Team object found!")
		return
	end
	
	for i, v in pairs(Model:GetChildren()) do
		if v:IsA("BasePart") and v:GetAttribute("ColorType") ~= nil then
			local ColourValue:Color3Value = Team:FindFirstChild(v:GetAttribute("ColorType"))
			if not ColourValue then continue end
			v.Color = ColourValue.Value
		end
		local SurfaceAppearance = v:FindFirstChildWhichIsA("SurfaceAppearance")
		if v:IsA("MeshPart") == false then
			continue
		end
		if SurfaceAppearance ~= nil and (v:GetAttribute("ColorType") == "Saturation" or SurfaceAppearance:GetAttribute("ColorType") == "Saturation") then
			local ColourValue:Color3Value = Team:FindFirstChild(v:GetAttribute("ColorType"))
			if not ColourValue then continue end
			SurfaceAppearance.Color = ColourValue.Value
		end
	end
	
	return self
end

function Entity:LoadAnimation(animId:string, animName:string):AnimationTrack
	local Model:Model = self.Object
	local Controller = Model:FindFirstChildWhichIsA("Humanoid") or Model:FindFirstChildWhichIsA("AnimationController")
	local Animator:Animator = Controller:FindFirstChildWhichIsA("Animator") or Controller
	
	local Animation = Instance.new("Animation")
	Animation.Name = animName or Animation.Name
	Animation.AnimationId = animId

	local Track = Animator:LoadAnimation(Animation)
	return Track
end

--TODO: move damage into its own module
function Entity:DealDamage(TargetEntity, dmg)
	dmg = math.abs(dmg)
	local Modifiers = {}
	--TODO: add modifiers
	TargetEntity:TakeDamage(self, dmg, Modifiers)
end

function Entity:TakeDamage(OwnerEntity, dmg, modifiersapplied)
	dmg = math.abs(dmg)
end

--Some units have turrets so they'll be procedural
local function worldCFrameToC0ObjectSpace(motor6DJoint,worldCFrame) --function by dthecoolest
	local part1CF = motor6DJoint.Part1.CFrame
	local c1Store = motor6DJoint.C1
	local c0Store = motor6DJoint.C0
	local relativeToPart1 = c0Store * c1Store:Inverse() * part1CF:Inverse() * worldCFrame * c1Store
	relativeToPart1 -= relativeToPart1.Position

	local goalC0CFrame = relativeToPart1 + c0Store.Position--New orientation but keep old C0 joint position
	return goalC0CFrame
end

function Entity:AddTurrets()
	local Model:Model = self.Object
	local Turrets = Model:FindFirstChild("Turrets")

	for i, v in pairs(Turrets:GetChildren()) do
		if not v:IsA("ObjectValue") or not v.Value:IsA("Motor6D") then
			continue
		end

		local VMotor:Motor6D = v.Value
		if self.TurretDefaultMotorC0[VMotor.C0] == nil then
			self.TurretDefaultMotorC0[VMotor.C0] = {VMotor}
		else
			table.insert(self.TurretDefaultMotorC0[VMotor.C0], VMotor)
		end
	end

	return self
end

function Entity:AimTurrets(tarpos:Vector3)
	local Model:Model = self.Object

	local Turrets = Model:FindFirstChild("Turrets")
	if Turrets == nil then
		warn("No folder called \"Turrets\" were found")
	end

	local TurretList = Turrets:GetChildren()

	for i = 1, #TurretList do
		local v = TurretList[i]
		if not v:IsA("ObjectValue") or not v.Value:IsA("Motor6D") then
			continue
		end

	end
end

function Entity:ResetTurretsAim()
	local Model:Model = self.Object

	for i, v in pairs(self.TurretDefaultMotorC0) do
		for j = 1, #v do
			v[j].C0 = i
		end
	end

	return self
end

return Entity