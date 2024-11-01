--disable
--[[
    Testing with dummy with only one motor but both elevation and yaw constraints
]]

task.wait(1)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TurretController = require(ReplicatedStorage:FindFirstChild("TurretController",true))

local model = workspace["Assault destroyer"]
local Target = workspace.Target

local Motor6DValues = model.TurretMotor6d:GetChildren()
local ModelMotor6Ds = {}
for i,v in pairs (Motor6DValues) do
	table.insert(ModelMotor6Ds, v.Value)
end

local gunHeadConstraints = {
	["YawLeft"] = 89;
	["YawRight"] = 89;
	["ElevationAngle"] = 45;
	["DepressionAngle"] = 45;
}

local x = {}
for i, v in pairs(ModelMotor6Ds) do
	table.insert(x, TurretController.new(v, gunHeadConstraints))
end

RunService.Heartbeat:Connect(function(step)
	-- get rid of initial lag when step is around 8 when it should be small 0.02 seconds because of loading lag
	-- because it messes with PID integration calculation :(
	if step > 1 then return end
	local goalPos = Target.Position
	--normal only move towards direction of the goal
	--GunHead:LookAt(goalPos,step)

	--PID mode, more realistic ;)
		
	for i, v in pairs(x) do
		v:PIDLookAt(goalPos,step)
	end
end)