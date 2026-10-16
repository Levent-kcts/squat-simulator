-- Settings penceresi: ses efektleri, müzik, kazanç yazıları, ekran sarsıntısı ve isim etiketlerini açıp kapatır (Config.Settings listesi).
-- Ayarlar PlayerSettings üzerinden uygulanır ve kaydedilir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
local PlayerSettings = require(script.Parent.PlayerSettings)

local SettingsPanel = {}

local FONT = Enum.Font.FredokaOne
local ON_COLOR = Color3.fromRGB(70, 200, 100)
local OFF_COLOR = Color3.fromRGB(110, 114, 135)

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
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- Döner: pencereyi açıp kapatan fonksiyon
function SettingsPanel.init(screenGui, openWhatsNew)
	local player = Players.LocalPlayer
	local ROW_HEIGHT, ROW_GAP = 54, 8
	local settings = Config.Settings
	local height = 68 + (#settings + 2) * (ROW_HEIGHT + ROW_GAP) + 4 -- ilk satır: promosyon kodu girişi, sonra ayarlar, son satır: Neler yeni

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(440, height),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true, -- pencereye tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	create("UISizeConstraint", { MaxSize = Vector2.new(440, height), MinSize = Vector2.new(300, height) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(110, 130, 165),
	}, panel)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, header)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	UIStyle.headerIcon(header, Config.Icons.Settings, "⚙", { Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(48, 48) })
	text(header, {
		Position = UDim2.fromOffset(68, 6),
		Size = UDim2.new(1, -150, 1, -12),
		Text = "SETTINGS",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 3)

	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(235, 40, 70),
	}, header)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, close)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })
	text(close, { Size = UDim2.fromScale(1, 1), Text = "X", TextColor3 = Color3.new(1, 1, 1) }, 2)
	close.MouseButton1Click:Connect(function()
		PanelManager.hide(panel)
	end)

	-- PROMOSYON KODU (Config.Codes; 2026-10-14 büyüme planı): kutuya yaz, REDEEM'e bas. Sonuç aynı satırda yazar (yeşil: ödül, kırmızı: hata); sunucu doğrular (PlayerStats.redeemCode)
	do
		local CODE_HINT = "Redeem code: free potions and Wins!"
		local shop = ReplicatedStorage:WaitForChild("Shop")
		local codeRow = create("Frame", {
			Name = "CodeRow",
			Position = UDim2.fromOffset(12, 68),
			Size = UDim2.new(1, -24, 0, ROW_HEIGHT),
			BackgroundColor3 = Color3.fromRGB(58, 63, 82),
		}, panel)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, codeRow)
		UIStyle.soften(codeRow, { radius = 10, strength = 0.12, shine = false })
		local status = text(codeRow, {
			Name = "CodeStatus",
			Position = UDim2.fromOffset(12, 3),
			Size = UDim2.new(1, -120, 0, 24),
			Text = CODE_HINT,
			TextColor3 = Color3.fromRGB(255, 230, 120),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, 1)
		create("UITextSizeConstraint", { MaxTextSize = 16 }, status)
		local box = create("TextBox", {
			Name = "CodeBox",
			Position = UDim2.fromOffset(12, 29),
			Size = UDim2.new(1, -120, 0, 21),
			BackgroundColor3 = Color3.fromRGB(30, 33, 46),
			TextColor3 = Color3.new(1, 1, 1),
			PlaceholderText = "Enter code",
			PlaceholderColor3 = Color3.fromRGB(140, 146, 170),
			Font = FONT,
			TextSize = 15,
			Text = "",
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, codeRow)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
		create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, box)
		local redeem = create("TextButton", {
			Name = "RedeemButton",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(84, 36),
			Text = "",
			BackgroundColor3 = ON_COLOR,
		}, codeRow)
		create("UICorner", { CornerRadius = UDim.new(0, 18) }, redeem)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, redeem)
		UIStyle.soften(redeem, { radius = 18, strength = 0.28 })
		text(redeem, { Position = UDim2.fromScale(0.08, 0.15), Size = UDim2.fromScale(0.84, 0.7), Text = "REDEEM", TextColor3 = Color3.new(1, 1, 1) }, 2)

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
				status.TextColor3 = if success then Color3.fromRGB(110, 255, 140) else Color3.fromRGB(255, 120, 120)
				if success then
					box.Text = ""
				end
				task.delay(7, function()
					if shownId == id then
						status.Text = CODE_HINT
						status.TextColor3 = Color3.fromRGB(255, 230, 120)
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
		local row = create("Frame", {
			Position = UDim2.fromOffset(12, 68 + index * (ROW_HEIGHT + ROW_GAP)),
			Size = UDim2.new(1, -24, 0, ROW_HEIGHT),
			BackgroundColor3 = Color3.fromRGB(58, 63, 82),
		}, panel)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
		UIStyle.soften(row, { radius = 10, strength = 0.12, shine = false })

		text(row, {
			Position = UDim2.fromOffset(12, 6),
			Size = UDim2.new(1, -120, 0, 26),
			Text = setting.name,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, 2)
		text(row, {
			Position = UDim2.fromOffset(12, 33),
			Size = UDim2.new(1, -120, 0, 16),
			Text = setting.detail,
			TextColor3 = Color3.fromRGB(190, 195, 215),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, 1)

		local toggle = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(84, 36),
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = ON_COLOR,
		}, row)
		create("UICorner", { CornerRadius = UDim.new(0, 18) }, toggle)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, toggle)
		UIStyle.soften(toggle, { radius = 18, strength = 0.28 })
		local toggleText = text(toggle, {
			Position = UDim2.fromScale(0.1, 0.1),
			Size = UDim2.fromScale(0.8, 0.8),
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)

		local function refresh()
			local on = PlayerSettings.get(setting.key)
			toggle.BackgroundColor3 = if on then ON_COLOR else OFF_COLOR
			toggleText.Text = if on then "ON" else "OFF"
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
		local row = create("Frame", {
			Name = "WhatsNewRow",
			Position = UDim2.fromOffset(12, 68 + (#settings + 1) * (ROW_HEIGHT + ROW_GAP)),
			Size = UDim2.new(1, -24, 0, ROW_HEIGHT),
			BackgroundColor3 = Color3.fromRGB(58, 63, 82),
		}, panel)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
		UIStyle.soften(row, { radius = 10, strength = 0.12, shine = false })
		text(row, { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -120, 0, 26), Text = "What's New", TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left }, 2)
		text(row, { Position = UDim2.fromOffset(12, 33), Size = UDim2.new(1, -120, 0, 16), Text = "See the latest updates", TextColor3 = Color3.fromRGB(190, 195, 215), TextXAlignment = Enum.TextXAlignment.Left }, 1)
		local open = create("TextButton", {
			Name = "WhatsNewButton",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(84, 36),
			Text = "",
			BackgroundColor3 = Color3.fromRGB(255, 190, 60),
		}, row)
		create("UICorner", { CornerRadius = UDim.new(0, 18) }, open)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, open)
		UIStyle.soften(open, { radius = 18, strength = 0.28 })
		text(open, { Position = UDim2.fromScale(0.1, 0.1), Size = UDim2.fromScale(0.8, 0.8), Text = "OPEN", TextColor3 = Color3.new(1, 1, 1) }, 2)
		open.MouseButton1Click:Connect(function()
			PanelManager.hide(panel)
			openWhatsNew()
		end)
	end

	return function()
		PanelManager.toggle(panel)
	end
end

return SettingsPanel
