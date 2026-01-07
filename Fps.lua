if getgenv().KAMI_APA_ACTIVE then return end
getgenv().KAMI_APA_ACTIVE = true

repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
repeat task.wait() until Players.LocalPlayer
task.wait(0)

getgenv().FPS_CAP = 12
if typeof(setfpscap) == "function" then
	task.spawn(function()
		while true do
			setfpscap(getgenv().FPS_CAP)
			task.wait(1)
		end
	end)
end

getgenv().BlackModeConfig = {
	enableBlackOverlay = true,
	overlayZIndex = 100000,
	overlayTransparency = 0,
	toggleOverlayKey = Enum.KeyCode.F5
}

local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

repeat task.wait() until workspace.CurrentCamera
local Camera = workspace.CurrentCamera

local function applySafeOptimizations()
	pcall(function()
		if settings and settings().Rendering then
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end
	end)

	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 1e6
		Lighting.Brightness = 1
		Lighting.Ambient = Color3.fromRGB(50,50,50)
		Lighting.OutdoorAmbient = Color3.fromRGB(50,50,50)

		for _, v in ipairs(Lighting:GetChildren()) do
			if v:IsA("Atmosphere") then
				v.Density = 0
			elseif typeof(v.Enabled) == "boolean" then
				v.Enabled = false
			end
		end
	end)

	for _, obj in ipairs(workspace:GetDescendants()) do
		pcall(function()
			if obj:IsA("BasePart") then
				obj.LocalTransparencyModifier = 1
				obj.CastShadow = false
			elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") then
				obj.Enabled = false
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				obj.Transparency = 1
			end
		end)
	end
end

applySafeOptimizations()

workspace.DescendantAdded:Connect(function(obj)
	pcall(function()
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = 1
			obj.CastShadow = false
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") then
			obj.Enabled = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		end
	end)
end)

local overlayGui, overlayFrame
local overlayEnabled = false

local function createOverlay()
	if overlayGui then return end

	overlayGui = Instance.new("ScreenGui")
	overlayGui.Name = "KAMI_APA_BLACK"
	overlayGui.IgnoreGuiInset = true
	overlayGui.ResetOnSpawn = false
	overlayGui.Parent = CoreGui

	overlayFrame = Instance.new("Frame")
	overlayFrame.Size = UDim2.new(1,0,1,0)
	overlayFrame.BackgroundColor3 = Color3.new(0,0,0)
	overlayFrame.BackgroundTransparency = getgenv().BlackModeConfig.overlayTransparency
	overlayFrame.BorderSizePixel = 0
	overlayFrame.ZIndex = getgenv().BlackModeConfig.overlayZIndex
	overlayFrame.Parent = overlayGui

	local fpsLabel = Instance.new("TextLabel")
	fpsLabel.Size = UDim2.new(0,200,0,40)
	fpsLabel.Position = UDim2.new(0.5,-100,0,15)
	fpsLabel.BackgroundTransparency = 1
	fpsLabel.TextColor3 = Color3.new(1,1,1)
	fpsLabel.Font = Enum.Font.SourceSansBold
	fpsLabel.TextSize = 24
	fpsLabel.ZIndex = overlayFrame.ZIndex + 1
	fpsLabel.Parent = overlayGui

	local frames, last = 0, tick()
	RunService.RenderStepped:Connect(function()
		frames += 1
		if tick() - last >= 1 then
			fpsLabel.Text = "FPS : "..frames
			frames = 0
			last = tick()
		end
	end)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,200,0,40)
	btn.Position = UDim2.new(0.5,-100,0.9,0)
	btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 20
	btn.Text = "🔘 Black Screen: ON"
	btn.ZIndex = overlayFrame.ZIndex + 1
	btn.Parent = overlayGui

	btn.MouseButton1Click:Connect(function()
		overlayEnabled = not overlayEnabled
		overlayFrame.Visible = overlayEnabled
		btn.Text = overlayEnabled and "🔘 Black Screen: ON" or "⚪ Black Screen: OFF"
	end)
end

local function toggleOverlay()
	overlayEnabled = not overlayEnabled
	if overlayEnabled then
		createOverlay()
		overlayFrame.Visible = true
	elseif overlayFrame then
		overlayFrame.Visible = false
	end
end

if getgenv().BlackModeConfig.enableBlackOverlay then
	toggleOverlay()
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == getgenv().BlackModeConfig.toggleOverlayKey then
		toggleOverlay()
	end
end)

pcall(function()
	LocalPlayer.Idled:Connect(function()
		VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
		task.wait(0.1)
		VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
	end)
end)

task.spawn(function()
	while true do
		task.wait(25)
		VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
		task.wait(0.05)
		VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
	end
end)
