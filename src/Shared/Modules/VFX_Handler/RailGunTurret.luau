local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Modules = ReplicatedStorage.Modules
local VFX_Parts = ReplicatedStorage.VFX

local LightningModule = require(Modules.LS_Module)

if workspace:FindFirstChild("Effects") == nil then
	Instance.new("Folder", workspace).Name = "Effects"
end

local function Run(owner, Start:Vector3, End:Vector3, Model:Model)
	task.wait(1)
	local dist = (End - Start).Magnitude

	local ShockWave = VFX_Parts.Shockwave:Clone()
	ShockWave.Size = Vector3.new(1.5, 1.5, dist)
	ShockWave.CFrame = CFrame.new(Start,End) * CFrame.new(0,0,-dist/2)
	ShockWave.Parent = workspace.Effects

	local tween = TweenService:Create(ShockWave,TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),{Size = Vector3.new(0,0,dist)})
	tween:Play()
	
	tween.Completed:Wait()
	
	ShockWave:Destroy()
	
	local ShotSound = VFX_Parts.ShotSound:Clone()
	ShotSound.PlayOnRemove = true
	ShotSound.Parent = Model --TODO: Change this to barrel
	ShotSound:Play()
	
	local PointLight = VFX_Parts.OrangePointLight:Clone()
	PointLight.Range = 15
	PointLight.Parent = Model --TODO: Change this also to the barrel
	
	local LightTween = TweenService:Create(PointLight,TweenInfo.new(.7,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Range = 0})
	LightTween:Play()
	LightTween.Completed:Once(function()
		PointLight:Destroy()
	end)
	
	for i= 1, math.random(2,3) do		
		LightningModule.Bolt(Start, End, 10,1,.2)
		task.wait()
	end
	local ShootParticle = VFX_Parts.ShootParticle:Clone()
	ShootParticle:Emit(50) --TODO: Change this also to barrel... noticing a trend here....
	ShootParticle.Parent = Model
	
	local HitPart = VFX_Parts.Hit:Clone()
	HitPart.Position = End
	HitPart.CFrame = CFrame.lookAt(End, Start)
	HitPart.Attachment.Shoot:Emit(70)
	HitPart.Parent = workspace.Effects
	
	Debris:AddItem(ShootParticle, 5)
	Debris:AddItem(HitPart, 5)
end

return Run