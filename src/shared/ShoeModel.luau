-- Tek bir ayakkabının parça listesi (sadece raftaki ayakkabı modeli, server/ShoeShop). Karakterin ayağındaki ayakkabı
-- parça eklemez: AppearanceCleaner ayak parçasını ayakkabının neon renginde boyar ve ışık ekler. Blender modeli gelince burası değişir.
-- Birim uzayı: genişlik 2.6, uzunluk 6 (burun -Z yönünde), taban alt yüzü y = BOTTOM, kenarın tepesi BOTTOM + HEIGHT.
local Config = require(script.Parent.Config)

local ShoeModel = {}

-- Ayakkabının güç kademesi: Config.Items zayıftan güçlüye sıralıdır; 0 = en zayıf, 1 = en güçlü
local tierById = {}
for index, item in Config.Items do
	tierById[item.id] = (index - 1) / math.max(1, #Config.Items - 1)
end

-- Parlaklık Config.MaxGlowShoeId'ye (Neon Kicks) kadar artar, daha güçlü ayakkabılar aynı parlaklıkta kalır
local glowCap = tierById[Config.MaxGlowShoeId] or 1

function ShoeModel.tier(item)
	return math.min(tierById[item.id] or 0, glowCap)
end

-- Neon rengin yoğunluğu güçle artar: en zayıf ayakkabı %55 parlaklıkta, Neon Kicks ve üstü %87 (raf ve ayak aynı rengi kullanır)
function ShoeModel.neonColor(item)
	local brightness = 0.55 + 0.45 * ShoeModel.tier(item)
	local color = item.color
	return Color3.new(color.R * brightness, color.G * brightness, color.B * brightness)
end

ShoeModel.WIDTH = 2.6
ShoeModel.LENGTH = 6
ShoeModel.BOTTOM = -0.3
ShoeModel.HEIGHT = 3.1

local SOLE_COLOR = Color3.fromRGB(235, 235, 235)
local DARK = Color3.fromRGB(40, 40, 48)

-- item: Config.Items satırı (color, damage). Dönüş: { { name, size, offset, color, material } ... } (ayakkabı tek, ortada)
function ShoeModel.parts(item)
	local body = ShoeModel.neonColor(item)
	local toe = body:Lerp(Color3.new(1, 1, 1), 0.35)
	local bodyMaterial = Enum.Material.Neon -- tüm ayakkabılar neon (canlı, parlak renk)

	return {
		{ name = "Sole", size = Vector3.new(2.6, 0.6, 6), offset = Vector3.new(0, 0, 0), color = SOLE_COLOR, material = Enum.Material.SmoothPlastic },
		{ name = "Heel", size = Vector3.new(2.4, 2, 3), offset = Vector3.new(0, 1.3, 1.4), color = body, material = bodyMaterial },
		{ name = "Toe", size = Vector3.new(2.4, 1.2, 2.8), offset = Vector3.new(0, 0.9, -1.6), color = toe, material = bodyMaterial },
		{ name = "Collar", size = Vector3.new(2.2, 0.6, 1.8), offset = Vector3.new(0, 2.5, 1.5), color = DARK, material = Enum.Material.SmoothPlastic },
		{ name = "Stripe", size = Vector3.new(2.6, 0.4, 1.2), offset = Vector3.new(0, 1.5, 0.2), color = DARK, material = Enum.Material.SmoothPlastic },
	}
end

return ShoeModel
