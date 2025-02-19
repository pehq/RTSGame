local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera
local PlayerGui = Player:WaitForChild("PlayerGui", 60)
local Events = ReplicatedStorage.Events
local Functions = ReplicatedStorage.Functions
local PlayerEntityContainers = workspace:WaitForChild(tostring(Player.UserId), 60)
local SelectionUi = PlayerGui:WaitForChild("Selection", 60)

local SelectedIds = {}