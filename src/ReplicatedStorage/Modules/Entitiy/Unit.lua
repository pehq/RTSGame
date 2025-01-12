local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local ServerEvents = ServerStorage.Events
local Modules = ReplicatedStorage.Modules

local EntityModule = require(script.Parent)
local TurretCotroller = require(Modules.TurretController)

local Unit = {}
Unit.__index = Unit
setmetatable(Unit, EntityModule)

function Unit.new(Values, owner)
	local self = EntityModule.new(Values, owner)
	setmetatable(self, Unit)
	
	--Humanoid
	local Humanoid:Humanoid = self.Object:FindFirstChildWhichIsA("Humanoid")
	Humanoid.WalkSpeed = Values.Speed
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,		false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,			true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,			false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,			false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,			true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,				false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,				true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,			true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,			false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,				false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,	true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,				true) --TODO: deaths will be handled manually, for now it is true
	
	--Collisions
	for i, v:BasePart in pairs(self.Object:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Unit"
			v.Anchored = false
		end
	end
	
	self.WalkSpeed = Values.Speed
	self.State = "Idle"
	self.Radius = 16 --???? --maybe attack radius??
	self.WalkToDestination = Vector3.zero
	self.TurretDefaultMotorC0 = {} --Value = {motor6ds}, any duplicate values will be stored as one entry rather than each object having its own value
	if self.CanJoinSquadron == true then
		self.IsInSquadron = false
	end
	
	if self.CanBuild == true then
		self.BuildProgressTime = 0
	end
	
	--Configs
	self:NewConfig("WalkToDestination", Instance.new("Vector3Value"))
	
	--if self.Animations.Idle ~= nil then
	--	local AnimTrack:AnimationTrack = self:LoadAnimation(self.Animations.Idle)
	--	AnimTrack:Play()
	--end
	
	return self
end

function Unit:ResetAnimsAndPlayeIdle() --Removes all tasks and animations, WILL CAUSE ANIMATION BUGS!!!
	local Model:Model = self.Object
	local Animator = Model:FindFirstChildWhichIsA("Humanoid"):FindFirstChildWhichIsA("Animator") ~= nil and Model:FindFirstChildWhichIsA("Humanoid"):FindFirstChildWhichIsA("Animator") or Model:FindFirstChildWhichIsA("AnimationController"):FindFirstChildWhichIsA("Animator")
	
	local PlayingTracks = Animator:GetPlayingAnimationTracks()
	for i, track in pairs(PlayingTracks) do
		track:Stop()
	end
	
	--Play Idle Anim
	if self.Animations.Idle ~= nil then	
		local AnimTrack:AnimationTrack = self:LoadAnimation(self.Animations.Idle)
		AnimTrack:Play()
	end
end

function Unit:WalkTo(pos:Vector3) --TODO: Animations are bugged!
	local Model:Model = self.Object
	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid")
	
	self.WalkToDestination = pos
	self:UpdateConfigkey("WalkToDestination")
	
	local WalkTrack:AnimationTrack = nil
	if self.Animations.Walk ~= nil then
		WalkTrack = self:LoadAnimation(self.Animations.Walk, "Walk") --TODO: tie movement with walk speed
		WalkTrack:Play()
		--WalkTrack:AdjustSpeed(1) --TODO: this might be done in another function that speeds up animations
	end
	
	Humanoid:MoveTo(pos)
	self.State = "Walking"
	
	local TimeSinceLastMove = 0
	local Heartbeat
	Heartbeat = RunService.Heartbeat:Connect(function(dt)
		TimeSinceLastMove += dt
		if TimeSinceLastMove >= 6 then
			Humanoid:MoveTo(pos)
		end
	end)
	
	local MoveConnection
	MoveConnection = Humanoid.MoveToFinished:Connect(function()
		if self.State == "Walking" then
			if WalkTrack ~= nil and WalkTrack.IsPlaying == true then
				WalkTrack:Stop()
			end
			self.State = "Idle"
		end
		Heartbeat:Disconnect()
	end)
	
	local PosChange
	PosChange = Humanoid:GetPropertyChangedSignal("WalkToPoint"):Connect(function()
		if Humanoid.WalkToPoint ~= pos then
			if self.State == "Walking" then
				if WalkTrack ~= nil and WalkTrack.IsPlaying == true then
					WalkTrack:Stop()
				end
			end
			MoveConnection:Disconnect()
			Heartbeat:Disconnect()
			PosChange:Disconnect()
		end
	end)
end

function Unit:SmartWalk(pos:Vector3) --Uses PathfindingService, very experimental and will be buggy.
	local Model:Model = self.Object
	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid")
	local Animations = self.Animations
	
	Model.PrimaryPart:SetNetworkOwner(nil)
	self.WalkToDestination = pos
	self:UpdateConfigkey("WalkToDestination")
	
	local waypoints
	local nextWaypointIndex
	local reachedConnection
	local blockedConnection
	
	local Path = PathfindingService:CreatePath({
		AgentRadius = Model.PrimaryPart.Size.X < Model.PrimaryPart.Size.Z and Model.PrimaryPart.Size.X or Model.PrimaryPart.Size.Z,
		AgentHeight = Model.PrimaryPart.Size.Y,
		AgentCanJump = false,
		AgentCanClimb = false,
		Costs = {
			Water = math.huge,
			Danger = math.huge,
		}}
	)
	
	local function FollowPath(destination)
		local suc, err = pcall(function()
			Path:ComputeAsync(Model.PrimaryPart.Position, destination)
		end)
		
		if suc and Path.Status == Enum.PathStatus.Success then
			waypoints = Path:GetWaypoints()
			
			blockedConnection = Path.Blocked:Connect(function(blockedWaypointIndex)
				if blockedWaypointIndex >= nextWaypointIndex then
					FollowPath(destination)
					blockedConnection:Disconnect()
				end
			end)
			
			if not reachedConnection then
				reachedConnection = Humanoid.MoveToFinished:Connect(function(reached)
					if reached and nextWaypointIndex < #waypoints and pos == self.WalkToDestination then
						nextWaypointIndex += 1
						Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
					else
						blockedConnection:Disconnect()
						reachedConnection:Disconnect()
					end
				end)
			end
			
			nextWaypointIndex = 2
			Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
		else
			warn("Path not computed!", err)
		end
	end
	
	FollowPath(pos)
end

function Unit:FollowTarget(otherUnit) --TODO: needs to actually follow the unit if the followed unit moves
	local Model:Model = self.Object
	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid")
	
	Unit:WalkTo(otherUnit.Object.Position)
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

function Unit:BuildBuilding(BuildingDataName, BuildCFrame:CFrame)
	local Model:Model = self.Object
	--Look for slot in entity
	local Slot = nil
	for i, v in pairs(self.BuildSlots) do
		if v.DataName == BuildingDataName then
			Slot = v
			break
		end
	end
	
	if not self.CanBuild or (BuildCFrame.Position - Model.PrimaryPart.Position).Magnitude > self.BuildRange or Slot == nil then
		return self
	end
	
	self.State = "Building"
	local StartTime = os.time()
	
	repeat
		self.BuildProgressTime = os.time() - StartTime
		task.wait()
	until self.State ~= "Building" or os.time() - StartTime >= Slot.BuildTime
	
	if self.State == "Building" then --success
		ServerEvents.SpawnUnit:Fire(BuildingDataName, BuildCFrame)
		self.State = "Idle"
	end
	
	return self
end

--Commented code is too fancy to be finished now.
--[[function Unit:ProgressSpawnBuildBuilding(BuildingDataName, BuildCFrame:CFrame, Percentage) --This spawns an unfinished building with a progress percentage, it'll be built up.
--	if not Percentage then
--		Percentage = 0
--	else
--		Percentage = math.clamp(Percentage, 0, 1)
--	end
	
--	local Model:Model = self.Object
	
--	local Slot = nil
--	for i, v in pairs(self.BuildSlots) do
--		if v.DataName == BuildingDataName then
--			Slot = v
--			break
--		end
--	end
	
--	if not self.CanBuild or (BuildCFrame.Position - Model.PrimaryPart.Position).Magnitude > self.BuildRange or Slot == nil then
--		return self
--	end
	
--	self.State = "Building"
--	local TimeOffset = self.BuildTime * Percentage
--	local StartTime = os.time()
	
--	--TODO: Spawn the RootPart of the building at BuildCFrame and make it look like it's being built up. If there is already a percentage done then have that percentage done.
	
--	repeat
--		Percentage = (os.time() - StartTime + TimeOffset) / Slot.BuildTime
--		self.BuildProgressTime = Percentage
--		task.wait()
--	until self.State ~= "Building" or os.time() - StartTime >= Slot.BuildTime - TimeOffset
	
--	if self.State == "Building" then --success
--		ServerEvents.SpawnUnit:Fire(BuildingDataName, BuildCFrame) --TODO: Replace building with a finished version
--		self.State = "Idle"
--	end
	
--	return self
--end]]

--Squadron stuff is **VERY** experimental
function Unit:JoinSquadron(Squadron):boolean --This unit has joined a squadron and will no longer partake in normal unit behaviour
	if self.CanJoinSquadron == false then
		return false
	end

	--TODO: Add code to join squadron
end

function Unit:LeaveSquadron(Squadron) --This Unit has reentered society
	
end

return Unit