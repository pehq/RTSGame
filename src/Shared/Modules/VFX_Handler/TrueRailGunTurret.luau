local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VFX_Parts = ReplicatedStorage.VFX

if workspace:FindFirstChild("Effects") == nil then
	Instance.new("Folder", workspace).Name = "Effects"
end

local function Run(owner, Start, End, Model: Model)
	local Bullet = VFX_Parts.Ammo:Clone()
	Bullet.Position = Model.Barrel.Main.Position
	Bullet.CFrame = CFrame.new(Start,End) -- * CFrame.new(0,0,-dist/2)--:PointToObjectSpace(workspace.Target.Position)
	Bullet.Parent = workspace.Effects
	
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
	
	local PointlightTween = TweenService:Create(PointLight, TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Range = 0})
	PointlightTween:Play()
	PointlightTween.Completed:Once(function()
		PointLight:Destroy()
	end)
	
	local BulletTween = TweenService:Create(Bullet,TweenInfo.new(.2,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{Position = End})
	BulletTween:Play()
	
	Debris:AddItem(Bullet, 1)
	Debris:AddItem(ShootParticle, 1)
end

return Run