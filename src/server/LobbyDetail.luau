-- Lobi süsleri (sahibi başka bir oyunun lobisinin ekran görüntülerini verip 'bu oyundaki harita düzenine benzet' dedi; duvar + tavan + zemin seçildi): lego tuğla derzli duvar, studlu sütunlar, alt şerit ve ortada koyu bant;
-- kirişli (kasetli) tavan; koridor ağzından yumurta standına giden yolun kenar çıkıntıları. Sadece GÖRÜNTÜDÜR (oyun mantığı yok), EnvironmentService.init sonunda pcall ile çağrılır: hata verirse lobi yine kurulu kalır.
-- Dikkat: raflar (sol duvar), antrenman alanı (sağ duvar), yumurta standı ve Worlds kemeri duvara YASLI durur; buradaki parçalar duvardan en çok 0.35 (şeritler) ya da 1.4 (sütunlar) taşar,
-- sütunlar bu yüzden rafların ve rampaların durmadığı yerlere konur. Derz şeritleri 0.25 taşar (duvardaki studlar 0.2): studların üstünde kalıp görünürler, 0.3 taşan kemer/tabela yüzleriyle titreşmezler.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Build = require(script.Parent.Build)

local LobbyDetail = {}

local SEAM_COLOR = Color3.fromRGB(120, 130, 186) -- tuğla derzleri
local BASE_COLOR = Color3.fromRGB(122, 132, 188) -- alt şerit
local BAND_COLOR = Color3.fromRGB(137, 147, 203) -- duvarın ortasındaki koyu bant
local PILASTER_COLOR = Color3.fromRGB(178, 186, 232) -- studlu sütunlar duvardan açık
local BEAM_COLOR = Color3.fromRGB(139, 149, 206) -- tavan kirişleri
local CURB_COLOR = Color3.fromRGB(108, 117, 174) -- yol kenarı

-- geo: { folder, widthLeft, widthRight, back, zFront, ceiling, corridorCeiling, openingHalf, floorTop, lightColumns, lightRows }
function LobbyDetail.init(geo)
	local cfg = Config.Lobby.Detail
	if not cfg or not cfg.Enabled then
		return
	end
	local folder = geo.folder
	local ceiling, floorTop = geo.ceiling, geo.floorTop
	local frontInner = geo.zFront + 2 -- giriş duvarının iç yüzü (duvar bloğu 2 kalın)

	-- Parça kurar: collide = true yalnızca sütunlarda
	local function piece(name, size, position, color, material, collide, studs)
		local part = Build.block(folder, name, size, position, color, material or Enum.Material.Plastic, studs)
		part.CanCollide = collide == true
		if not collide then
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
		end
		return part
	end

	-- Duvar düzlemi: along = 'x' (arka/ön duvar: duvar boyunca x) ya da 'z' (yan duvarlar); face = duvarın iç yüzünün sabit koordinatı; into = salona doğru yön (+1 / -1)
	local function wallPlane(axis, face, into)
		local plane = {}
		-- Duvar boyunca u'da, y yüksekliğinde, duvara depth taşan, length x height boyutunda parça
		function plane.add(name, u0, u1, y0, y1, depth, color, collide, studs)
			local length, height = u1 - u0, y1 - y0
			local u, y, offset = (u0 + u1) / 2, (y0 + y1) / 2, face + into * depth / 2
			local size, position
			if axis == "x" then
				size, position = Vector3.new(length, height, depth), Vector3.new(u, y, offset)
			else
				size, position = Vector3.new(depth, height, length), Vector3.new(offset, y, u)
			end
			return piece(name, size, position, color, nil, collide, studs)
		end
		return plane
	end

	local walls = {
		{ name = "Back", plane = wallPlane("x", geo.back, -1), u0 = -geo.widthLeft, u1 = geo.widthRight, yFrom = 0 },
		{ name = "Left", plane = wallPlane("z", -geo.widthLeft, 1), u0 = frontInner, u1 = geo.back, yFrom = 0 },
		{ name = "Right", plane = wallPlane("z", geo.widthRight, -1), u0 = frontInner, u1 = geo.back, yFrom = 0 },
		{ name = "FrontL", plane = wallPlane("x", frontInner, 1), u0 = -geo.widthLeft, u1 = -geo.openingHalf, yFrom = 0 },
		{ name = "FrontR", plane = wallPlane("x", frontInner, 1), u0 = geo.openingHalf, u1 = geo.widthRight, yFrom = 0 },
		{ name = "FrontTop", plane = wallPlane("x", frontInner, 1), u0 = -geo.openingHalf, u1 = geo.openingHalf, yFrom = geo.corridorCeiling + 1 }, -- koridorun üstündeki duvar
	}

	local courseHeight, brickLength = cfg.CourseHeight, cfg.BrickLength
	local baseTop = cfg.BaseHeight
	local topLimit = ceiling - cfg.BeamHeight -- üstteki kiriş bölgesine derz çizilmez
	local courses = math.floor((topLimit - baseTop) / courseHeight)

	for _, wall in walls do
		local plane = wall.plane
		-- Alt şerit (koyu, studlu) ve ortadaki koyu bant (düz, duvarın tek 'kat'ı)
		if wall.yFrom == 0 then
			plane.add(`Base_{wall.name}`, wall.u0, wall.u1, floorTop, baseTop, 0.35, BASE_COLOR, false, true)
		end
		for course = 0, courses do
			local yLow = baseTop + course * courseHeight
			if yLow >= wall.yFrom then
				-- Yatay derz: kat sınırı
				plane.add(`Seam_{wall.name}_{course}`, wall.u0, wall.u1, yLow, yLow + 0.3, 0.25, SEAM_COLOR)
				if course < courses then
					if course == cfg.BandCourse then
						plane.add(`Band_{wall.name}`, wall.u0, wall.u1, yLow + 0.3, yLow + courseHeight, 0.15, BAND_COLOR)
					else
						-- Dikey derzler: her kat yarım tuğla kayık (lego duvar gibi); duvarın uçlarına derz konmaz
						local offset = if course % 2 == 0 then 0 else brickLength / 2
						local u = wall.u0 + brickLength - offset
						while u < wall.u1 - 1 do
							plane.add(`Joint_{wall.name}`, u - 0.15, u + 0.15, yLow + 0.3, yLow + courseHeight, 0.25, SEAM_COLOR)
							u += brickLength
						end
					end
				end
			end
		end
	end

	-- Studlu sütunlar (referanstaki köşe/ara sütunlar): sadece raf ve rampa olmayan yerlerde. Hepsi tavana kadar çıkar.
	local pilasterWidth, pilasterDepth = cfg.PilasterWidth, cfg.PilasterDepth
	local function pilaster(wallName, u)
		for _, wall in walls do
			if wall.name == wallName then
				wall.plane.add(`Pilaster_{wallName}`, u - pilasterWidth / 2, u + pilasterWidth / 2, floorTop, ceiling, pilasterDepth, PILASTER_COLOR, true, true)
			end
		end
	end
	local pilasterOffset = geo.openingHalf + pilasterWidth / 2
	pilaster("FrontL", -pilasterOffset) -- koridor ağzının iki yanı
	pilaster("FrontR", pilasterOffset)
	for _, x in cfg.BackPilasters do
		pilaster("Back", x)
	end
	pilaster("Back", geo.widthRight - pilasterWidth / 2) -- sağ arka köşe
	for _, z in cfg.RightPilasters do
		pilaster("Right", z)
	end

	-- Kirişli tavan: duvar boyunca çevre kirişi + ışık panelleri arasında enine/boyuna kirişler (her panel bir 'kaset'in içinde kalır)
	local function beam(name, x0, x1, z0, z1, height, color)
		local size = Vector3.new(x1 - x0, height, z1 - z0)
		return piece(name, size, Vector3.new((x0 + x1) / 2, ceiling - height / 2, (z0 + z1) / 2), color or BEAM_COLOR, nil, false, true)
	end
	local width = cfg.BeamWidth
	beam("BeamBack", -geo.widthLeft, geo.widthRight, geo.back - width, geo.back, cfg.BeamHeight)
	beam("BeamFront", -geo.widthLeft, geo.widthRight, frontInner, frontInner + width, cfg.BeamHeight)
	beam("BeamLeft", -geo.widthLeft, -geo.widthLeft + width, frontInner, geo.back, cfg.BeamHeight)
	beam("BeamRight", geo.widthRight - width, geo.widthRight, frontInner, geo.back, cfg.BeamHeight)
	local innerBeam = cfg.InnerBeamHeight
	local innerWidth = cfg.InnerBeamWidth
	local rows = geo.lightRows
	for index = 1, #rows - 1 do
		local z = (rows[index] + rows[index + 1]) / 2 -- iki ışık sırasının ortası
		beam("BeamCross", -geo.widthLeft, geo.widthRight, z - innerWidth / 2, z + innerWidth / 2, innerBeam)
	end
	local columns = table.clone(geo.lightColumns)
	table.sort(columns)
	for index = 1, #columns - 1 do
		local x = (columns[index] + columns[index + 1]) / 2
		beam("BeamLong", x - innerWidth / 2, x + innerWidth / 2, frontInner, geo.back, innerBeam)
	end

	-- Yol kenarları (referanstaki zemin çizgileri): koridorun iki kenarı hizasında, koridor ağzından yumurta standının önüne kadar
	if cfg.PathCurb then
		local stand = Config.Lobby.BackZ - (11 + 11 + Config.Worlds.TerraceDepth) -- yumurta standının ön kenarı
		local z0, z1 = frontInner + 1, stand - 2
		for _, side in { -1, 1 } do
			piece(
				"PathCurb",
				Vector3.new(cfg.PathCurbWidth, cfg.PathCurbHeight, z1 - z0),
				Vector3.new(side * cfg.PathHalfWidth, floorTop + cfg.PathCurbHeight / 2, (z0 + z1) / 2),
				CURB_COLOR,
				nil,
				true,
				true
			)
		end
	end
end

return LobbyDetail
