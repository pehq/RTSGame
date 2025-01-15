--Squadrons are a collection of the same units WIP
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Squadron = {}
Squadron.__index = {}

function Squadron.new(Values, owner) --Values come from unit data
	local self = setmetatable({}, Squadron)
	
	self.Object = ReplicatedStorage.Models
	
	--Humanoid
	local Humanoid:Humanoid = self.Object:FindFirstChildWhichIsA("Humanoid")
	Humanoid.WalkSpeed = Values.Speed
	Humanoid.MaxHealth = math.huge
	Humanoid.Health = math.huge
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false) --wth???
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)  
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	--Collisions
	for i, v:BasePart in pairs(self.Object:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Unit"
			v.Anchored = false
		end
	end
	
	self.Units = {}
	self.UnitName = Values.DataName
	self.Id = shared.Strategis.EntityIdCount
	shared.Strategis.EntityIdCount += 1
	self.ObjectType = "Squadron"
	self.SquadUnit = Values.Unit
	self.MaxLimit = Values.SquadronLimit
	self.RadiusMinMax = Values.SquadronRadiusSizeMinMax
	self.SpinConnection = nil
	--this is where you left of <3! UwU
	return self
end

local function NewMotor6d(Part0, Part1)
	local Motor6d = Instance.new("Motor6D")
	Motor6d.Part0 = Part0
	Motor6d.Part1 = Part1
	Motor6d.C0 = (Part1.Position - Part0.Position)
	Motor6d.Parent = Part0
	Motor6d.Name = Part1.Name
	
	return Motor6d
end

function Squadron:Spin()
	
end

--__add
local function AddSquadrons(self, value)
	
	return self
end

local function AddSquadronWithUnit(self, unit)
	local result:boolean = unit:JoinSquadron(self)
	
	table.insert(self.Units, unit.Id)
	
	local UnitBasePart = Instance.new("Part")
	UnitBasePart.Size = Vector3.one
	UnitBasePart.Position = 
	
	return self
end

function Squadron:__add(value)
	if #self.Units >= self.MaxLimit or typeof(value) ~= "table" then
		return self
	end
	if value.EntityType ~= nil and value.EntityType == "Unit" then 	--Is it a Unit?
		AddSquadronWithUnit(self, value)
	elseif value.ObjectType ~= nil and value.ObjectType == "Squadron" then  --Is it a Squadron?
		AddSquadrons(self, value)
	else
		warn("Unable to add object to Squadron: "..value)
	end
	
	return self
end

--__sub


return Squadron