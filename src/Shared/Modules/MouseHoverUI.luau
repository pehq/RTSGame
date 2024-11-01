local Hover = {}

function Hover.ChangeTitle(plr:Player, title:string)
	plr.PlayerGui:FindFirstChild("Hover"):FindFirstChildWhichIsA("CanvasGroup"):FindFirstChild("Title").Text = title
end

function Hover.ChangeDescription(plr:Player, desc:string)
	plr.PlayerGui:FindFirstChild("Hover"):FindFirstChildWhichIsA("CanvasGroup"):FindFirstChild("Description").Text = desc 
end

function Hover.SetText(plr, title, desc)
	Hover.ChangeTitle(plr, title)
	Hover.ChangeDescription(plr, desc)
end

return Hover