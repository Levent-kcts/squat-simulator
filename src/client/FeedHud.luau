-- Duyuru akışı (server/GlobalFeed): nadir pet ve rebirth duyuruları sağ tarafta küçük şeritler olarak görünür, ~7 sn sonra solar; en çok 3 şerit.
-- Sadece görsel. Settings > 'Server feed' kapalıysa (FeedOn = false) gösterilmez. Ekran sade kalsın: ortada büyük yazı yok, şeritler küçük ve kısa.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local FeedHud = {}

local MAX_ENTRIES = 3
local SHOW_SECONDS = 7
local ICONS = { pet = "✨", rebirth = "★", stage = "🏆" }

-- Duyurunun vurgu rengi: nadirlik adı (Config.Rarities) ya da 'rebirth'
local function accent(tier)
	for _, rarity in Config.Rarities do
		if rarity.name == tier then
			return rarity.color
		end
	end
	return Color3.fromRGB(255, 210, 60)
end

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

function FeedHud.init(screenGui)
	local player = Players.LocalPlayer
	local remote = ReplicatedStorage:WaitForChild("Feed", 30)
	if not remote then
		return
	end

	-- Sağ ortanın altı: FREE REWARD kutusunun (0.4) altında, teypin (alt) üstünde
	local holder = create("Frame", {
		Name = "FeedHud",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0.57, 0),
		Size = UDim2.fromOffset(280, 3 * 34),
		BackgroundTransparency = 1,
		Active = false,
	}, screenGui)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Top }, holder)

	local order = 0
	local entries = {}

	local function remove(entry)
		local index = table.find(entries, entry)
		if index then
			table.remove(entries, index)
		end
		entry:Destroy()
	end

	remote.OnClientEvent:Connect(function(kind, text, tier)
		if player:GetAttribute("FeedOn") == false then
			return
		end
		if type(text) ~= "string" or text == "" then
			return
		end
		order += 1
		local entry = create("Frame", {
			LayoutOrder = order,
			Size = UDim2.fromOffset(280, 30),
			BackgroundColor3 = Color3.fromRGB(24, 27, 46),
			BackgroundTransparency = 0.12,
		}, holder)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, entry)
		create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, entry)
		local bar = create("Frame", {
			Size = UDim2.new(0, 5, 1, 0),
			BackgroundColor3 = accent(tier),
			BorderSizePixel = 0,
		}, entry)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, bar)
		local label = create("TextLabel", {
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -16, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.new(1, 1, 1),
			Text = `{ICONS[kind] or "•"} {text}`,
		}, entry)
		create("UITextSizeConstraint", { MaxTextSize = 15 }, label)
		create("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0) }, label)

		table.insert(entries, entry)
		while #entries > MAX_ENTRIES do
			remove(entries[1])
		end
		task.delay(SHOW_SECONDS, function()
			if entry.Parent then
				TweenService:Create(entry, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
				task.delay(0.45, function()
					if entry.Parent then
						remove(entry)
					end
				end)
			end
		end)
	end)
end

return FeedHud
