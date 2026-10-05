-- Lobideki raf kurucusu (ayakkabı rafı, skin rafı ve antrenman alanı aynı standı kullanır): duvara yaslı, 3 basamaklı şerit
-- (tepsi), her şeritte birkaç postament, iki uçta rampa, duvarda başlık. Ayakkabı/skin rafında postamentin üstüne basınca
-- satın alınır; antrenman alanında pede girmek TrainingArea tarafından izlenir (buy verilmez). Postamentin rengi, etiketleri
-- ve fiyat bilgisi oyuncuya özeldir ve istemcide (client/ShelfClient, client/TrainingClient) ayarlanır.
-- Raf yerel eksenlerle kurulur: yerel -Z duvardan salonun ortasına (izleyiciye) doğru, yerel X rafın uzunluğu boyunca.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local Build = require(script.Parent.Build)

local Shelf = {}

-- Varsayılan ölçüler (ayakkabı/skin rafı). spec.layout ile üstüne yazılır.
local DEFAULT_LAYOUT = {
	perRow = 5, -- her şeritteki ped sayısı (rowCounts verilmezse)
	rowCounts = nil, -- şerit başına ped sayısı { 4, 3, 3 } gibi (alttan üste); verilirse perRow yerine geçer, pedler ortalanır
	rowPadSizes = nil, -- şerit başına ped boyutu { 8.5, 11, 13.5 }: üst şeritlerde ped büyür (padSize yerine)
	laneDepths = nil, -- şerit başına derinlik { 12, 14.5, 17 } (laneDepth yerine)
	rowLength = nil, -- verilirse her şeridin ped dizisi bu uzunluğu doldurur (aralık = rowLength / ped sayısı; padSpacing yerine)
	-- Ped ölçüsü sahibinin verdiği referans ekran görüntüsünden ölçüldü (yeşil ped, yandan): karakter boyuna oranla ped ~0.94 genişlik x ~0.23 yükseklik,
	-- yani GENİŞ ve alçak (en/boy ~4:1), altında kenarlardan taşan ince gri çerçeve. Normal boyda karakterde (~5.3 stud) bu ~4.8 x 1.2 stud eder.
	-- (Eskiden 4 x 1.6 küp gibi duruyordu 'çok kalın'; sonra 0.35 yapıldı, o da referanstan çok ince kaldı.)
	padSize = 4.8, -- postament genişliği/derinliği
	padHeight = 1.2,
	padSpacing = 6.5, -- aynı sıradaki postamentler arası (merkezden merkeze)
	laneDepth = 8, -- her sıranın (şeridin) derinliği, postamentin yaklaşık 2 katı
	rimHeight = 1, -- şeritleri çevreleyen açık renkli kenar
	rimThickness = 1,
	tierHeights = { 0.4, 3.4, 6.4 }, -- 1. şerit yerde (hafif yükseltilmiş), 2. şerit 3.4, 3. şerit 6.4 stud
	rampWidth = 6,
	signSize = Vector3.new(32, 5, 0.5),
	signY = 15,
	displayLift = 0.5, -- eşyanın postament tepesinden yüksekliği
	padZOffset = 0.5, -- postamentin şerit ortasına göre yerel Z kayması (eksi: izleyiciye doğru)
	displayZ = 0, -- eşyanın postamente göre yerel Z kayması (artı: duvara doğru, yumurta pedin arkasında durur)
	padMaterial = Enum.Material.Neon,
	frameColor = Color3.fromRGB(95, 102, 145), -- postamentin altındaki girinti çerçevesi
}
local TRY_DEBOUNCE = 3 -- aynı eşyaya art arda deneme arası (saniye), mesaj yağmasın

local PLATFORM_COLOR = Color3.fromRGB(140, 150, 205)
local RIM_COLOR = Color3.fromRGB(178, 186, 228) -- şeritleri çevreleyen açık renkli kenar

-- Sol duvara yaslı raf çerçevesi. zOffset: rafın duvar boyunca kayması (stud, + arka duvara/yumurtalara doğru).
function Shelf.leftWallFrame(zOffset)
	return CFrame.new(-Config.Lobby.HalfWidth, 0, zOffset) * CFrame.Angles(0, -math.pi / 2, 0)
end

-- Arka duvara yaslı raf çerçevesi (yumurtalar): salonun ortasında, yerel -Z salonun ortasına bakar.
function Shelf.backWallFrame()
	return CFrame.new(0, 0, Config.Lobby.BackZ)
end

-- Sağ duvara yaslı raf çerçevesi (yerel -Z yine salonun ortasına bakar).
function Shelf.rightWallFrame(zOffset)
	return CFrame.new(Config.Lobby.HalfWidth, 0, zOffset) * CFrame.Angles(0, math.pi / 2, 0)
end

-- Raf kurar. spec:
--   name: Workspace'te klasör adı (istemci bunu bekler), frame: raf çerçevesi (leftWallFrame / rightWallFrame),
--   title / signColor: duvardaki başlık, items: Config listesi (id, color alanları gerekli; şerit kapasitelerinin toplamı kadar),
--   layout (isteğe bağlı): DEFAULT_LAYOUT alanlarını değiştirir,
--   padColor(item) (isteğe bağlı): postamentin başlangıç rengi (varsayılan kırmızı; ayakkabı/skinde istemci boyar),
--   sparkles (isteğe bağlı, varsayılan true): postamentin üstünde parıltı,
--   buildDisplay(parent, item, frame, center, slot): postamentin üstündeki eşyayı çizer (center = yerel konum, slot.row = şerit),
--   maxGlowIndex (isteğe bağlı): bu sıradan sonra postament ışığı artmaz,
--   buy(player, item) -> ok, mesaj (isteğe bağlı): postamente basınca çağrılır (satın alır ya da takar; mesaj nil ise
--   bildirim gitmez), notifyEvent: mesajı oyuncuya yollar
-- Dönüş: klasör, pads ([eşya id] = postament parçası)
function Shelf.build(spec)
	local L = table.clone(DEFAULT_LAYOUT)
	for key, value in spec.layout or {} do
		L[key] = value
	end

	local frame = spec.frame
	local folder = Instance.new("Folder")
	folder.Name = spec.name
	folder.Parent = Workspace

	local floorTop = Layout.FloorTop

	-- Yerel konumla blok kurar (dünya konumuna frame ile çevirir)
	local function block(name, size, localPosition, color, material, studs)
		local part = Build.block(folder, name, size, localPosition, color, material, studs)
		part.CFrame = frame * CFrame.new(localPosition)
		return part
	end

	-- Üç şerit (sıra): 3. şerit duvara yaslı ve en yüksek, 2. şerit onun önünde, 1. şerit yerde en önde.
	-- Referans oyundaki gibi her şerit bir tepsi: zemin + ön ve yan kenarlarda açık renkli çıkıntı (rim).
	-- Şerit sayısı rowCounts'tan gelir (2 ya da 3): 1. şerit en önde ve yerde, sonuncusu duvara yaslı ve en yüksek.
	local rowCounts = L.rowCounts or { L.perRow, L.perRow, L.perRow }
	local rowTotal = #rowCounts
	local rows = {}
	local depths = {}
	for i = 1, rowTotal do
		depths[i] = if L.laneDepths then L.laneDepths[i] else L.laneDepth
	end
	-- Şerit merkezi duvardan başlayarak hesaplanır (son şerit duvara yaslı): arkasındaki şeritlerin derinlikleri toplanır
	local behind = 0
	for i = rowTotal, 1, -1 do
		rows[i] = { z = -(behind + depths[i] / 2), y = floorTop + L.tierHeights[i], depth = depths[i] }
		behind += depths[i]
	end
	-- Şerit başına ped sayısı: şeritlerin uzunluğu en kalabalık şeride göre, daha az pedli şeritte pedler ortalanır
	local widest = 0
	for _, count in rowCounts do
		widest = math.max(widest, count)
	end
	local shelfLength = (if L.rowLength then L.rowLength else L.padSpacing * widest) + 6
	local slots = {} -- eşya sırası -> { şerit, sütun, şeritteki ped sayısı }
	for rowIndex = 1, rowTotal do
		for column = 1, rowCounts[rowIndex] do
			table.insert(slots, { row = rowIndex, column = column, count = rowCounts[rowIndex] })
		end
	end

	for rowIndex = 1, rowTotal do
		local height = L.tierHeights[rowIndex]
		local z = rows[rowIndex].z
		local depth = rows[rowIndex].depth
		-- Şeridin zemini (basamak)
		block(
			`Lane_{rowIndex}`,
			Vector3.new(shelfLength, height, depth),
			Vector3.new(0, floorTop + height / 2, z),
			PLATFORM_COLOR,
			Enum.Material.Plastic,
			true
		)
		-- Ön kenar çıkıntısı
		block(
			`Rim_{rowIndex}`,
			Vector3.new(shelfLength, L.rimHeight, L.rimThickness),
			Vector3.new(0, floorTop + height + L.rimHeight / 2, z - depth / 2 + L.rimThickness / 2),
			RIM_COLOR,
			Enum.Material.Plastic,
			true
		)
		-- Yan kenar çıkıntıları
		for _, side in { -1, 1 } do
			block(
				`SideRim_{rowIndex}_{side}`,
				Vector3.new(L.rimThickness, L.rimHeight, depth),
				Vector3.new(side * (shelfLength / 2 - L.rimThickness / 2), floorTop + height + L.rimHeight / 2, z),
				RIM_COLOR,
				Enum.Material.Plastic,
				true
			)
		end
	end

	-- Rafın iki ucunda rampa: yerden başlar, 2. şeridin yüksekliğinde kısa bir düzlük (referanstaki çentik) yapar,
	-- sonra üst şeridin yüksekliğine çıkar. Basamaklar 0.4 stud olduğu için yürürken rampa gibi hissedilir.
	local rampFront = rows[1].z - rows[1].depth / 2 -- rampanın yerdeki başlangıcı
	local rampLength = -rampFront
	local profile = {} -- { { z başlangıç, uzunluk, yükseklik } ... }
	local function addSlope(zStart, length, fromHeight, toHeight)
		local steps = math.max(1, math.ceil((toHeight - fromHeight) / 0.4))
		local run = length / steps
		for i = 1, steps do
			table.insert(profile, { zStart + (i - 1) * run, run, fromHeight + (toHeight - fromHeight) * i / steps })
		end
	end
	if rowTotal >= 3 then
		-- 3 şerit: 2. şeridin yüksekliğinde kısa düzlük, sonra üst şerit
		local flatLength = rampLength * 0.12
		local slopeLength = (rampLength - flatLength) / 2
		addSlope(rampFront, slopeLength, 0, L.tierHeights[2])
		table.insert(profile, { rampFront + slopeLength, flatLength, L.tierHeights[2] })
		addSlope(rampFront + slopeLength + flatLength, slopeLength, L.tierHeights[2], L.tierHeights[3])
	elseif rowTotal == 2 then
		addSlope(rampFront, rampLength, 0, L.tierHeights[2])
	end
	for _, side in { -1, 1 } do
		for index, step in profile do
			local z, run, height = step[1], step[2], step[3]
			block(
				`Ramp_{side}_{index}`,
				Vector3.new(L.rampWidth, height, run),
				Vector3.new(side * (shelfLength / 2 + L.rampWidth / 2), floorTop + height / 2, z + run / 2),
				PLATFORM_COLOR,
				Enum.Material.Plastic,
				true
			)
		end
	end

	-- Duvardaki başlık
	local sign = block("Sign", L.signSize, Vector3.new(0, L.signY, -0.3), spec.signColor, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Text = spec.title
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(40, 25, 0)
	stroke.Parent = title

	-- Postamentler ve eşyalar
	local lastTry = {} -- [userId] = { [itemId] = zaman }
	Players.PlayerRemoving:Connect(function(player)
		lastTry[player.UserId] = nil
	end)

	local pads = {}
	for index, item in spec.items do
		local slot = slots[index]
		local row = rows[slot.row]
		local padSize = if L.rowPadSizes then L.rowPadSizes[slot.row] else L.padSize
		local spacing = if L.rowLength then L.rowLength / slot.count else L.padSpacing
		local x = (slot.column - (slot.count + 1) / 2) * spacing

		block(
			`PadFrame_{item.id}`,
			Vector3.new(padSize + 0.9, 0.15, padSize + 0.9), -- pedin her kenarından 0.45 taşan ince çerçeve
			Vector3.new(x, row.y + 0.075, row.z + L.padZOffset),
			L.frameColor,
			Enum.Material.Plastic
		)

		local pad = block(
			`Pad_{item.id}`,
			Vector3.new(padSize, L.padHeight, padSize),
			Vector3.new(x, row.y + L.padHeight / 2, row.z + L.padZOffset),
			if spec.padColor then spec.padColor(item) else Color3.fromRGB(255, 50, 50), -- ayakkabı/skinde istemci oyuncuya göre yeşil/kırmızı/sarı yapar
			L.padMaterial
		)
		pad:SetAttribute("ItemId", item.id)
		pads[item.id] = pad

		-- Raftaki sıra güçle artar: sondaki (en güçlü) eşya daha parlak ve geniş ışık verir
		local tier = (math.min(index, spec.maxGlowIndex or #spec.items) - 1) / math.max(1, #spec.items - 1)
		local light = Instance.new("PointLight")
		light.Range = 7 + 5 * tier
		light.Brightness = 0.5 + 1 * tier
		light.Color = item.color
		light.Shadows = false
		light.Parent = pad

		-- Eşyanın üstünde süzülen parıltılar (eşyanın renginde)
		if spec.sparkles ~= false then
			local sparkles = Instance.new("ParticleEmitter")
			sparkles.Color = ColorSequence.new(item.color)
			sparkles.LightEmission = 0.8
			sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
			sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
			sparkles.Lifetime = NumberRange.new(1, 1.8)
			sparkles.Rate = 8
			sparkles.Speed = NumberRange.new(1, 3)
			sparkles.SpreadAngle = Vector2.new(60, 60)
			sparkles.Parent = pad
		end

		spec.buildDisplay(folder, item, frame, Vector3.new(x, row.y + L.padHeight + L.displayLift, row.z + L.padZOffset + L.displayZ), slot)

		if spec.buy then
			pad.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end

				local tries = lastTry[player.UserId]
				if not tries then
					tries = {}
					lastTry[player.UserId] = tries
				end
				local now = os.clock()
				if now - (tries[item.id] or 0) < TRY_DEBOUNCE then
					return
				end
				tries[item.id] = now

				local ok, message = spec.buy(player, item)
				if message then -- zaten takılı eşyaya basınca mesaj yok (üstünde dururken yağmasın)
					spec.notifyEvent:FireClient(player, ok, message)
				end
			end)
		end
	end

	return folder, pads
end

return Shelf
