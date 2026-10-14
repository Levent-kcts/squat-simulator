-- NELER YENİ KARTI (Config.WhatsNew; büyüme planı 1.6): geri dönen oyuncuya yeni özellikleri tek küçük kartla duyurur. Eğitimi bitirmiş oyuncuda, görmediği bir sürüm varsa girişten birkaç sn sonra BİR KEZ kendiliğinden açılır
-- ('Got it!' ya da X: sunucuya 'SeenWhatsNew' gider, o sürüm görülmüş sayılır). Settings > 'What's New' ile her zaman yeniden açılır. Karartma YOK, küçük, ortada; çevrimdışı kazanç penceresi açıksa o kapanana kadar bekler.
-- Döner: kartı açan fonksiyon.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)

local WhatsNewCard = {}

local SHOW_DELAY = 4 -- girişten sonra (sn)
local Theme = UIStyle.Theme

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

function WhatsNewCard.init(screenGui)
	local player = Players.LocalPlayer
	local settings = Config.WhatsNew
	if not settings or not settings.Lines or #settings.Lines == 0 then
		return nil
	end
	local shop = ReplicatedStorage:WaitForChild("Shop")

	-- Ölçüler: 60 başlık, satır başına 40 (+6 aralık), altta düğme + boşluklar
	local ROW_HEIGHT, ROW_GAP, HEADER, FOOTER = 40, 6, 60, 76
	local height = HEADER + 12 + #settings.Lines * (ROW_HEIGHT + ROW_GAP) + FOOTER
	local card = UIStyle.panel(screenGui, {
		name = "WhatsNewCard",
		size = UDim2.fromOffset(380, height),
		width = 380,
		accent = "info",
		position = UDim2.fromScale(0.5, 0.46),
	})
	card.Active = true -- karta tıklamak hareket başlatmasın
	card.Visible = false
	card.ZIndex = 20

	local function markSeen()
		if (player:GetAttribute("WhatsNewSeen") or 0) < settings.Version then
			task.spawn(function()
				pcall(shop.InvokeServer, shop, "SeenWhatsNew")
			end)
		end
	end
	local function hide()
		UIStyle.fadeScaleOut(card)
		markSeen()
	end

	UIStyle.header(card, {
		title = settings.Title,
		emoji = "✨",
		accent = "info",
		chip = `v{settings.Version}`,
		onClose = hide,
	})

	for index, line in settings.Lines do
		local row = UIStyle.card(card, {
			name = `Line_{index}`,
			accent = "info",
			padding = false,
			size = UDim2.new(1, -32, 0, ROW_HEIGHT),
			position = UDim2.fromOffset(16, HEADER + 12 + (index - 1) * (ROW_HEIGHT + ROW_GAP)),
		})
		local iconChip = create("Frame", {
			Name = "IconChip",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Theme.colors.info.base,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
		}, row)
		UIStyle.round(iconChip, Theme.radius.chip)
		UIStyle.label(iconChip, {
			name = "Icon",
			text = line.icon or "•",
			role = "bold",
			size = 16,
			align = "center",
			props = { Size = UDim2.fromScale(1, 1) },
		})
		UIStyle.label(row, {
			name = "Text",
			text = line.text,
			role = "body",
			size = 14,
			props = { Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -52, 1, 0) },
		})
	end

	UIStyle.button(card, {
		name = "GotItButton",
		text = "GOT IT!",
		kind = "primary",
		size = "lg",
		width = UDim2.new(1, -32, 0, 0),
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 1, -16),
		onClick = hide,
	})

	local function show()
		UIStyle.fadeScaleIn(card)
		card.Visible = true
	end

	-- Kendiliğinden açılma: veri yüklü, eğitim bitmiş, görülmemiş sürüm var. Çevrimdışı kazanç penceresi açıksa o kapanana kadar (en çok 40 sn) beklenir.
	local scheduled = false
	local function consider()
		if scheduled or player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("TutorialDone") ~= true then
			return
		end
		if (player:GetAttribute("WhatsNewSeen") or 0) >= settings.Version then
			return
		end
		scheduled = true
		task.spawn(function()
			task.wait(SHOW_DELAY)
			for _ = 1, 40 do
				local offline = screenGui:FindFirstChild("OfflineEarnings", true)
				if not offline or not offline.Visible then
					break
				end
				task.wait(1)
			end
			if (player:GetAttribute("WhatsNewSeen") or 0) < settings.Version then
				show()
			end
		end)
	end
	player:GetAttributeChangedSignal("DataLoaded"):Connect(consider)
	player:GetAttributeChangedSignal("TutorialDone"):Connect(consider)
	player:GetAttributeChangedSignal("WhatsNewSeen"):Connect(consider)
	consider()

	return show
end

return WhatsNewCard
