--Note: this vfx seems unoptimized... maybe optimize it for less remote usage? -Pehq
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VFX_Parts = ReplicatedStorage.VFX

local function Run(owner, Model)
	local ShotSound = VFX_Parts.ShotSound:Clone()
	ShotSound.PlayOnRemove = true
	ShotSound.Parent = Model --TODO: Change this to barrel
	ShotSound:Play()
	
	local ShootParticle = VFX_Parts.ShootParticle:Clone()
	ShootParticle:Emit(50) --TODO: Change this also to barrel... noticing a trend here....
	ShootParticle.Parent = Model
	
	local PointLight = VFX_Parts.OrangePointLight:Clone()
	PointLight.Range = 8
	PointLight.Parent = Model --TODO: Change this also to the barrel
	
	local PointLightTween = TweenService:Create(PointLight, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Range = 0})
	PointLightTween:Play()
	PointLightTween.Completed:Once(function()
		PointLight:Destroy()
	end)
	
	Debris:AddItem(ShootParticle, 1)
end

return Run