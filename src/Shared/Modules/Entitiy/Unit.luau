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
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true) --TODO: deaths will be handled manually, for now it is true
	
	--Collisions
	for i, v:BasePart in pairs(self.Object:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Unit"
			v.Anchored = false
		end
	end
	
	self.WalkSpeed = Values.Speed
	self.State = "Idle"
	self.Radius = 16
	self.TurretDefaultMotorC0 = {} --Value = {motor6ds}, any duplicate values will be stored as one entry rather than each object having its own value
	if self.CanJoinSquadron == true then
		self.IsInSquadron = false
	end
	
	if self.CanBuild == true then
		self.BuildProgressTime = 0
	end
	
	return self
end

function Unit:IdleAnimReset() --Removes all tasks and animations
	local Model:Model = self.Object
	local Animator = Model:FindFirstChildWhichIsA("Humanoid"):FindFirstChildWhichIsA("Animator") or Model:FindFirstChildWhichIsA("AnimationController"):FindFirstChildWhichIsA("Animator")
	
	local PlayingTracks = Animator:GetPlayingAnimationTracks()
	for i, track in pairs(PlayingTracks) do
		track:Stop()
	end
	
	--Play Idle Anim
	if self.Animations.Idle ~= nil then	
		local AnimTrack:AnimationTrack = self:LoadAnimation()
		AnimTrack:Play()
	end
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
	MoveConnection = Humanoid.MoveToFinished:Once(function()
		if self.State == "Walking" then
			self.State = "Idle"
		end
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

function Unit:JoinSquadron(Squadron):boolean --This unit has joined a squadron and will no longer partake in normal unit behaviour
	if self.CanJoinSquadron == false then
		return false
	end

	--TODO: Add code to join squadron
end

function Unit:LeaveSquadron(Squadron) --This Unit has reentered society
	
end

return Unit