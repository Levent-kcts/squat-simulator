-- Gifts menüsü (Playtime Rewards): oyuna girdikten belli süre sonra alınabilen 10 ödül.
-- Süre sayaçları sunucu saatine göre çalışır. Ödülü sunucu verir. "Unlock Next / Unlock All" butonları Developer Product satın alma penceresi açar (ödülleri satın alma sonrası sunucu verir).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
local GiftState = require(script.Parent.GiftState)
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))

local GiftsPanel = {}

local FONT = Enum.Font.FredokaOne

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Kalın siyah kenarlı yazı
local function makeText(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
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

local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

-- showToast(ok, mesaj). onClaimable(adet): alınabilir ödül sayısı değişince (rozet için).
-- Dönüş: paneli açıp kapatan fonksiyon.
function GiftsPanel.init(screenGui, showToast, onClaimable)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local claimed = GiftState.claimed -- bu oturumda alınan ödüller (lobideki sandık ve sağdaki kutuyla ortak; sunucu zaten kontrol eder)
	local unlocked = GiftState.unlocked -- Robux 'Unlock' ile açılan, alınmayı bekleyen ödüller (süre beklemeden 'Claim' olur; oyuncu kendisi alır)

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(640, 492), -- alttaki 'liste yeniden başlar' notu için biraz yüksek
		BackgroundColor3 = Color3.fromRGB(50, 52, 66),
		Active = true, -- panele tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(255, 170, 30),
	}, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	UIStyle.headerIcon(header, Config.Icons.Gifts, "🎁", { Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(48, 48) })
	makeText(header, {
		Position = UDim2.fromOffset(68, 8),
		Size = UDim2.new(0.7, -50, 1, -16),
		Text = "Playtime Rewards",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
	}, 3)
	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		Text = "X",
		Font = FONT,
		TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(235, 35, 90),
	}, header)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })

	close.MouseButton1Click:Connect(function()
		PanelManager.hide(panel)
	end)

	-- 5 sütun x 2 satır kart + her kartın altında durum butonu
	local area = create("Frame", {
		Position = UDim2.fromOffset(10, 66),
		Size = UDim2.new(1, -20, 0, 330),
		BackgroundTransparency = 1,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(116, 158),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, area)

	-- A5 (playtest: 'ödüller bitince başa sarıyor gibi'): bu BİLİNÇLİ; oyuncuya açıkça yazılır
	makeText(panel, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 400),
		Size = UDim2.new(0.94, 0, 0, 22),
		Text = "Claim all 10 rewards and the list starts over from the beginning!",
		TextColor3 = Color3.fromRGB(255, 232, 150),
	}, 2)

	-- Bilgi balonu: kartın üstüne gelince (ya da dokununca) ne işe yaradığı yazar; balona dokunmak kapatır. İlk satırdaki kartlarda kartın altında, ikinci satırdakilerde üstünde çıkar (ızgara ölçüleri sabit: hücre 116x158, aralık 8, alan (10, 66))
	local TIP_WIDTH, TIP_HEIGHT = 340, 104
	local tip = create("TextButton", {
		Name = "RewardTip",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(TIP_WIDTH, TIP_HEIGHT),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(34, 38, 60),
		Visible = false,
		ZIndex = 30,
	}, panel)
	create("UIStroke", { Thickness = 3, Color = Color3.fromRGB(255, 214, 60) }, tip)
	UIStyle.soften(tip, { radius = 12, strength = 0.2, shine = false })
	local tipTitle = makeText(tip, {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 28),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 226, 120),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 31,
	}, 2)
	local tipBody = create("TextLabel", {
		Position = UDim2.fromOffset(12, 36),
		Size = UDim2.new(1, -24, 0, 62),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextScaled = true,
		TextWrapped = true,
		Text = "",
		TextColor3 = Color3.fromRGB(235, 238, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 31,
	}, tip)
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
		local cellX = 10 + column * (116 + 8)
		local cellY = 66 + row * (158 + 8)
		tip.Position = UDim2.fromOffset(math.clamp(cellX + 58, 10 + TIP_WIDTH / 2, 630 - TIP_WIDTH / 2), if row == 0 then cellY + 112 else cellY - TIP_HEIGHT - 6)
		tipIndex = index
		tip.Visible = true
	end
	tip.MouseButton1Click:Connect(hideTip)

	local cells = {} -- [index] = { statusButton, statusLabel }
	for index, reward in Config.GiftRewards do
		local color, icon, text, image, rewardPet = describe(reward)

		local cell = create("Frame", { LayoutOrder = index, BackgroundTransparency = 1 }, area)
		local card = create("Frame", { Size = UDim2.new(1, 0, 0, 108), BackgroundColor3 = color }, cell)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, card)
		UIStyle.soften(card, { radius = 12, strength = 0.28 })
		if rewardPet then
			-- Pet ödülü: petin kendi resmi (Blender modeli varsa 3B, yoksa sevimli yüz; UIStyle.safePetIcon)
			UIStyle.safePetIcon(card, rewardPet, {
				Name = "RewardPet",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0, 38),
				Size = UDim2.fromOffset(66, 66),
			})
		elseif image ~= "" then
			create("ImageLabel", {
				Name = "RewardIcon",
				Position = UDim2.fromScale(0.15, 0.04),
				Size = UDim2.fromScale(0.7, 0.62),
				BackgroundTransparency = 1,
				Image = image,
				ScaleType = Enum.ScaleType.Fit,
			}, card)
		else
			makeText(card, { Position = UDim2.fromScale(0.15, 0.08), Size = UDim2.fromScale(0.7, 0.55), Text = icon }, 0)
		end
		makeText(card, {
			Position = UDim2.fromScale(0.04, 0.68),
			Size = UDim2.fromScale(0.92, 0.28),
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)

		-- Karta gelince/dokununca bilgi balonu (şeffaf düğme kartın üstünü kaplar; Claim düğmesi kartın altındadır, karışmaz)
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

		local status = create("TextButton", {
			Position = UDim2.fromOffset(0, 114),
			Size = UDim2.new(1, 0, 0, 38),
			Text = "",
			BackgroundColor3 = Color3.fromRGB(110, 110, 120),
		}, cell)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, status)
		UIStyle.soften(status, { radius = 10, strength = 0.28 })
		local statusLabel = makeText(status, {
			Position = UDim2.fromScale(0.05, 0.1),
			Size = UDim2.fromScale(0.9, 0.8),
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
		cells[index] = { button = status, label = statusLabel }

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

	-- Alt butonlar: Robux ile kilit açma (Developer Product; ödülü sunucu verir: server/Purchases > PlayerStats unlockGifts)
	-- productId 0 ise fiyatlı 'coming soon'. Kilitli (süresi dolmamış, alınmamış) ödül yokken satın alma penceresi AÇILMAZ (Robux boşa gitmesin)
	local function robuxButton(side, color, title, price, productId)
		local button = create("TextButton", {
			AnchorPoint = Vector2.new(if side == "right" then 1 else 0, 1),
			Position = UDim2.new(if side == "right" then 0.98 else 0.52, 0, 1, -8),
			Size = UDim2.new(0.22, 0, 0, 50),
			Text = "",
			BackgroundColor3 = color,
		}, panel)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
		UIStyle.soften(button, { radius = 10, strength = 0.28 })
		makeText(button, {
			Position = UDim2.fromScale(0.05, 0.06),
			Size = UDim2.fromScale(0.9, 0.5),
			Text = title,
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
		makeText(button, {
			Position = UDim2.fromScale(0.05, 0.56),
			Size = UDim2.fromScale(0.9, 0.38),
			Text = `R$ {price}`,
			TextColor3 = Color3.fromRGB(255, 240, 150),
		}, 2)
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
	robuxButton("left", Color3.fromRGB(190, 50, 240), "Unlock All", Config.GiftUnlockAllRobux, Config.GiftUnlockAllProductId)
	robuxButton("right", Color3.fromRGB(60, 200, 40), "Unlock Next", Config.GiftUnlockNextRobux, Config.GiftUnlockNextProductId)

	-- Her saniye: sayaçları güncelle, alınabilir ödül sayısını bildir
	local lastClaimable = -1
	local function update()
		local elapsed = Workspace:GetServerTimeNow() - (player:GetAttribute("SessionStart") or Workspace:GetServerTimeNow())
		local claimable = 0
		for index, reward in Config.GiftRewards do
			local cell = cells[index]
			if claimed[index] then
				cell.label.Text = "Claimed"
				cell.button.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
			elseif elapsed >= reward.time or unlocked[index] then
				claimable += 1
				cell.label.Text = "Claim"
				cell.button.BackgroundColor3 = Color3.fromRGB(60, 200, 40)
			else
				cell.label.Text = formatTime(reward.time - elapsed)
				cell.button.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
			end
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
