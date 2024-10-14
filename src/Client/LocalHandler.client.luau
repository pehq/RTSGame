local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local RemoteEvents = ReplicatedStorage.Events
local RemoteFunctions = ReplicatedStorage.Functions

local Selected = nil
local SelectionBox = Instance.new("SelectionBox")
Mouse.Button1Down:Connect(function()
	Selected = nil
	SelectionBox.Visible = false
	SelectionBox.Adornee = nil
end)

Mouse.Button1Up:Connect(function()
	local ObjPointed = Mouse.Target
	if ObjPointed == nil then
		return
	end
	
	local Entity = RemoteFunctions.GetEntityFromInstance:InvokeServer(ObjPointed.Parent)
	Selected = Entity
	
	if Entity == nil then
		return
	end
	
	SelectionBox.Visible = true
	SelectionBox.Adornee = ObjPointed.Parent
	SelectionBox.Parent = ObjPointed.Parent
end)

Mouse.Button2Up:Connect(function()
	local TargetPos = Mouse.Hit.Position
	if Selected == nil or Selected.EntityId == nil then
		return
	end
	RemoteEvents.MoveEntity:FireServer(TargetPos, Selected.EntityId)
end)