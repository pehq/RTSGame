--Changes Gui position
local Runservice = game:GetService("RunService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Mouse = Players.LocalPlayer:GetMouse()

local ScreenGui = script.Parent
local CanvasGroup = ScreenGui.CanvasGroup

local CanvasSize = CanvasGroup.AbsoluteSize
local Vector2Pos = Vector2.zero

local TopbarSize = GuiService:GetGuiInset()

local function HoverUpdate(dt)
	if ScreenGui.Enabled == false then
		return
	end
	--Check if the Ui's size doesn't exceed the window, if it does then shift it.
	CanvasGroup.AnchorPoint = Vector2.new(Mouse.X + CanvasSize.X > Mouse.ViewSizeX and 1 or 0, Mouse.Y + CanvasSize.Y > Mouse.ViewSizeY + TopbarSize.Y and 1 or 0)
	CanvasGroup.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
end

Runservice:BindToRenderStep("HoverUpdate", Enum.RenderPriority.Camera.Value - 1, HoverUpdate)
CanvasGroup:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	CanvasSize = CanvasGroup.AbsoluteSize
end)