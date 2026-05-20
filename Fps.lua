if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local MaterialService = game:GetService("MaterialService")

local player = Players.LocalPlayer
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

pcall(function()
	local old = CoreGui:FindFirstChild("BlackOverlay")
	if old then
		old:Destroy()
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BlackOverlay"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Enabled = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.Position = UDim2.new(0, 0, 0, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Parent = gui

local text = Instance.new("TextLabel")
text.AnchorPoint = Vector2.new(0.5, 0.5)
text.Position = UDim2.new(0.5, 0, 0.5, 0)
text.Size = UDim2.new(0, 500, 0, 60)

text.BackgroundTransparency = 1
text.Text = player.Name
text.TextColor3 = Color3.fromRGB(255, 255, 255)
text.TextSize = 40
text.Font = Enum.Font.GothamBold
text.Parent = frame

pcall(function()
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

pcall(function()
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.Brightness = 0
	Lighting.ClockTime = 14
	Lighting.ExposureCompensation = 0
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
end)

for _, v in pairs(Lighting:GetChildren()) do
	pcall(function()
		if v:IsA("PostEffect")
		or v:IsA("Sky")
		or v:IsA("Atmosphere") then
			v:Destroy()
		end
	end)
end

pcall(function()
	if Terrain then
		Terrain.WaterWaveSize = 0
		Terrain.WaterWaveSpeed = 0
		Terrain.WaterReflectance = 0
		Terrain.WaterTransparency = 1
		Terrain.Decoration = false
	end
end)

for _, obj in pairs(Workspace:GetDescendants()) do
	pcall(function()

		if obj:IsA("BasePart") then
			obj.Material = Enum.Material.Plastic
			obj.Reflectance = 0
			obj.CastShadow = false

			if obj.Transparency >= 0.95 then
				obj:Destroy()
			end
		end

		if obj:IsA("Decal")
		or obj:IsA("Texture") then
			obj.Transparency = 1
		end

		if obj:IsA("ParticleEmitter")
		or obj:IsA("Trail")
		or obj:IsA("Smoke")
		or obj:IsA("Fire")
		or obj:IsA("Sparkles")
		or obj:IsA("Beam") then
			obj.Enabled = false
		end

		if obj:IsA("SpecialMesh")
		or obj:IsA("MeshPart") then
			pcall(function()
				obj.TextureID = ""
			end)
		end

	end)
end

pcall(function()
	for _, material in pairs(MaterialService:GetChildren()) do
		material:Destroy()
	end
end)
getgenv().BlackScreenOn = function()
	if gui then
		gui.Enabled = true
	end
end

getgenv().BlackScreenOff = function()
	if gui then
		gui.Enabled = false
	end
end
