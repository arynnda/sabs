-- 1. Matikan Rendering 3D Utama (Jika executor mendukung fungsi ini)
pcall(function()
    set3drendering(false)
end)

-- 2. Metode Alternatif: Hapus Tekstur & Efek Visual di Workspace
-- Pastikan logika skrip farming kamu mencari data di folder BASE, bukan di Model Karakter/Backpack agar tidak error!
local workspace = game:GetService("Workspace")
local lighting = game:GetService("Lighting")

-- Matikan efek pencahayaan berat
lighting.GlobalShadows = false
lighting.FogEnd = 9e9

-- Hapus visual yang membebani GPU/VRAM
local function cleanVisuals(obj)
    if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("CornerWedgePart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Color = Color3.fromRGB(0, 0, 0) -- Ubah jadi hitam polos
    elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
        obj:Destroy() -- Hapus total efek partikel dan tekstur
    end
end

-- Jalankan pembersihan pada objek yang sudah ada
for _, v in pairs(workspace:GetDescendants()) do
    cleanVisuals(v)
end

-- Jalankan pembersihan untuk objek baru yang muncul saat game berjalan
workspace.DescendantAdded:Connect(cleanVisuals)
