--????
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 60)
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI_TEAM_COLOR = {
	PlayerGui:WaitForChild("BuildGrid", 60),
	PlayerGui:WaitForChild("EntityStats", 60), 	
}

local function ChangeStrokeToTeamColor()
	local TeamColor = Player.TeamColor
	if TeamColor == nil then
		TeamColor = Color3.new(1,1,1)
	end
	
	for i, v in pairs(PlayerGui:GetDescendants()) do
		if v:IsA("UIStroke") then
			v.Color = TeamColor.Color
		end
	end
end

local EntityData = {}
for i, v in pairs(ReplicatedStorage.EntityData:GetChildren()) do
	EntityData[v.Name] = require(v)
end

Player:GetPropertyChangedSignal("TeamColor"):Connect(ChangeStrokeToTeamColor)