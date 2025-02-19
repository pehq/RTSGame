local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

if workspace:FindFirstChild("Effects") == nil then
	Instance.new("Folder", workspace).Name = "Effects"
end

local function lerp (a, b, t)
	return a + (b-a) * t
end

local function RandomFloat(Min, Max)
	return math.random() * (Max - Min) + Min
end

local function BulletEffect(Amount, Start:Vector3, End, Clone)
	for n = 1, Amount do
		local Clone = Clone:Clone()
		Clone.Position = Start
		Clone.Anchored = true
		Clone.Parent = workspace.Effects
		Debris:AddItem(Clone, 7)
		local P1 = End + Vector3.new(RandomFloat(-1,1), RandomFloat(-1,1), RandomFloat(-1,1))

		task.wait(0.1)
		for i = 0, 10, 0.5 do
			local t = i / 10

			local l1 = lerp(Start, P1, t) --Why not `Start:Lerp(P1, t)` ???
			local l2 = lerp(P1, End, t)

			local quad = lerp(l1,l2, t)		
			Clone.Position = quad

			task.wait()
		end

		game:GetService("Debris"):AddItem(Clone, 0.1)
	end
end

local function Run(owner:Player, Am:number, Start:Vector3, End:Vector3, Model: Model)
	Model.Barrel.Main.Shot:Play()
	Model.Barrel.Main.Shoot:Emit(20)
	Model.Barrel.Main.PointLight.Range = 8
	TweenService:Create(Model.Barrel.Main.PointLight,TweenInfo.new(.7,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Range = 0}):Play()
	BulletEffect(Am,Start,End, workspace.EnergyBullet)
end

return Run