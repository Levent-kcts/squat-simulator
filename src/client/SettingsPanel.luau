-- Settings penceresi: ses efektleri, müzik, kazanç yazıları, ekran sarsıntısı ve isim etiketlerini açıp kapatır (Config.Settings listesi).
-- Ayarlar PlayerSettings üzerinden uygulanır ve kaydedilir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
local PlayerSettings = require(script.Parent.PlayerSettings)

local SettingsPanel = {}

local Theme = UIStyle.Theme
local PAD = 16 -- içerik kenar payı

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Modern anahtar: hap 52x28, içinde daire düğme; açık = success, kapalı = cardDeep (0.15 sn tween). Döner: düğme, setOn(on, animate)
local KNOB_OFF, KNOB_ON = UDim2.new(0, 3, 0.5, 0), UDim2.new(1, -25, 0.5, 0)
local SWITCH_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function makeSwitch(parent, name)
	local toggle = create("TextButton", {
		Name = name,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(52, 28),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.colors.cardDeep,
		BorderSizePixel = 0,
	}, parent)
	UIStyle.round(toggle, UDim.new(1, 0))
	create("UIStroke", { Thickness = 1, Color = Theme.stroke.color, Transparency = Theme.stroke.transparency, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, toggle)
	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = KNOB_OFF,
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Theme.colors.text,
		BorderSizePixel = 0,
	}, toggle)
	UIStyle.round(knob, UDim.new(1, 0))
	local function setOn(on, animate)
		local color = if on then Theme.colors.success.base else Theme.colors.cardDeep
		local position = if on then KNOB_ON else KNOB_OFF
		toggle:SetAttribute("On", on and true or false)
		if animate and not UIStyle.isLow() then
			pcall(function()
				TweenService:Create(toggle, SWITCH_TWEEN, { BackgroundColor3 = color }):Play()
				TweenService:Create(knob, SWITCH_TWEEN, { Position = position }):Play()
			end)
		else
			toggle.BackgroundColor3 = color
			knob.Position = position
		end
	end
	return toggle, setOn
end

-- Ad (kalın) + küçük açıklama (soluk) olan ayar satırı kartı; sağ tarafa kontrol konur ('Control' tutucusu)
local function makeRow(parent, order, name, detail)
	local row = UIStyle.card(parent, { name = "SettingRow", size = UDim2.new(1, 0, 0, 64), padding = false, props = { LayoutOrder = order } })
	UIStyle.label(row, { name = "RowName", text = name, role = "bold", props = { Position = UDim2.fromOffset(PAD, 8), Size = UDim2.new(1, -(PAD * 2 + 64), 0, 20) } })
	UIStyle.label(row, { name = "RowDetail", text = detail, role = "caption", wrap = true, props = { Position = UDim2.fromOffset(PAD, 28), Size = UDim2.new(1, -(PAD * 2 + 64), 0, 30), TextYAlignment = Enum.TextYAlignment.Top } })
	local control = create("Frame", {
		Name = "Control",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -PAD, 0.5, 0),
		Size = UDim2.fromOffset(52, 28),
		BackgroundTransparency = 1,
	}, row)
	return row, control
end

-- Döner: pencereyi açıp kapatan fonksiyon
function SettingsPanel.init(screenGui, openWhatsNew)
	local player = Players.LocalPlayer
	local settings = Config.Settings
	-- Yükseklik satır sayısına bağlı: 60 başlık + 104 kod kartı + ayarlar (64 + 8) + Neler yeni; ekranı aşarsa içerik kayar
	local rowCount = #settings + (if openWhatsNew then 1 else 0)
	local contentHeight = 12 + 104 + 8 + rowCount * 72 + PAD
	local height = math.min(60 + contentHeight, 560)

	local panel = UIStyle.panel(screenGui, {
		name = "SettingsPanel",
		width = 440,
		height = height,
		accent = "info",
		position = UDim2.fromScale(0.5, 0.48),
		anchor = Vector2.new(0.5, 0.5),
	})
	panel.Visible = false

	UIStyle.header(panel, {
		title = "Settings",
		icon = Config.Icons.Settings,
		emoji = "⚙",
		accent = "info",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})

	local list = create("ScrollingFrame", {
		Name = "SettingsList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 1, -60),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, panel)
	create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, PAD), PaddingLeft = UDim.new(0, PAD), PaddingRight = UDim.new(0, PAD) }, list)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	-- PROMOSYON KODU (Config.Codes; 2026-10-14 büyüme planı): kutuya yaz, REDEEM'e bas. Sonuç girdinin ALTINDA küçük yazar (yeşil: ödül, kırmızı: hata); sunucu doğrular (PlayerStats.redeemCode)
	do
		local CODE_HINT = "Redeem code: free potions and Wins!"
		local HINT_COLOR = Theme.colors.textDim
		local shop = ReplicatedStorage:WaitForChild("Shop")
		local codeRow = UIStyle.card(list, { name = "CodeRow", size = UDim2.new(1, 0, 0, 104), padding = false, accent = "info", props = { LayoutOrder = 0 } })
		UIStyle.label(codeRow, { name = "CodeTitle", text = "Redeem code", role = "bold", props = { Position = UDim2.fromOffset(PAD, 8), Size = UDim2.new(1, -(PAD * 2), 0, 20) } })
		local box = UIStyle.input(codeRow, {
			placeholder = "Enter code",
			accent = "info",
			props = { Position = UDim2.fromOffset(PAD, 34), Size = UDim2.new(1, -(PAD * 2 + 108), 0, 44) },
		})
		box.Name = "CodeBox"
		box.Font = Theme.fonts.bold
		box.TextSize = 18
		local redeem = UIStyle.button(codeRow, {
			name = "RedeemButton",
			text = "REDEEM",
			kind = "primary",
			size = "md",
			width = 100,
			anchor = Vector2.new(1, 0),
			position = UDim2.new(1, -PAD, 0, 34),
		})
		local status = UIStyle.label(codeRow, {
			name = "CodeStatus",
			text = CODE_HINT,
			role = "caption",
			props = { Position = UDim2.fromOffset(PAD, 82), Size = UDim2.new(1, -(PAD * 2), 0, 16) },
		})

		local busy = false
		local shownId = 0
		local function submit()
			local typed = box.Text
			if busy or typed == "" then
				return
			end
			busy = true
			task.spawn(function()
				local callOk, success, message = pcall(shop.InvokeServer, shop, "RedeemCode", typed)
				busy = false
				shownId += 1
				local id = shownId
				if not callOk then
					success, message = false, "Could not redeem the code. Try again."
				end
				status.Text = message or ""
				status.TextColor3 = if success then Theme.colors.success.base else Theme.colors.danger.base
				if success then
					box.Text = ""
				end
				task.delay(7, function()
					if shownId == id then
						status.Text = CODE_HINT
						status.TextColor3 = HINT_COLOR
					end
				end)
			end)
		end
		redeem.MouseButton1Click:Connect(submit)
		box.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				submit()
			end
		end)
	end

	for index, setting in settings do
		local _, control = makeRow(list, index, setting.name, setting.detail)
		local toggle, setOn = makeSwitch(control, "Toggle_" .. setting.key)
		toggle.Position = UDim2.new(1, 0, 0.5, 0)

		local first = true
		local function refresh()
			setOn(PlayerSettings.get(setting.key) and true or false, not first)
			first = false
		end
		toggle.MouseButton1Click:Connect(function()
			PlayerSettings.set(setting.key, not PlayerSettings.get(setting.key))
			refresh()
		end)
		-- Ayar başka yerden (teyp, sunucudan yüklenen kayıt) değişirse düğme de güncellensin
		player:GetAttributeChangedSignal(setting.key):Connect(refresh)
		refresh()
	end

	-- NELER YENİ satırı (son satır): kartı her zaman yeniden açar (Config.WhatsNew)
	if openWhatsNew then
		local row, control = makeRow(list, #settings + 1, "What's new", "See the latest updates")
		row.Name = "WhatsNewRow"
		control:Destroy()
		UIStyle.button(row, {
			name = "WhatsNewButton",
			text = "OPEN",
			kind = "secondary",
			size = "sm",
			width = 76,
			anchor = Vector2.new(1, 0.5),
			position = UDim2.new(1, -PAD, 0.5, 0),
			onClick = function()
				PanelManager.hide(panel)
				openWhatsNew()
			end,
		})
	end

	return function()
		PanelManager.toggle(panel)
	end
end

return SettingsPanel
