-- Gifts menüsü (Playtime Rewards): oyuna girdikten belli süre sonra alınabilen 10 ödül.
-- Süre sayaçları sunucu saatine göre çalışır. Ödülü sunucu verir. "Unlock Next / Unlock All" butonları Developer Product satın alma penceresi açar (ödülleri satın alma sonrası sunucu verir).
-- Görünüm: UIStyle tasarım sistemi (Soft Dark Candy, vurgu = success/yeşil). SADECE görünüm; mantık, öznitelik ve Remote çağrıları aynı.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
local GiftState = require(script.Parent.GiftState)
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))

local GiftsPanel = {}

local Theme = UIStyle.Theme

-- Ölçüler (panel pikseli; tuttuğu yer: ızgara sabit ölçülü, balon konumu buradan hesaplanır)
local PANEL_WIDTH, PANEL_HEIGHT = 660, 508
local AREA_X, AREA_Y = 14, 72
local CELL_W, CELL_H, CELL_GAP = 120, 158, 8
local CARD_H = 112

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Yazı: UIStyle.label ile kurulur, sonra konum/ölçü yazılır
local function makeLabel(parent, opts, props)
	local label = UIStyle.label(parent, opts)
	for key, value in props or {} do
		label[key] = value
	end
	return label
end

-- Ödül türüne göre kart rengi, simgesi (emoji yedeği), yazısı ve görseli (Config.Icons yüklüyse; yoksa ''). Pet ödülünde 5. değer petin kendisidir: kartta genel pati simgesi yerine PETİN RESMİ çizilir (sahibi 'bunlar yerine pet resmi olsun' dedi)
local function describe(reward)
	if reward.kind == "muscle" then
		return Color3.fromRGB(240, 50, 140), "🦵", `+{Format.compact(reward.amount)} Muscle`, Catalog.iconImage("LegMuscle")
	elseif reward.kind == "wins" then
		return Color3.fromRGB(250, 190, 40), "🏆", `+{Format.number(reward.amount)} Wins`, Catalog.iconImage("Wins")
	elseif reward.kind == "pet" then
		local pet = Catalog.PetById[reward.pet]
		return Color3.fromRGB(170, 60, 230), "🐾", `{pet.name} Pet`, Catalog.iconImage("Pet"), pet
	end
	local potion = Catalog.PotionByKind[reward.kind]
	if potion then
		return potion.color, potion.emoji, potion.name, Catalog.iconImage(nil, potion.id)
	end
	return Color3.fromRGB(250, 160, 40), "🧪", "Potion", ""
end

-- KART BİLGİSİ (2026-10-13, sahibi 'potionların üzerine gelince veya tıklayınca ne işe yaradığı yazsın, petlere tıklayınca ne kadar çarpan verdiği yazsın' dedi): kartın üstüne gelince / dokununca çıkan balonun başlığı ve açıklaması
function GiftsPanel.rewardInfo(reward)
	if reward.kind == "muscle" then
		return `+{Format.compact(reward.amount)} Leg Muscle`, `Adds {Format.number(reward.amount)} Leg Muscle right away: more muscle means more damage and higher levels!`
	elseif reward.kind == "wins" then
		return `+{Format.number(reward.amount)} Wins`, "Wins are your money: spend them on pets, shoes, skins and more!"
	elseif reward.kind == "pet" then
		local pet = Catalog.PetById[reward.pet]
		return `{pet.name} Pet`, `{Format.petBonus(pet.mult)} Pet Multiplier when equipped. Equip up to {Config.MaxEquippedPets} pets: their bonuses add up!`
	end
	local potion = Catalog.PotionByKind[reward.kind]
	if potion then
		local minutes = potion.fixedMinutes or reward.minutes or Config.BoostMinutes
		return `{potion.name} ({minutes} min)`, `{potion.effect}: {potion.description} It goes to Shop > Potions: press USE to drink it.`
	end
	return "Reward", ""
end

-- m:ss
local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- showToast(ok, mesaj). onClaimable(adet): alınabilir ödül sayısı değişince (rozet için).
-- Dönüş: paneli açıp kapatan fonksiyon.
function GiftsPanel.init(screenGui, showToast, onClaimable)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local claimed = GiftState.claimed -- bu oturumda alınan ödüller (lobideki sandık ve sağdaki kutuyla ortak; sunucu zaten kontrol eder)
	local unlocked = GiftState.unlocked -- Robux 'Unlock' ile açılan, alınmayı bekleyen ödüller (süre beklemeden 'Claim' olur; oyuncu kendisi alır)
	local total = #Config.GiftRewards

	local panel = UIStyle.panel(screenGui, {
		name = "GiftsPanel",
		size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT),
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		accent = "success",
	})
	panel.Visible = false
	panel.Active = true -- panele tıklamak hareket başlatmasın

	UIStyle.header(panel, {
		title = "Playtime Rewards",
		subtitle = "All claimed = rewards restart",
		icon = Config.Icons.Gifts,
		emoji = "🎁",
		accent = "success",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})

	-- 5 sütun x 2 satır: her hücrede kart (sayaç, simge, ad) + altında durum düğmesi
	local area = create("Frame", {
		Name = "RewardGrid",
		Position = UDim2.fromOffset(AREA_X, AREA_Y),
		Size = UDim2.fromOffset(5 * CELL_W + 4 * CELL_GAP, 2 * CELL_H + CELL_GAP),
		BackgroundTransparency = 1,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(CELL_W, CELL_H),
		CellPadding = UDim2.fromOffset(CELL_GAP, CELL_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, area)

	-- A5 (playtest: 'ödüller bitince başa sarıyor gibi'): bu BİLİNÇLİ; oyuncuya açıkça yazılır
	local noteY = AREA_Y + 2 * CELL_H + CELL_GAP + 8
	makeLabel(panel, {
		name = "RestartNote",
		text = "Claim all 10 rewards and the list starts over from the beginning!",
		role = "caption",
		align = "center",
		color = Theme.colors.textDim,
	}, { Position = UDim2.fromOffset(16, noteY), Size = UDim2.new(1, -32, 0, 18) })

	-- Bilgi balonu: kartın üstüne gelince (ya da dokununca) ne işe yaradığı yazar; balona dokunmak kapatır. İlk satırdaki kartlarda kartın altında, ikinci satırdakilerde üstünde çıkar
	local TIP_WIDTH, TIP_HEIGHT = 340, 104
	local tip = create("TextButton", {
		Name = "RewardTip",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(TIP_WIDTH, TIP_HEIGHT),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.colors.panelHigh,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
	}, panel)
	UIStyle.round(tip, Theme.radius.card)
	create("UIStroke", {
		Thickness = 1.5,
		Color = Theme.colors.success.base,
		Transparency = 0.3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, tip)
	local tipTitle = makeLabel(tip, { name = "TipTitle", text = "", role = "bold", size = 17, color = Theme.colors.primary.base }, {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 24),
		ZIndex = 31,
	})
	local tipBody = makeLabel(tip, { name = "TipBody", text = "", role = "body", size = 14, wrap = true, color = Theme.colors.text }, {
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -28, 0, 60),
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 31,
	})
	local tipIndex = nil
	local function hideTip()
		tipIndex = nil
		tip.Visible = false
	end
	local function showTip(index)
		local title, body = GiftsPanel.rewardInfo(Config.GiftRewards[index])
		tipTitle.Text = title
		tipBody.Text = body
		local column = (index - 1) % 5
		local row = (index - 1) // 5
		local cellX = AREA_X + column * (CELL_W + CELL_GAP)
		local cellY = AREA_Y + row * (CELL_H + CELL_GAP)
		tip.Position = UDim2.fromOffset(
			math.clamp(cellX + CELL_W / 2, 10 + TIP_WIDTH / 2, PANEL_WIDTH - 10 - TIP_WIDTH / 2),
			if row == 0 then cellY + CARD_H + 2 else cellY - TIP_HEIGHT - 6
		)
		tipIndex = index
		tip.Visible = true
	end
	tip.MouseButton1Click:Connect(hideTip)

	-- Hazır ödül düğmesi nabzı (yeşil, ortadan büyür; hafif modda yok)
	local function setPulse(cell, on)
		if on == cell.pulsing then
			return
		end
		cell.pulsing = on
		pcall(function()
			if cell.pulseTween then
				cell.pulseTween:Cancel()
				cell.pulseTween = nil
			end
			cell.pulseScale.Scale = 1
			if on and not UIStyle.isLow() then
				cell.pulseTween = TweenService:Create(cell.pulseScale, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.07 })
				cell.pulseTween:Play()
			end
		end)
	end

	local cells = {} -- [index] = { button, card, timer, icon, pulseScale, state }
	for index, reward in Config.GiftRewards do
		local color, icon, text, image, rewardPet = describe(reward)

		local cell = create("Frame", { Name = "Cell_" .. index, LayoutOrder = index, BackgroundTransparency = 1 }, area)
		local card = UIStyle.card(cell, { name = "Card_" .. index, size = UDim2.new(1, 0, 0, CARD_H), padding = false, accent = "success" })

		-- Üst: sayaç ya da durum
		local timer = makeLabel(card, { name = "Timer", text = "", role = "bold", size = 14, align = "center" }, {
			Position = UDim2.fromOffset(0, 6),
			Size = UDim2.new(1, 0, 0, 18),
		})

		-- Orta: ödül ikonu, ödül renginde yumuşak bir yuvanın üstünde
		local well = create("Frame", {
			Name = "IconWell",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 26),
			Size = UDim2.fromOffset(56, 56),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.78,
			BorderSizePixel = 0,
		}, card)
		UIStyle.round(well, UDim.new(1, 0))
		local iconImage = nil
		if rewardPet then
			-- Pet ödülü: petin kendi resmi (Blender modeli varsa 3B, yoksa sevimli yüz; UIStyle.safePetIcon)
			UIStyle.safePetIcon(card, rewardPet, {
				Name = "RewardPet",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0, 54),
				Size = UDim2.fromOffset(54, 54),
			})
		elseif image ~= "" then
			iconImage = create("ImageLabel", {
				Name = "RewardIcon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0, 54),
				Size = UDim2.fromOffset(50, 50),
				BackgroundTransparency = 1,
				Image = image,
				ScaleType = Enum.ScaleType.Fit,
			}, card)
		else
			makeLabel(card, { name = "RewardEmoji", text = icon, role = "title", size = 30, align = "center" }, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0, 54),
				Size = UDim2.fromOffset(56, 40),
			})
		end

		-- Alt: kısa ödül adı (sığmazsa küçülür)
		local nameLabel = makeLabel(card, { name = "RewardName", text = text, role = "bold", size = 14, align = "center" }, {
			Position = UDim2.fromOffset(4, 88),
			Size = UDim2.new(1, -8, 0, 20),
			TextScaled = true,
		})
		create("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 9 }, nameLabel)

		-- Karta gelince/dokununca bilgi balonu (şeffaf düğme kartın üstünü kaplar; durum düğmesi kartın altındadır, karışmaz)
		local info = create("TextButton", {
			Name = "Info_" .. index,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 10,
		}, card)
		info.MouseEnter:Connect(function()
			showTip(index)
		end)
		info.MouseLeave:Connect(function()
			if tipIndex == index then
				hideTip()
			end
		end)
		info.MouseButton1Click:Connect(function()
			showTip(index)
		end)

		-- Durum düğmesi: kilitli (devre dışı) / CLAIM (yeşil, nabız) / alındı (ikincil tik)
		local status = UIStyle.button(cell, {
			name = "Status_" .. index,
			text = "",
			kind = "success",
			size = "sm",
			width = CELL_W,
			position = UDim2.fromOffset(0, CARD_H + 8),
		})
		local pulseScale = create("UIScale", { Name = "PulseScale" }, status)
		cells[index] = { button = status, card = card, timer = timer, icon = iconImage, well = well, pulseScale = pulseScale, state = "", pulsing = false }

		status.MouseButton1Click:Connect(function()
			local elapsed = Workspace:GetServerTimeNow() - (player:GetAttribute("SessionStart") or 0)
			if claimed[index] or (elapsed < reward.time and not unlocked[index]) then
				return
			end
			task.spawn(function()
				-- Son ödülü almak turu baştan başlatır (sunucu ClaimedGifts'i boşaltır): cevap yeni tur bildiriminden SONRA gelirse eski turun 'Claimed'ını yeni tura işaretleme
				local cycle = player:GetAttribute("GiftCycle") or 0
				local ok, message = shopFunction:InvokeServer("ClaimGift", index)
				if ok and (player:GetAttribute("GiftCycle") or 0) == cycle then
					claimed[index] = true
				end
				showToast(ok, message or "")
			end)
		end)
	end

	-- Alt çubuk: genel ilerleme + Robux ile kilit açma
	local barY = PANEL_HEIGHT - 16 - 52
	makeLabel(panel, { name = "ProgressCaption", text = "PROGRESS", role = "caption", size = 11 }, {
		Position = UDim2.fromOffset(16, barY + 2),
		Size = UDim2.fromOffset(120, 14),
	})
	local progress = UIStyle.progressBar(panel, { name = "GiftProgress", accent = "success", value = 0, text = `0/{total}` })
	if progress and progress.frame then
		progress.frame.Position = UDim2.fromOffset(16, barY + 22)
		progress.frame.Size = UDim2.fromOffset(240, 22)
	end

	-- Alt butonlar: Robux ile kilit açma (Developer Product; ödülü sunucu verir: server/Purchases > PlayerStats unlockGifts)
	-- productId 0 ise fiyatlı 'coming soon'. Kilitli (süresi dolmamış, alınmamış) ödül yokken satın alma penceresi AÇILMAZ (Robux boşa gitmesin)
	-- Düğme yazıları düğmenin DOĞRUDAN çocuğudur (testler düğmeyi başlık yazısından bulur).
	local function robuxButton(slot, primary, title, price, productId)
		local width, height = 150, 52
		local button = create("TextButton", {
			Name = "Unlock_" .. slot,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -(16 + width / 2 + (if slot == "All" then 0 else width + 12)), 0, barY + height / 2),
			Size = UDim2.fromOffset(width, height),
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			BackgroundColor3 = if primary then Theme.colors.primary.base else Theme.colors.card,
		}, panel)
		UIStyle.round(button, Theme.radius.button)
		create("UIStroke", {
			Thickness = 1,
			Color = Theme.stroke.color,
			Transparency = if primary then 1 else Theme.stroke.transparency,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, button)
		local titleColor = if primary then Theme.colors.primary.text else Theme.colors.text
		local priceColor = if primary then Theme.colors.primary.text else Theme.colors.primary.base
		makeLabel(button, { name = "Title", text = title, role = "bold", size = 15, align = "center", color = titleColor }, {
			Position = UDim2.fromOffset(4, 6),
			Size = UDim2.new(1, -8, 0, 20),
			ZIndex = 2,
		})
		makeLabel(button, { name = "Price", text = `R$ {price}`, role = "title", size = 14, align = "center", color = priceColor }, {
			Position = UDim2.fromOffset(4, 27),
			Size = UDim2.new(1, -8, 0, 18),
			ZIndex = 2,
		})
		UIStyle.press(button, { anchor = false })
		button.MouseButton1Click:Connect(function()
			local elapsed = Workspace:GetServerTimeNow() - (player:GetAttribute("SessionStart") or Workspace:GetServerTimeNow())
			local locked, unclaimed = 0, 0
			for index, reward in Config.GiftRewards do
				if not claimed[index] then
					unclaimed += 1
					if elapsed < reward.time and not unlocked[index] then
						locked += 1
					end
				end
			end
			if locked == 0 then
				-- Satın alınacak (kilitli) ödül yok: hazır olanlar ücretsiz alınır; Robux harcatma
				showToast(false, if unclaimed > 0 then "Nothing is locked: claim your ready rewards!" else "You already claimed every reward!")
				return
			end
			if productId > 0 then
				MarketplaceService:PromptProductPurchase(player, productId)
			else
				showToast(false, `{title} (R$ {price}) is coming soon!`)
			end
		end)
	end
	robuxButton("All", true, "Unlock All", Config.GiftUnlockAllRobux, Config.GiftUnlockAllProductId)
	robuxButton("Next", false, "Unlock Next", Config.GiftUnlockNextRobux, Config.GiftUnlockNextProductId)

	-- Her saniye: sayaçları güncelle, alınabilir ödül sayısını bildir
	local lastClaimable = -1
	local function update()
		local elapsed = Workspace:GetServerTimeNow() - (player:GetAttribute("SessionStart") or Workspace:GetServerTimeNow())
		local claimable = 0
		local claimedCount = 0
		for index, reward in Config.GiftRewards do
			local cell = cells[index]
			local state
			if claimed[index] then
				state = "claimed"
				claimedCount += 1
			elseif elapsed >= reward.time or unlocked[index] then
				state = "ready"
				claimable += 1
			else
				state = "locked"
			end
			if state == "locked" then
				-- Sayaç her saniye değişir
				cell.timer.Text = "🔒 " .. formatTime(reward.time - elapsed)
			end
			if state ~= cell.state then
				cell.state = state
				if state == "claimed" then
					UIStyle.setButtonKind(cell.button, "secondary")
					UIStyle.setButtonEnabled(cell.button, false)
					UIStyle.setButtonText(cell.button, "✓")
					cell.timer.Text = "CLAIMED"
					cell.timer.TextColor3 = Theme.colors.textMute
					UIStyle.setCardSelected(cell.card, false, "success")
				elseif state == "ready" then
					UIStyle.setButtonKind(cell.button, "success")
					UIStyle.setButtonEnabled(cell.button, true)
					UIStyle.setButtonText(cell.button, "CLAIM")
					cell.timer.Text = "READY!"
					cell.timer.TextColor3 = Theme.colors.success.base
					UIStyle.setCardSelected(cell.card, true, "success")
				else
					UIStyle.setButtonKind(cell.button, "secondary")
					UIStyle.setButtonEnabled(cell.button, false)
					UIStyle.setButtonText(cell.button, "LOCKED")
					cell.timer.TextColor3 = Theme.colors.textDim
					UIStyle.setCardSelected(cell.card, false, "success")
				end
				-- Kilitli ve alınmış kartlar sönük ama okunur
				if cell.icon then
					cell.icon.ImageTransparency = if state == "ready" then 0 else 0.4
				end
				cell.well.BackgroundTransparency = if state == "ready" then 0.7 else 0.88
				setPulse(cell, state == "ready")
			end
		end
		if progress and progress.set then
			progress.set(claimedCount / total, `{claimedCount}/{total}`)
		end
		if claimable ~= lastClaimable then
			lastClaimable = claimable
			if onClaimable then
				onClaimable(claimable)
			end
		end
	end
	task.spawn(function()
		while true do
			update()
			task.wait(1)
		end
	end)

	return function()
		hideTip()
		PanelManager.toggle(panel)
		if PanelManager.isOpen(panel) then
			update()
		end
	end
end

return GiftsPanel
