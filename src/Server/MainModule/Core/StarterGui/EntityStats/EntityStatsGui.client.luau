local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageData = require(ReplicatedStorage.OtherData.EntityImageData)
local ViewportModel = require(ReplicatedStorage.Modules.ViewportModel)

local Events = ReplicatedStorage.Events

local ScreenGui = script.Parent
local Body = ScreenGui["Entity stats"]

local TmpObj = {}
local function ClearTmpObj()
	for i, v:Instance in pairs(TmpObj) do
		if v:IsA("Instance") then
			v:Destroy()
		end
		
		v = nil
	end
end

local function UpdateScrollSize(child)
	local ScrollFrame:ScrollingFrame = child.Parent
	local UIGridLayout = ScrollFrame:FindFirstChildWhichIsA("UIGridLayout")
	
	ScrollFrame.CanvasSize = UDim2.fromOffset(0, UIGridLayout.AbsoluteContentSize.Y + 10)
end

UpdateScrollSize(Body["production frame"].UIGridLayout)

local function EntityInfoReceived(Entity)
	if Entity.Owner ~= Players.LocalPlayer then
		return
	end	
	--Entity Name
	Body["Entity name"].Text = Entity.Name
	
	--Entity Icon
	local EntityImage = ImageData.EntityIcons[Entity.Name]
	if EntityImage == nil then
		local ViewportGenerated = ViewportModel.GenerateViewportFullshot(Entity.Object:Clone())
		if ViewportGenerated:FindFirstChildWhichIsA("Model"):FindFirstChildWhichIsA("SelectionBox") then
			ViewportGenerated:FindFirstChildWhichIsA("Model"):FindFirstChildWhichIsA("SelectionBox"):Destroy()
		end
		ViewportGenerated.Position = UDim2.new()
		ViewportGenerated.Size = UDim2.fromScale(1, 1)
		ViewportGenerated.BackgroundColor3 = Color3.fromRGB(53,53,53)
		ViewportGenerated.Parent = Body["Entity icon"]
		
		table.insert(TmpObj, ViewportGenerated)
	end
	
	--stats
	if Entity.Health and Entity.MaxHealth then
		Body.Hull.Text = string.format("%d/%d", Entity.Health, Entity.MaxHealth)
		Body.Hull.Visible = true
	else
		Body.Hull.Visible = false
	end
	if Entity.Shield and Entity.MaxShield then
		Body.Shield.Text = string.format("%d/%d", Entity.Shield, Entity.MaxShield)
		Body.Hull.Visible = true
	else
		Body.Hull.Visible = false
	end
	
	--Building production line
	local isBuilding = Entity.EntityType == "Building"
	Body["production frame"].Visible = isBuilding
	Body["Entity production"].Visible = isBuilding
	
	ScreenGui.Enabled = true --Will show if there are no errors
end

local function EntityDeselected(Entity)
	ClearTmpObj()
	ScreenGui.Enabled = false
end

Body["production frame"].ChildAdded:Connect(UpdateScrollSize)
Body["production frame"].ChildRemoved:Connect(UpdateScrollSize)
Events.EntityInfo.Event:Connect(EntityInfoReceived)
Events.EntityDeselected.Event:Connect(EntityDeselected)