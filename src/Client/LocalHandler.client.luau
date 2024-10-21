local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Events = ReplicatedStorage.Events
local Functions = ReplicatedStorage.Functions

local Selected = nil
local SelectionBox = Instance.new("SelectionBox")
Mouse.Button1Down:Connect(function()
	Events.EntityDeselected:Fire(Selected)
	
	Selected = nil
	SelectionBox.Visible = false
	SelectionBox.Adornee = nil
end)

Mouse.Button1Up:Connect(function()
	local ObjPointed = Mouse.Target
	if ObjPointed == nil then
		return
	end
	
	local Entity = Functions.GetEntityFromInstance:InvokeServer(ObjPointed.Parent)
	Selected = Entity
	
	if Entity == nil then
		return
	end
	
	Events.EntityInfo:Fire(Entity)
	
	SelectionBox.Visible = true
	SelectionBox.Adornee = ObjPointed.Parent
	SelectionBox.Parent = ObjPointed.Parent
end)

Mouse.Button2Up:Connect(function()
	local TargetPos = Mouse.Hit.Position
	if Selected == nil or Selected.EntityId == nil then
		return
	end
	Events.MoveEntity:FireServer(TargetPos, Selected.EntityId)
end)