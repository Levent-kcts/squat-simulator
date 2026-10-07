-- Blender modelleri (pet ve yumurta): sahibi Studio'nun 3B içe aktarıcısıyla FBX'i alır ve oluşan modeli ReplicatedStorage > GameModels klasörüne koyar (adım adım: README, Blender bölümü).
-- Bu modül o klasörden modeli bulur ve kopyasını DOĞRU BOYUTTA verir. İçe aktarma ölçeği ne olursa olsun boyut ModelInfo'daki (Blender'dan otomatik üretilen) ölçüye göre ayarlanır.
-- Model yoksa (klasör yok ya da o model henüz yüklenmemiş) nil döner ve çağıran yer eski kod modeline (küre / kod yumurtası) düşer: oyun modelsiz de eksiksiz çalışır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelInfo = require(script.Parent.ModelInfo)

local ModelLibrary = {}

-- Klasörde adı 'name' olan MeshPart (ya da içinde MeshPart bulunan Model) kaynağı
local function findSource(name)
	local folder = ReplicatedStorage:FindFirstChild("GameModels")
	if not folder then
		return nil
	end
	local fallback = nil
	for _, item in folder:GetDescendants() do
		if item.Name == name then
			if item:IsA("MeshPart") then
				return item
			elseif item:IsA("Model") and not fallback then
				fallback = item:FindFirstChildWhichIsA("MeshPart", true)
			end
		end
	end
	return fallback
end

function ModelLibrary.has(name)
	return ModelInfo[name] ~= nil and findSource(name) ~= nil
end

-- Modelin kopyası: Anchored, çarpışmasız, boyu ModelInfo[name].size x scale. Dönüş: MeshPart, MODEL ORİJİNİNE (tabanın ortası) göre kutu merkezi (ölçekli).
-- Yerleştirme: part.CFrame = orijinCFrame * CFrame.new(merkez). Önü -Z'dir (Roblox'un 'ileri'si), yani oyuncunun baktığı yöne bakar.
function ModelLibrary.create(name, scale)
	local info = ModelInfo[name]
	local source = findSource(name)
	if not info or not source then
		return nil
	end
	scale = scale or 1
	local part = source:Clone()
	for _, child in part:GetChildren() do
		if child:IsA("Script") or child:IsA("LocalScript") then
			child:Destroy()
		end
	end
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Color = Color3.new(1, 1, 1) -- renkler palet dokusundan gelir, boya karıştırma
	part.Size = info.size * scale
	return part, info.center * scale
end

return ModelLibrary
