-- Günlük çarkın YÜZÜ: 8 renkli dilim (pasta), ince beyaz ayırıcı çizgiler, simge + ad + yüzde yazıları. Hem lobideki 3B çarkın SurfaceGui'sinde (server/WheelService)
-- hem de E'ye basınca açılan arayüzde (client/WheelPanel) AYNI kodla çizilir.
-- Dilim şekli: Roblox arayüzünde pasta dilimi yoktur; 8 dilimin sınırları 0/45/90... derecede olduğu için her dilim, bir çeyrek karenin köşegeniyle kesilmiş DİK ÜÇGENDİR:
-- çeyrek kareye (UIGradient) şeffaflık basamağı verilerek köşegenin bir yanı gizlenir. Sonra bütün dilimler bir CanvasGroup içinde yuvarlak köşeyle (UICorner) daireye kırpılır
-- (kırpılmış köşeler görünmez), köşegenlerin tırtıkları ayırıcı çizgilerin altında kalır. Dilim sayısı SEKİZ olmak zorundadır (Config.Wheel.Prizes).
local WheelFace = {}

local SLICE_COUNT = 8

-- Dilim i (1 = üstte, saat yönünde; açı aralığı [(i-1) * 45, i * 45]): hangi çeyrek kare (x, y konumu, 0 ya da 0.5), gradyan dönüşü ve gradyanın hangi yarısı görünür
-- (first = gradyan konumu < 0.5 olan yarı görünür). Dönüş +45: yön sağ-aşağı (kesim ters köşegen), -45: yön sağ-yukarı (kesim ana köşegen).
local SLICES = {
	{ x = 0.5, y = 0, rotation = 45, first = true },
	{ x = 0.5, y = 0, rotation = 45, first = false },
	{ x = 0.5, y = 0.5, rotation = -45, first = false },
	{ x = 0.5, y = 0.5, rotation = -45, first = true },
	{ x = 0, y = 0.5, rotation = 45, first = false },
	{ x = 0, y = 0.5, rotation = 45, first = true },
	{ x = 0, y = 0, rotation = -45, first = true },
	{ x = 0, y = 0, rotation = -45, first = false },
}

local VISIBLE_FIRST = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.499, 0),
	NumberSequenceKeypoint.new(0.5, 1),
	NumberSequenceKeypoint.new(1, 1),
})
local VISIBLE_SECOND = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.499, 1),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 0),
})

local LABEL_RADIUS = 0.32 -- dilim yazılarının merkezden uzaklığı (çarkın çapına oranı; yarıçap 0.5)

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function text(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = Enum.Font.FredokaOne
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- parent: kare bir alan (GuiObject ya da SurfaceGui); alanı tamamen kaplar. prizes: Config.Wheel.Prizes (8 dilim).
-- options: rim (dış halka çizilsin mi), hub (göbek çizilsin mi), upright (yazılar çark dönerken dik mi kalsın; arayüzde true, 3B çarkta false).
-- Dönüş: { disc = dönen CanvasGroup, place = function(açı) çarkı (derece, saat yönü) ve yazıları yerleştirir, sliceDegrees }
function WheelFace.build(parent, prizes, options)
	options = options or {}
	assert(#prizes == SLICE_COUNT, "WheelFace: çarkta tam olarak 8 dilim olmalı")
	local sliceDegrees = 360 / SLICE_COUNT

	local totalWeight = 0
	for _, prize in prizes do
		totalWeight += prize.weight
	end

	local root = create("Frame", { Name = "WheelFace", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)

	local discScale = 1
	if options.rim then
		-- Dış halka: çarkın arkasında hafif büyük gri-mavi daire + koyu iç zemin
		discScale = 0.9
		local rim = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(146, 172, 188),
			BorderSizePixel = 0,
		}, root)
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, rim)
		create("UIStroke", { Thickness = 3, Color = Color3.fromRGB(40, 52, 70) }, rim)
	end

	-- Dönen disk: CanvasGroup daireye kırpar (yoksa Frame'e düşer: köşeler taşar ama çark yine çalışır)
	local okGroup, disc = pcall(create, "CanvasGroup", {
		Name = "Disc",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(discScale, discScale),
		BackgroundColor3 = Color3.fromRGB(40, 46, 74),
		BorderSizePixel = 0,
	}, root)
	if not okGroup then
		disc = create("Frame", {
			Name = "Disc",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(discScale, discScale),
			BackgroundColor3 = Color3.fromRGB(40, 46, 74),
			BorderSizePixel = 0,
		}, root)
	end
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, disc)

	for index, prize in prizes do
		local slice = SLICES[index]
		local triangle = create("Frame", {
			Name = `Slice{index}`,
			Position = UDim2.fromScale(slice.x, slice.y),
			Size = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = prize.color,
			BorderSizePixel = 0,
		}, disc)
		create("UIGradient", {
			Rotation = slice.rotation,
			Transparency = if slice.first then VISIBLE_FIRST else VISIBLE_SECOND,
		}, triangle)
	end

	-- Ayırıcı çizgiler: dikey, yatay ve iki köşegen (diskin kırpması dışarıyı keser)
	for _, rotation in { 0, 45, 90, 135 } do
		create("Frame", {
			Name = "Divider",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.012, 1.5),
			Rotation = rotation,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
		}, disc)
	end

	-- Yazılar: simge + ad + çıkma şansı (%). Dönen diskin üstünde ayrı katmandadır (arayüzde dik kalabilsin diye diskin çocuğu değildir)
	local labels = {}
	for index, prize in prizes do
		local holder = create("Frame", {
			Name = `Label{index}`,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.2 * discScale, 0.22 * discScale),
			BackgroundTransparency = 1,
		}, root)
		text(holder, { Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 0.46), Text = prize.icon, TextColor3 = Color3.new(1, 1, 1) }, 0)
		text(holder, { Position = UDim2.fromScale(0, 0.46), Size = UDim2.fromScale(1, 0.28), Text = prize.label, TextColor3 = Color3.new(1, 1, 1) }, 1.5)
		text(holder, {
			Position = UDim2.fromScale(0.1, 0.74),
			Size = UDim2.fromScale(0.8, 0.24),
			Text = `{math.floor(prize.weight / totalWeight * 100 + 0.5)}%`,
			TextColor3 = Color3.fromRGB(255, 240, 170),
		}, 1.5)
		labels[index] = holder
	end

	if options.hub then
		local hub = create("Frame", {
			Name = "Hub",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.12, 0.12),
			BackgroundColor3 = Color3.fromRGB(196, 206, 220),
			BorderSizePixel = 0,
		}, root)
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, hub)
		create("UIStroke", { Thickness = 4, Color = Color3.fromRGB(110, 134, 152) }, hub)
	end

	local face = { disc = disc, labels = labels, sliceDegrees = sliceDegrees }

	-- Çarkı angleDegrees (saat yönü) kadar döndürür; yazılar dilimlerle birlikte konumlanır, upright ise dik, değilse dilimin yönünde (radyal) durur
	function face.place(angleDegrees)
		disc.Rotation = angleDegrees
		for index, holder in labels do
			local sliceAngle = (index - 0.5) * sliceDegrees + angleDegrees
			local radians = math.rad(sliceAngle)
			holder.Position = UDim2.fromScale(0.5 + math.sin(radians) * LABEL_RADIUS * discScale, 0.5 - math.cos(radians) * LABEL_RADIUS * discScale)
			holder.Rotation = if options.upright then 0 else sliceAngle
		end
	end
	-- 3B çarkta yazılar diskle birlikte fiziksel olarak döner: bir kez radyal yerleştirilir (angle 0, upright = false)
	face.place(0)
	return face
end

return WheelFace
