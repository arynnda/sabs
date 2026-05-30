if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local MaterialService = game:GetService("MaterialService")

pcall(function()
	if setfpscap then
		setfpscap(6)
	end
end)

for _,v in ipairs(Lighting:GetChildren()) do
	if v:IsA("Sky")
	or v:IsA("Atmosphere")
	or v:IsA("BloomEffect")
	or v:IsA("BlurEffect")
	or v:IsA("ColorCorrectionEffect")
	or v:IsA("SunRaysEffect")
	or v:IsA("DepthOfFieldEffect") then
		v:Destroy()
	end
end

Lighting.GlobalShadows = false
Lighting.Brightness = 0
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0

Lighting.Ambient = Color3.new(1,1,1)
Lighting.OutdoorAmbient = Color3.new(1,1,1)

Lighting.FogColor = Color3.new(1,1,1)
Lighting.FogStart = 0
Lighting.FogEnd = 100000

local cc = Instance.new("ColorCorrectionEffect")
cc.Parent = Lighting
cc.Saturation = -1
cc.Brightness = 0.4
cc.Contrast = -0.6
cc.TintColor = Color3.new(1,1,1)

for _,obj in ipairs(game:GetDescendants()) do
	pcall(function()

		if obj:IsA("ParticleEmitter")
		or obj:IsA("Trail")
		or obj:IsA("Smoke")
		or obj:IsA("Fire")
		or obj:IsA("Sparkles")
		or obj:IsA("Beam") then
			obj:Destroy()
		end

		if obj:IsA("Texture")
		or obj:IsA("Decal") then
			obj.Transparency = 1
		end

		if obj:IsA("SpecialMesh") then
			obj.TextureId = ""
		end

		if obj:IsA("BasePart") then
			obj.CastShadow = false
			obj.Reflectance = 0
			obj.Material = Enum.Material.SmoothPlastic

			obj.Color = Color3.fromRGB(255,255,255)
		end

	end)
end

if Terrain then
	pcall(function()
		Terrain.WaterWaveSize = 0
		Terrain.WaterWaveSpeed = 0
		Terrain.WaterReflectance = 0
		Terrain.WaterTransparency = 1
	end)
end

workspace.DescendantAdded:Connect(function(obj)
	task.defer(function()
		pcall(function()

			if obj:IsA("ParticleEmitter")
			or obj:IsA("Trail")
			or obj:IsA("Smoke")
			or obj:IsA("Fire")
			or obj:IsA("Sparkles")
			or obj:IsA("Beam") then
				obj:Destroy()
			end

			if obj:IsA("Texture")
			or obj:IsA("Decal") then
				obj.Transparency = 1
			end

			if obj:IsA("BasePart") then
				obj.CastShadow = false
				obj.Material = Enum.Material.SmoothPlastic
				obj.Color = Color3.new(1,1,1)
			end

		end)
	end)
end)
