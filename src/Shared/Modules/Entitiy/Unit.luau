local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules

local EntityModule = require(script.Parent)
local TurretCotroller = require(Modules.TurretController)

local Unit = {}
Unit.__index = Unit

function Unit.new(Values, owner)
	local self = EntityModule.new(Values, owner)
	setmetatable(self, Unit)
	
	local Humanoid:Humanoid = self.Object:FindFirstChildWhichIsA("Humanoid")
	Humanoid.WalkSpeed = Values.Speed
	
	self.WalkSpeed = 1
	self.State = "Idle"
	self.Radius = 16
	self.TurretDefaultMotorC0 = {
		--Value = {motor6ds}, any duplicate values will be stored as one entry rather than each object having its own value
	}
	
	return self
end

function Unit:LoadAnimation(animId:string, animName:string):AnimationTrack
	local Model:Model = self.Object
	local Controller = Model:FindFirstChildWhichIsA("Humanoid") or Model:FindFirstChildWhichIsA("AnimationController")
	local Animator:Animator = Controller:FindFirstChildWhichIsA("Animator")
	
	local Animation = Instance.new("Animation")
	Animation.Name = animName ~= nil and animName or Animation.Name
	Animation.AnimationId = animId
	
	local Track = Animator:LoadAnimation(Animation)
	return Track
end

function Unit:WalkTo(pos:Vector3)	
	local Model:Model = self.Object
	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid")
	local Animations = self.Animations
	
	local WalkTrack = nil
	if Animations.Walk ~= nil then
		WalkTrack = self:LoadAnimation(Animations.Walk, "Walk") --TODO: tie movement with walk speed
		WalkTrack:Play()
		WalkTrack:AdjustSpeed(self.WalkSpeed) --TODO: this might be done in another function that speeds up animations
	end
	
	Humanoid:MoveTo(pos)
	
	local TimeSinceLastMove = 0
	local Heartbeat
	Heartbeat = RunService.Heartbeat:Connect(function(dt)
		TimeSinceLastMove += dt
		if TimeSinceLastMove >= 6 then
			Humanoid:MoveTo(pos)
		end
	end)
	
	local MoveConnection
	MoveConnection = Humanoid.MoveToFinished:Once(function()
		Heartbeat:Disconnect()
	end)
	
	local PosChange
	PosChange = Humanoid:GetPropertyChangedSignal("WalkToPoint"):Connect(function()
		if Humanoid.WalkToPoint ~= pos then
			if WalkTrack ~= nil then
				WalkTrack:Stop()
			end
			MoveConnection:Disconnect()
			Heartbeat:Disconnect()
			PosChange:Disconnect()
		end
	end)
end

local SetPos = nil
function Unit:SmartWalk(pos:Vector3) --Uses PathfindingService, very experimental and will be buggy.
	SetPos = pos
	
	local Model:Model = self.Object
	local ModelSize = Model.PrimaryPart.Size
	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid")
	
	local waypoints = nil
	local nextWaypointIndex = nil
	local reachedConnection = nil
	local blockedConnection = nil
	
	local path = PathfindingService:CreatePath({
		AgentRadius = ModelSize.X > ModelSize.Y and ModelSize.X or ModelSize.Y,
		AgentHeight = ModelSize.Y + (Model:FindFirstChildWhichIsA("Humanoid") and Model:FindFirstChildWhichIsA("Humanoid").HipHeight or 0),
		AgentCanJump = false,
		AgentCanClimb = false,
		Costs = {
			Water = math.huge
		}
	})
	
	local suc, res = pcall(function()
		path:ComputeAsync(Model.PrimaryPart.Position, pos)
	end)
	
	if suc and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()
		
		-- Detect if path becomes blocked
		blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= nextWaypointIndex then
				-- Stop detecting path blockage until path is re-computed
				blockedConnection:Disconnect()
				-- Call function to re-compute new path
				self:SmartWalk(pos)
			end
		end)
		
		-- Detect when movement to next waypoint is complete
		if not reachedConnection then
			reachedConnection = Humanoid.MoveToFinished:Connect(function(reached)
				if SetPos ~= pos or reached and nextWaypointIndex < #waypoints then
					-- Increase waypoint index and move to next waypoint
					nextWaypointIndex += 1
					Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
				else
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
				end
			end)
		end
		
		-- Initially move to second waypoint (first waypoint is path start; skip it)
		nextWaypointIndex = 2
		Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
	else
		warn("Path not computed!", res)
	end
end

function Unit:FollowTarget(otherUnit)
	local Model:Model = self.Object
	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid")
	
	Unit:WalkTo(otherUnit.Object.Position)
end

function Unit:Damage(otherUnit, dmg)
	dmg = math.abs(dmg)
	otherUnit.Health -= math.clamp(dmg, 0, dmg)
	--TODO: add modifiers
end

function Unit:AttackTarget(otherUnit)
	local Model:Model = self.Object
	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid")
	local Animations = self.Animations
	
	local OtherModel:Model = otherUnit.Object
	local OtherPart = OtherModel.PrimaryPart
	
	--Move to otherUnit until in range
	local function WalkToTarget()
		repeat
			Unit:WalkTo(OtherPart.Position)
			task.wait()
		until (Model.PrimaryPart.Position - OtherPart.Position).Magnitude <= self.Radius	
	end
	--TODO: Enter attack state
end

function Unit:Emote(EmoteNum:number)
	local Emotes = self.Animations.Emote
	if EmoteNum == nil or #Emotes < EmoteNum then
		EmoteNum = Emotes[math.random(1, #Emotes)]
	end
	--Play emote
	self.State = "Emote"
	
	local EmoteTrack:AnimationTrack = self:LoadAnimation(Emotes[EmoteNum])
	EmoteTrack:Play()
	
	repeat
		task.wait()
	until
	self.State ~= "Emote"
	
	--TODO: Add idle phase if emote ends.
	
	--Stop emote
	EmoteTrack:Stop()
	EmoteTrack:Destroy()
end

--Someunits have turrets so they'll be procedural
local function worldCFrameToC0ObjectSpace(motor6DJoint,worldCFrame) --function by dthecoolest
	local part1CF = motor6DJoint.Part1.CFrame
	local c1Store = motor6DJoint.C1
	local c0Store = motor6DJoint.C0
	local relativeToPart1 = c0Store * c1Store:Inverse() * part1CF:Inverse() * worldCFrame * c1Store
	relativeToPart1 -= relativeToPart1.Position

	local goalC0CFrame = relativeToPart1 + c0Store.Position--New orientation but keep old C0 joint position
	return goalC0CFrame
end

function Unit:AddTurrets()
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

function Unit:AimTurrets(tarpos:Vector3)
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

function Unit:ResetTurretsAim()
	local Model:Model = self.Object
	
	for i, v in pairs(self.TurretDefaultMotorC0) do
		for j = 1, #v do
			v[j].C0 = i
		end
	end
	
	return self
end

return Unit