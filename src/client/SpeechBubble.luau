-- KONUŞMA BALONU (2026-10-16, sahibi 'şimdiye kadar yapılmış bütün balonları konuşma balonuna dönüştür, anında çıkandan ziyade küçük bir animasyonu olan konuşma balonu olsun' dedi):
-- var olan bir bilgi kutusuna (Frame/TextButton, UIStroke'lu) gösterdiği şeye doğru bakan KUYRUK ekler ve açılıp kapanmayı küçük bir 'pop' animasyonuyla yapar.
-- Kuyruk: 45 derece döndürülmüş kare (kutunun dolgu rengi + aynı çerçeve), kutunun içinde kalan yarısı ve birleşme yerindeki çerçeve çizgisi aynı renkli iki örtüyle gizlenir;
-- böylece kuyruk kutuyla tek parça görünür. Kutunun UIGradient'i varsa kuyruk o kenarın rengini alır. Calm UI'da animasyon yok (anında açılır/kapanır).
-- Kullanım:
--   local bubble = SpeechBubble.decorate(frame, { side = "bottom", at = 0.5 })   -- side: kuyruğun çıktığı kenar (bottom = aşağıdaki şeyi gösterir)
--   bubble.setSide("top", 0.3)   bubble.show()   bubble.hide()
-- Açılma, kutunun AnchorPoint'inden büyür: kuyruğun olduğu kenara anchor vermek en doğal görünümü verir.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local SpeechBubble = {}

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function calm()
	local player = Players.LocalPlayer
	return player ~= nil and player:GetAttribute("CalmUI") == true
end

-- Kutunun belirli kenarındaki dolgu rengi (soften'in üstten alta UIGradient'i hesaba katılır)
local function edgeColor(frame, side)
	local color = frame.BackgroundColor3
	local gradient = frame:FindFirstChildOfClass("UIGradient")
	if gradient and gradient.Rotation == 90 then
		local keypoints = gradient.Color.Keypoints
		local tint = if side == "top" then keypoints[1].Value elseif side == "bottom" then keypoints[#keypoints].Value else keypoints[math.max(1, math.ceil(#keypoints / 2))].Value
		color = Color3.new(color.R * tint.R, color.G * tint.G, color.B * tint.B)
	end
	return color
end

function SpeechBubble.decorate(frame, opts)
	opts = opts or {}
	local size = opts.tail or 18
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	local thickness = if stroke then stroke.Thickness else 0
	local strokeColor = if stroke then stroke.Color else Color3.new(0, 0, 0)
	local baseZ = frame.ZIndex
	local half = size * math.sqrt(2) / 2 -- döndürülmüş karenin merkezden köşeye uzaklığı (kuyruğun boyu)

	local tail = create("Frame", {
		Name = "BubbleTail",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		Rotation = 45,
		BorderSizePixel = 0,
		ZIndex = math.max(1, baseZ - 1),
	}, frame)
	if thickness > 0 then
		create("UIStroke", { Thickness = thickness, Color = strokeColor }, tail)
	end
	-- Kuyruğun kutu içinde kalan yarısını örter (içerideki çapraz çizgiler görünmesin)
	local coverInside = create("Frame", { Name = "BubbleTailCover", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = baseZ }, frame)
	-- Birleşme yerinde kutunun çerçeve çizgisini örter (kuyruk kutudan kopuk görünmesin)
	local coverJoint = create("Frame", { Name = "BubbleTailJoint", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = baseZ }, frame)

	local scale = frame:FindFirstChild("BubblePop") or create("UIScale", { Name = "BubblePop", Scale = 1 }, frame)
	local api = {}
	local token = 0

	function api.setSide(side, at)
		at = math.clamp(at or 0.5, 0.05, 0.95)
		local color = edgeColor(frame, side)
		tail.BackgroundColor3 = color
		coverInside.BackgroundColor3 = color
		coverJoint.BackgroundColor3 = color
		local inside = half + 2 -- kutunun içine doğru örtü derinliği
		local jointWidth = math.max(4, 2 * (half - thickness) - thickness * 2)
		if side == "bottom" or side == "top" then
			local edgeY = if side == "bottom" then 1 else 0
			local outward = if side == "bottom" then 1 else -1
			tail.Position = UDim2.new(at, 0, edgeY, 0)
			coverInside.Size = UDim2.fromOffset(size * 1.6, inside)
			coverInside.Position = UDim2.new(at, 0, edgeY, -outward * inside / 2)
			coverJoint.Size = UDim2.fromOffset(jointWidth, thickness + 2)
			coverJoint.Position = UDim2.new(at, 0, edgeY, outward * (thickness / 2))
		else
			local edgeX = if side == "right" then 1 else 0
			local outward = if side == "right" then 1 else -1
			tail.Position = UDim2.new(edgeX, 0, at, 0)
			coverInside.Size = UDim2.fromOffset(inside, size * 1.6)
			coverInside.Position = UDim2.new(edgeX, -outward * inside / 2, at, 0)
			coverJoint.Size = UDim2.fromOffset(thickness + 2, jointWidth)
			coverJoint.Position = UDim2.new(edgeX, outward * (thickness / 2), at, 0)
		end
	end

	-- Açılış: küçük bir 'pop' (0.6 > 1, Back)
	function api.show()
		token += 1
		local wasVisible = frame.Visible
		frame.Visible = true
		if wasVisible and scale.Scale > 0.95 then
			return
		end
		if calm() then
			scale.Scale = 1
			return
		end
		scale.Scale = 0.6
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end

	-- Kapanış anında (fare başka yere geçince eski balon oyalanmasın; sadece açılış animasyonludur)
	function api.hide()
		token += 1
		frame.Visible = false
		scale.Scale = 1
	end

	function api.isShown()
		return frame.Visible
	end

	api.setSide(opts.side or "bottom", opts.at)
	return api
end

return SpeechBubble
