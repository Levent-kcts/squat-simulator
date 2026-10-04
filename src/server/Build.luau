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
function Build.ceilingLight(parent, name, size, position, range)
	local panel = Instance.new("Part")
	panel.Name = name
	panel.Anchored = true
	panel.CanCollide = false
	panel.CanQuery = false
	panel.CastShadow = false
	panel.Size = size
	panel.Position = position
	panel.Material = Enum.Material.Neon
	panel.Color = Color3.fromRGB(228, 231, 242) -- saf beyaz Neon aşırı parlıyordu
	panel.Parent = parent

	local light = Instance.new("PointLight")
	light.Range = range
	light.Brightness = 0.4
	light.Color = Color3.fromRGB(235, 240, 255)
	light.Shadows = false
	light.Parent = panel
	return panel
end

return Build
