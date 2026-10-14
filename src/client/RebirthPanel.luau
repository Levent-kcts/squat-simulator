-- Rebirth onay ekranı: önce/sonra çarpanı, önce/sonra en yüksek level, uyarı, level çubuğu ve iki buton:
-- "Rebirth" (level sınırına gelince çalışır) ve "SKIP?" (Robux ile level şartını atlama, şimdilik yer tutucu).
-- Görünüm: UIStyle tasarım sistemi (Soft Dark Candy), vurgu rengi hot (pembe). Mantık/Remote değişmedi.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
local Progression = require(Shared:WaitForChild("Progression"))
local Format = require(Shared:WaitForChild("Format"))

local RebirthPanel = {}

local Theme = UIStyle.Theme

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- showToast(ok, mesaj): kısa bildirim gösterir. Dönüş: paneli açan fonksiyon.
function RebirthPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local leaderstats = player:WaitForChild("leaderstats")
	local levelValue = leaderstats:WaitForChild(Config.StatLevel)
	local rebirthValue = leaderstats:WaitForChild(Config.StatRebirths)

	-- Pencere gövdesi (PanelManager soldan kaydırır; gölge konumu izler)
	local panel = UIStyle.panel(screenGui, {
		name = "RebirthPanel",
		size = UDim2.fromOffset(460, 424),
		accent = "hot",
		position = UDim2.fromScale(0.5, 0.45),
		anchor = Vector2.new(0.5, 0.5),
		width = 460,
	})
	panel.Visible = false

	UIStyle.header(panel, {
		title = "Rebirth",
		icon = Config.Icons.Rebirth,
		emoji = "🔄",
		accent = "hot",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})

	-- Şimdi / Sonra kutuları: iki büyük çarpan, ortada ok
	local function multiplierBox(side, caption, highlight)
		local box = UIStyle.card(panel, {
			name = if side == "left" then "NowBox" else "NextBox",
			size = UDim2.fromOffset(180, 92),
			position = UDim2.fromOffset(if side == "left" then 16 else 264, 76),
			accent = "hot",
			selected = highlight,
			padding = false,
		})
		UIStyle.label(box, { text = caption, role = "caption", align = "center", props = { Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 16) } })
		local value = UIStyle.label(box, {
			text = "x1",
			role = "number",
			size = 40,
			align = "center",
			color = if highlight then Theme.colors.hot.base else Theme.colors.text,
			props = { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 52) },
		})
		return value, box
	end
	local beforeMultiplier = multiplierBox("left", "NOW", false)
	local afterMultiplier, nextBox = multiplierBox("right", "NEXT", true)
	UIStyle.label(panel, {
		text = ">",
		role = "number",
		size = 28,
		align = "center",
		color = Theme.colors.textDim,
		props = { Position = UDim2.fromOffset(196, 98), Size = UDim2.fromOffset(68, 48) },
	})

	-- Max level satırı
	local maxLabel = UIStyle.label(panel, {
		text = "Max level",
		role = "bold",
		align = "center",
		color = Theme.colors.textDim,
		props = { Position = UDim2.fromOffset(16, 178), Size = UDim2.new(1, -32, 0, 22) },
	})

	-- Level çubuğu
	local levelBar = UIStyle.progressBar(panel, {
		name = "LevelBar",
		accent = "hot",
		props = { Position = UDim2.fromOffset(16, 208), Size = UDim2.new(1, -32, 0, 24) },
	})

	-- Uyarı: tek ince warn şeritli kart
	local warnCard = UIStyle.card(panel, {
		name = "WarnCard",
		size = UDim2.new(1, -32, 0, 52),
		position = UDim2.fromOffset(16, 244),
		accent = "warn",
		padding = false,
		props = { ClipsDescendants = true },
	})
	create("Frame", { Name = "WarnStripe", Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Theme.colors.warn.base, BorderSizePixel = 0 }, warnCard)
	UIStyle.label(warnCard, {
		text = "Resets your level & leg muscle. You KEEP Wins, shoes, skins & pets!",
		role = "body",
		color = Theme.colors.text,
		props = { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -28, 1, 0), TextWrapped = true },
	})

	-- Butonlar: büyük Rebirth (hot) + yanda küçük SKIP (secondary). Konum merkezdir (düğmeler anchorCenter)
	local rebirthButton = UIStyle.button(panel, {
		name = "RebirthButton",
		text = "Rebirth",
		kind = "hot",
		size = "lg",
		width = 250,
		position = UDim2.fromOffset(16 + 125, 332),
	})
	local skipButton = UIStyle.button(panel, {
		name = "SkipButton",
		text = `SKIP  {utf8.char(0xE002)} {Config.Rebirth.SkipRobuxPrice}`,
		kind = "secondary",
		size = "md",
		width = 150,
		position = UDim2.fromOffset(444 - 75, 332),
	})
	local hintLabel = UIStyle.label(panel, {
		text = "",
		role = "caption",
		align = "center",
		props = { Position = UDim2.fromOffset(16, 372), Size = UDim2.new(1, -32, 0, 16) },
	})
	UIStyle.label(panel, {
		text = "SKIP? Jump the level requirement with Robux.",
		role = "caption",
		align = "center",
		color = Theme.colors.textMute,
		props = { Position = UDim2.fromOffset(16, 392), Size = UDim2.new(1, -32, 0, 16) },
	})

	-- Hazırken Rebirth düğmesi nabız atar (düğme ortadan ölçeklenir; hafif modda yok)
	local pulseTween = nil
	local pulseScale = create("UIScale", { Name = "PulseScale" }, rebirthButton)
	local function setPulse(on)
		if on and not UIStyle.isLow() then
			if not pulseTween then
				pcall(function()
					pulseTween = UIStyle.loopTween(TweenService:Create(pulseScale, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.04 }), pulseScale, { Scale = 1 })
					pulseTween:Play()
				end)
			end
		elseif pulseTween then
			pcall(function()
				pulseTween:Cancel()
			end)
			pulseTween = nil
			pulseScale.Scale = 1
		end
	end

	local function currentState()
		local rebirths = rebirthValue.Value
		return rebirths, levelValue.Value, Progression.maxLevel(rebirths)
	end

	local lastNext = nil
	local function render()
		local rebirths, level, maxLevel = currentState()
		beforeMultiplier.Text = `x{Format.multiplier(Progression.rebirthMultiplier(rebirths))}`
		local nextText = `x{Format.multiplier(Progression.rebirthMultiplier(rebirths + 1))}`
		afterMultiplier.Text = nextText
		if lastNext ~= nextText then
			lastNext = nextText
			UIStyle.pop(nextBox)
		end
		maxLabel.Text = `Max level {maxLevel}  >  {Progression.maxLevel(rebirths + 1)}`
		levelBar.set(math.clamp(level / maxLevel, 0, 1), `Level {level}/{maxLevel}`)

		local ready = level >= maxLevel
		UIStyle.setButtonEnabled(rebirthButton, ready)
		hintLabel.Text = if ready then "Ready! Your multiplier goes up." else `Reach level {maxLevel} to rebirth ({maxLevel - level} to go)`
		setPulse(ready)
	end

	rebirthButton.MouseButton1Click:Connect(function()
		local _, level, maxLevel = currentState()
		if level < maxLevel then
			showToast(false, `Reach level {maxLevel} to rebirth!`)
			return
		end
		task.spawn(function()
			local ok, message = shopFunction:InvokeServer("Rebirth")
			showToast(ok, message or "")
			if ok then
				PanelManager.hide(panel)
			end
			render()
		end)
	end)

	skipButton.MouseButton1Click:Connect(function()
		-- Gerçek satış için Developer Product oluşturulup Config.Rebirth.SkipProductId'ye yazılmalı
		if Config.Rebirth.SkipProductId > 0 then
			-- Satın alma penceresi açılır; rebirth'i sunucu ProcessReceipt ile yapar (server/Purchases)
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, Config.Rebirth.SkipProductId)
		else
			showToast(false, "Skipping with Robux is coming soon!")
		end
	end)

	local function onChange()
		if PanelManager.isOpen(panel) then
			render()
		end
	end
	levelValue:GetPropertyChangedSignal("Value"):Connect(onChange)
	rebirthValue:GetPropertyChangedSignal("Value"):Connect(onChange)

	-- Paneli açar (kapalıysa), açıksa kapatır
	return function()
		PanelManager.toggle(panel)
		if PanelManager.isOpen(panel) then
			render()
		end
	end
end

return RebirthPanel
