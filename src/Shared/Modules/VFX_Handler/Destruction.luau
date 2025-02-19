local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VFX_Parts = ReplicatedStorage.VFX

if workspace:FindFirstChild("Effects") == nil then
	Instance.new("Folder", workspace).Name = "Effects"
end

if workspace.Effects.DestroyedShip == nil then
	Instance.new("Folder", workspace.Effects).Name = "DestroyedShip"
end

local function Run(owner, Am, Start:Vector3, End:Vector3, Model:Model, Destruction)
	local ModelClone = Model:Clone()
	ModelClone.PrimaryPart.CFrame *= CFrame.new(0,5,0)
	ModelClone.Parent = workspace.Effects.DestroyedShip

	task.wait(5)

	local BoomP = VFX_Parts.Boom:Clone()
	BoomP.CFrame = ModelClone.PrimaryPart.CFrame
	BoomP.Parent = workspace.Effects

	for i, v in pairs(BoomP:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			v:Emit(250)
		elseif v:IsA("Sound") then
			v:Play()
		end
	end

	for i, v in pairs(ModelClone:GetDescendants()) do
		if v:IsA("BasePart") then
			local AntiGravityPart = Instance.new("Part")
			AntiGravityPart.CFrame = v.CFrame
			AntiGravityPart.Shape = Enum.PartType.Ball
			AntiGravityPart.Size = v.Size
			AntiGravityPart.Transparency = 1
			AntiGravityPart.Parent = workspace.Effects.DestroyedShip

			local Weight = AntiGravityPart:GetMass() * 196.2
			local Att = Instance.new("Attachment", AntiGravityPart)
			local VF = Instance.new("VectorForce")
			VF.RelativeTo = Enum.ActuatorRelativeTo.World
			VF.Attachment0 = Att
			VF.Force = Vector3.new(0, Weight, 0)
			VF.Parent = AntiGravityPart

			local Weld = Instance.new("WeldConstraint")
			Weld.Name = "GravityThing"
			Weld.Part0 = AntiGravityPart
			Weld.Part1 = v
			Weld.Parent = AntiGravityPart

			v.Anchored = false
			v.CanCollide = false
			v.Massless = true
			v.Parent = AntiGravityPart

			task.spawn(function()
				task.wait(math.random(24,28))
				local tween = TweenService:Create(v,TweenInfo.new(10,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency = 1})
				tween:Play()
				tween.Completed:Once(function()
					AntiGravityPart:Destroy()
				end)
			end)

			task.wait()
		elseif v.Name ~= "GravityThing" then
			v:Destroy()
		end

		Debris:AddItem(ModelClone, 30)
	end
end

return Run