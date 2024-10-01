local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local EntityModule = require(script.Parent)

local Unit = {}
Unit.__index = Unit

function Unit.new(Values)
	local self = EntityModule.new(Values)
	setmetatable(self, Unit)
	
	local Humanoid:Humanoid = self.Object:FindFirstChildWhichIsA("Humanoid")
	Humanoid.WalkSpeed = Values.Speed
	
	self.WalkSpeed = 1
	self.State = "Idle"
	self.Radius = 16
	
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
	
	local WalkTrack:AnimationTrack = self:LoadAnimation(Animations.Walk, "Walk") --TODO: tie movement with walk speed
	WalkTrack:Play()
	WalkTrack:AdjustSpeed(self.WalkSpeed) --TODO: this might be done in another function that speeds up animations
	
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
		WalkTrack:Stop()
		Heartbeat:Disconnect()
	end)
	
	local PosChange
	PosChange = Humanoid:GetPropertyChangedSignal("WalkToPoint"):Connect(function()
		if Humanoid.WalkToPoint ~= pos then
			WalkTrack:Stop()
			MoveConnection:Disconnect()
			Heartbeat:Disconnect()
			PosChange:Disconnect()
		end
	end)
end

function Unit:SmartWalk(pos:Vector3) --Uses pathfinding, don't use unless proper use case
	local Model:Model = self.Object
	local ModelSize = Model:GetExtentsSize()
	
	local path = PathfindingService:CreatePath({
		AgentRadius = ModelSize.X > ModelSize.Y and ModelSize.X or ModelSize.Y ,
		AgentHeight = ModelSize.Y,
		AgentCanJump = false,
		AgentCanClimb = false,
		Costs = {
			Water = 20
		}
	})
	
end

function Unit:FollowTarget(otherUnit)
	local Model:Model = self.Object
	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid")
	
	Unit:WalkTo(otherUnit.Object.Position)
end

function Unit:Damage(otherUnit, dmg)
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

return Unit