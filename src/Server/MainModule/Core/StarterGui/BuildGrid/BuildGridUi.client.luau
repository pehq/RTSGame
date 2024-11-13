local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage.Events
local RemoteFunctions = ReplicatedStorage.Functions
local EntityData = ReplicatedStorage.EntityData
local RepUIs = ReplicatedStorage.UI

local ViewportModel = require(ReplicatedStorage.Modules.ViewportModel)

local ScreenGui = script.Parent
local CanvasGroup = ScreenGui:FindFirstChildWhichIsA("CanvasGroup")
local ScrollingFrame = CanvasGroup:FindFirstChildWhichIsA("ScrollingFrame")

local function DestroyButtons()
	for i, v in pairs(ScrollingFrame:GetChildren()) do
		if v:IsA("ImageButton") then
			v:Destroy()
		end	
	end
end

local Connections = {}
local function DisconnectConnections()
	for i, v in pairs(Connections) do
		v:Disconnect()
	end
end

Events.EntityInfo.Event:Connect(function(entity)
	local Owner = entity
	if entity.EntityType ~= "Building" or not entity.CanBuildUnits then
		return
	end
	
	DestroyButtons()
	
	local UnitSlotData = entity.BuildSlots
	
	for i = 1, #UnitSlotData do
		local CurrentSlot = UnitSlotData[i]
		local SlotUi = RepUIs.BuildUI.BuildSlot:Clone()
		if not CurrentSlot.Icon then
			local Model = CurrentSlot.Object:Clone()
			local Viewport = ViewportModel.GenerateViewportFullshot(Model)
			Viewport.BackgroundTransparency = 1
			Viewport.Position = UDim2.new()
			Viewport.Interactable = false
			Viewport.Size = UDim2.fromScale(1, 1)
			Viewport.Parent = SlotUi
		else
			SlotUi.Image = CurrentSlot.Icon
		end
		SlotUi:FindFirstChildWhichIsA("StringValue").Value = CurrentSlot.DataName
		SlotUi:FindFirstChildWhichIsA("NumberValue").Value = CurrentSlot.BuildTime
		SlotUi.LayoutOrder = i
		SlotUi.Name = "Slot".. i
		SlotUi.Visible = true
		SlotUi.Modal = true
		SlotUi.Parent = ScrollingFrame
		
		local MouseClick
		MouseClick = SlotUi.MouseButton1Click:Connect(function()
			Events.BuildUnit:FireServer(entity.EntityId, CurrentSlot.DataName, CurrentSlot.BuildTime)
		end)
		
		table.insert(Connections, MouseClick)
	end
	
	ScreenGui.Enabled = true
	
	Events.EntityDeselected.Event:Once(function(entity)
		DestroyButtons()
		ScreenGui.Enabled = false
	end)
end)