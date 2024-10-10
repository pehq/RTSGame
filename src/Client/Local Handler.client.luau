local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local RemoteFunctions = ReplicatedStorage.Functions
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Selected = nil
Mouse.Button1Down:Connect(function()
	Selected = nil
end)

Mouse.Button1Up:Connect(function()
	local ObjPointed = Mouse.Target
	if ObjPointed == nil then
		return
	end
	local Entity = RemoteFunctions.GetEntityFromInstance:InvokeServer(ObjPointed.Parent)
	print(Entity)
end)

Mouse.Button2Up:Connect(function()
	local TargetPos = Mouse.Hit.Position
end)