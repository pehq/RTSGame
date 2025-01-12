--PehqDev
local Lighting = game:GetService("Lighting")

local Generator = {}

--TODO: Abstract the Viewmodel creation and add Headshot and BodyBust
local function GenerateViewport(CamCFrame:CFrame)
	local ViewportFrame = Instance.new("ViewportFrame")

	local SkyClone = Lighting:FindFirstChild("Sky") and Lighting:FindFirstChild("Sky"):Clone() or nil
	if SkyClone ~= nil then
		SkyClone.Parent = ViewportFrame
	end

	local ViewCam = Instance.new("Camera")
	ViewCam.Name = "ViewCam"
	ViewCam.CFrame = CamCFrame
	ViewCam.Parent = ViewportFrame

	ViewportFrame.CurrentCamera = ViewCam

	return ViewportFrame
end

local function GetCFrameFromBounds(Bounds:Vector3, ZoomOffset:number)
	local HighestValue = math.max(Bounds.X, Bounds.Y, Bounds.Z) * ZoomOffset
	local CamCFrame = CFrame.lookAt(Vector3.new(HighestValue, HighestValue, -HighestValue), Vector3.zero)
	local Result = CFrame.lookAt(Vector3.new(HighestValue, HighestValue, -HighestValue), Vector3.zero)
	
	return Result
end

function Generator.GenerateViewportFullshot(Model:Model, ZoomOffset:number)
	if ZoomOffset == nil then ZoomOffset = 0.5 end
	
	Model:PivotTo(CFrame.new())
	
	local ViewportFrame = GenerateViewport(GetCFrameFromBounds(Model:GetExtentsSize(), ZoomOffset))
	Model.Parent = ViewportFrame
	
	return ViewportFrame
end

function Generator.GenerateViewportHeadshot(Model:Model, HeadOfModel:BasePart, ZoomOffset:number)
	if ZoomOffset == nil then ZoomOffset = 0.5 end
	if HeadOfModel == nil then HeadOfModel = Model.PrimaryPart end
	
	Model:PivotTo(CFrame.new())
	
	local ViewportFrame = GenerateViewport(GetCFrameFromBounds(HeadOfModel.Size, ZoomOffset))
	Model.Parent = ViewportFrame

	return ViewportFrame
end

return Generator