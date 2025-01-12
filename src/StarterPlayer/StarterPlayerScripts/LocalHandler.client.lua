--TODO: script needs to be rehauled, consider using ContextActionService. -Pehq
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

--Attachment thing
local TarAttachment = Instance.new("Attachment")
TarAttachment.Name = "UnitTargetBeam"
TarAttachment.Parent = workspace.Terrain
local TarAttachBeam = Instance.new("Beam")
TarAttachBeam.Name = "UnitTargetBeam"
TarAttachBeam.Attachment1 = TarAttachment

local function CreateUnitBeam(EntityModel:Model)
	if EntityModel:FindFirstChildWhichIsA("Humanoid") == false or EntityModel.PrimaryPart.AssemblyLinearVelocity == Vector3.zero then
		return
	end
	
	--TarAttachment.Position
end

local SelectedModels = {}
local function SelectModel(model)
	local SelectionBox = Instance.new("SelectionBox")
	table.insert(SelectedModels, SelectionBox)
	SelectionBox.Color3 = Player.TeamColor.Color
	SelectionBox.Adornee = model
	SelectionBox.Visible = true
	SelectionBox.Parent = model
	
	return SelectionBox
end

local function DeselectAllModels()
	for i, v in pairs(SelectedModels) do
		v:Destroy()
	end
	table.clear(SelectedModels)
end

local Box:ImageButton = SelectionUi.Box
local function SelectionUiUpdateBind(dt:number)
	local MousePos = UserInputService:GetMouseLocation()
	Box.Size = UDim2.fromOffset(MousePos.X - Box.Position.X.Offset, MousePos.Y - Box.Position.Y.Offset)
end

local function RaycastForEntities(MousePos:Vector2)
	local Length = 1000
	local UnitRay = Camera:ViewportPointToRay(MousePos.X, MousePos.Y)
	
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = {PlayerEntityContainers}
	
	local RayResult:RaycastResult = workspace:Raycast(UnitRay.Origin, UnitRay.Direction * Length, Params)
	
	local EntityModel = nil
	--Verify that instance is an entity
	if RayResult ~= nil then
		local Model = RayResult.Instance:FindFirstAncestorWhichIsA("Model")
		if Model == nil or Model:FindFirstChildWhichIsA("Configuration") == nil then
			return nil
		end
		
		EntityModel = Model
	end
	
	return EntityModel
end

local isSelectionUi = false
local function SelectAction(ActionName:string, InputState:Enum.UserInputState, InputObject:InputObject)
	if ActionName ~= "Select" then
		return Enum.ContextActionResult.Pass
	end
	
	local Selecting = {}
	local MousePos = UserInputService:GetMouseLocation()
	
	local Box:ImageButton = SelectionUi.Box
	if InputState == Enum.UserInputState.Begin then
		if InputObject:IsModifierKeyDown(Enum.ModifierKey.Shift) then
			isSelectionUi = true
			Box.Position = UDim2.fromOffset(MousePos.X, MousePos.Y)
			Box.Visible = true
			RunService:BindToRenderStep("SelectionUiUpdate", Enum.RenderPriority.Input.Value - 1, SelectionUiUpdateBind)
		end
	elseif InputState == Enum.UserInputState.Change then
		
	elseif InputState == Enum.UserInputState.End then
		if InputObject:IsModifierKeyDown(Enum.ModifierKey.Ctrl) == false then
			DeselectAllModels()
			SelectedIds = {}
		end
		
		if isSelectionUi == true then
			local StartPos = Vector2.new(Box.Position.X.Offset, Box.Position.Y.Offset)
			local endPos = UserInputService:GetMouseLocation()
			print(StartPos, endPos)
			isSelectionUi = false
			RunService:UnbindFromRenderStep("SelectionUiUpdate")
			SelectionUi.Box.Visible = false
			
			if StartPos.Y > endPos.Y then
				StartPos, endPos = Vector2.new(StartPos.X, endPos.Y), Vector2.new(endPos.X, StartPos.Y)
			end
			if StartPos.X > endPos.X then
				StartPos, endPos = Vector2.new(endPos.X, StartPos.Y), Vector2.new(StartPos.X, endPos.Y)
			end
			
			local CurPlayerEntities = PlayerEntityContainers:GetChildren()
			for i, v:Model in pairs(CurPlayerEntities) do
				local ScreenPos:Vector2, OnScreen = Camera:WorldToViewportPoint(v.PrimaryPart.Position)
				if StartPos.X <= ScreenPos.X and StartPos.Y <= ScreenPos.Y and ScreenPos.X <= endPos.X and ScreenPos.Y <= endPos.y then
					table.insert(Selecting, v:FindFirstChildWhichIsA("Configuration").Id.Value)
					SelectModel(v)
				end
			end

			print(Selecting)
		else
			local SelectedEntityModel:Model = RaycastForEntities(MousePos)
			if SelectedEntityModel ~= nil then
				local Configs = SelectedEntityModel:FindFirstChildWhichIsA("Configuration")
				table.insert(Selecting, Configs.Id.Value)
				Events.EntityInfo:Fire(require(ReplicatedStorage.EntityData:FindFirstChild(Configs.DataName.Value)).Values, Configs)
				SelectModel(SelectedEntityModel)
			else
				return Enum.ContextActionResult.Pass
			end
		end
		
		if InputObject:IsModifierKeyDown(Enum.ModifierKey.Ctrl) == true then
			table.move(Selecting, 1, #Selecting, #SelectedIds + 1, SelectedIds)
		else
			SelectedIds = Selecting
		end
	end
	
	return Enum.ContextActionResult.Pass
end

local function RightClick(ActionName:string, InputState:Enum.UserInputState, InputObject:InputObject)
	if ActionName ~= "RightClick" then
		return Enum.ContextActionResult.Pass
	end
	
	if InputState == Enum.UserInputState.Begin then
		if #SelectedIds ~= 0 then
			local Pos = Mouse.Hit.Position
			Events.MoveUnit:FireServer(SelectedIds, Pos)
			Events.SetBuildingWaypoint:FireServer(SelectedIds, Pos)
			return Enum.ContextActionResult.Sink
		end
	end
	
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("Select", SelectAction, false, Enum.UserInputType.MouseButton1)
ContextActionService:BindAction("RightClick", RightClick, false, Enum.UserInputType.MouseButton2)
