local Screengui = script.Parent
local SelectionBox = Screengui.Box
local Stroke = SelectionBox.UIStroke

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Events = ReplicatedStorage.Events
local Player = Players.LocalPlayer


Player:GetPropertyChangedSignal("TeamColor"):Connect(function()
	SelectionBox.BackgroundColor3 = Player.TeamColor.Color
	Stroke.Color = Player.TeamColor.Color
end)
