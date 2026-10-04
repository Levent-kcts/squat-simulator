-- Basit manken: kafa, gövde, kollar, bacaklar ve siyah şort. Skin rafındaki skin mankeni ve antrenman alanındaki antrenör
-- yer tutucusu bunu kullanır. Yüzü izleyiciye (yerel -Z) bakar, tabanı center yüksekliğindedir.
local Mannequin = {}

local SHORTS_COLOR = Color3.fromRGB(20, 20, 25)

-- parent: modelin konacağı klasör, name: model adı, frame: raf çerçevesi, center: yerel taban konumu,
-- scale: boyut (1 = ~5.3 stud boy), skin: vücut rengi, shorts: şort rengi (varsayılan siyah)
function Mannequin.build(parent, name, frame, center, scale, skin, shorts)
	local model = Instance.new("Model")
	model.Name = name

	local function part(partName, size, offset, color, shape)
		local p = Instance.new("Part")
		p.Name = partName
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = size * scale
		p.CFrame = frame * CFrame.new(center + offset * scale)
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		return p
	end

	for _, side in { -1, 1 } do
		part("Leg", Vector3.new(0.9, 2, 0.9), Vector3.new(side * 0.5, 1, 0), skin)
		part("Arm", Vector3.new(0.8, 2, 0.8), Vector3.new(side * 1.45, 3, 0), skin)
	end
	part("Shorts", Vector3.new(2, 0.9, 1.1), Vector3.new(0, 1.9, 0), shorts or SHORTS_COLOR)
	part("Torso", Vector3.new(2, 1.9, 1), Vector3.new(0, 3.05, 0), skin)
	part("Head", Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 4.65, 0), skin, Enum.PartType.Ball)

	-- Basit yüz (iki göz)
	for _, side in { -1, 1 } do
		part("Eye", Vector3.new(0.18, 0.18, 0.18), Vector3.new(side * 0.28, 4.75, -0.62), Color3.fromRGB(30, 30, 40), Enum.PartType.Ball)
	end

	model.Parent = parent
	return model
end

return Mannequin
