-- Sabit dünya parçaları (zemin, duvar, tavan) oluşturmak için küçük yardımcılar.
local Build = {}

-- studs = true ise parçanın yüzeyleri "lego çıkıntılı" olur (sadece Plastic malzemede görünür)
function Build.block(parent, name, size, position, color, material, studs)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	if studs then
		part.TopSurface = Enum.SurfaceType.Studs
		part.BottomSurface = Enum.SurfaceType.Studs
		part.LeftSurface = Enum.SurfaceType.Studs
		part.RightSurface = Enum.SurfaceType.Studs
		part.FrontSurface = Enum.SurfaceType.Studs
		part.BackSurface = Enum.SurfaceType.Studs
	end
	part.Parent = parent
	return part
end

-- Tavandan sarkan parlak ışık paneli. Salonu aydınlatır.
-- color / brightness verilmezse varsayılanlar kullanılır (lobide Config.Lighting değerleri geçilir)
function Build.ceilingLight(parent, name, size, position, range, color, brightness)
	local panel = Instance.new("Part")
	panel.Name = name
	panel.Anchored = true
	panel.CanCollide = false
	panel.CanQuery = false
	panel.CastShadow = false
	panel.Size = size
	panel.Position = position
	panel.Material = Enum.Material.Neon
	panel.Color = color or Color3.fromRGB(205, 212, 240) -- Neon'da açık renk göz alır, bu yüzden beyaza yakın değil
	panel.Parent = parent

	local light = Instance.new("PointLight")
	light.Range = range
	light.Brightness = brightness or 0.25
	light.Color = Color3.fromRGB(235, 240, 255)
	light.Shadows = false
	light.Parent = panel
	return panel
end

-- Tavan panelinin çevresinde yumuşak ışık halesi: SADECE tavan yüzeyine çizilir (aşağıya inen parıltı yok).
-- Şeffaf, ince bir parçanın alt yüzüne SurfaceGui; içinde küçülen şeffaf yuvarlak kareler üst üste biner ve kenarları yumuşatır.
function Build.ceilingHalo(parent, name, position, size, layers, alpha)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(size, 0.02, size)
	part.Position = position
	part.Parent = parent

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Bottom
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 16
	gui.LightInfluence = 0
	gui.Adornee = part
	gui.Parent = part
	for index = 1, layers do
		local scale = 1 - (index - 1) / layers * 0.6 -- 1.0'dan ~0.5'e küçülür
		local layer = Instance.new("Frame")
		layer.AnchorPoint = Vector2.new(0.5, 0.5)
		layer.Position = UDim2.fromScale(0.5, 0.5)
		layer.Size = UDim2.fromScale(scale, scale)
		layer.BackgroundColor3 = Color3.fromRGB(235, 240, 255)
		layer.BackgroundTransparency = 1 - alpha
		layer.BorderSizePixel = 0
		layer.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.3, 0)
		corner.Parent = layer
	end
	return part
end

return Build
