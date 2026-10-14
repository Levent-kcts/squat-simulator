-- Yumurta raflarının oyuncuya özel görünümü: etiketler, ped renkleri ve pede basınca (dokununca) açılan yumurta paneli.
-- Panelde yumurtanın adı, fiyatı, petleri, çarpanları ve çıkma şansları görünür.
-- Tuşlar: E = aç (ücretsiz), R = otomatik aç (ücretli: Auto Open), T = bir seferde açılacak sayı (1 / 3 / 10; x3 ve x10 modları ücretli: Multi Open).
-- Ücretli özellikler panelde NORMAL görünür, fiyat YAZMAZ (sahibi 'fiyatları R'ye T'ye basmadan göremeyelim, biraz clickbait olsun, Shop'ta da olmasın' dedi): fiyat ancak oyuncu R'ye ya da T'nin kilitli bir çarpana gelmesine basınca
-- görünür: pass satışa açıksa Roblox satın alma penceresi, değilse 'coming soon' bildirimi fiyatla birlikte. Kilitli çarpan SEÇİLMEZ (sahibi 'satın almadan o düğme çalışmasın' dedi): başlıktaki toplam fiyat ve Multi yazısı değişmez. Win yetmiyorsa Open düğmesi 'Get Wins' olur ve Shop'un paket bölümünü açar.
-- Burada yapılan renk/etiket değişiklikleri sadece bu oyuncunun ekranında görünür.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))
local EggRules = require(Shared:WaitForChild("EggRules"))
local UIStyle = require(script.Parent.UIStyle)
local MarketplaceService = game:GetService("MarketplaceService")

local EggShop = {}

-- Açılış ekranı korumalı yüklenir: hata verirse yumurta açma yine çalışır (sadece sonuç ekranı görünmez)
local okReveal, Reveal = pcall(require, script.Parent.Reveal)
local okScaler, LabelScaler = pcall(require, script.Parent.LabelScaler) -- etiketleri mesafeye göre ölçekler (uzaktakiler küçülür)

-- Ped renkleri raflarla aynı mantıkta (ShelfClient): parlak yeşil = açabilirsin, sönük lavanta gri = Win yetmiyor, gri = pet envanteri dolu
local GREEN = Color3.fromRGB(60, 255, 110)
local DIM = Color3.fromRGB(150, 157, 196)
local GRAY = Color3.fromRGB(110, 110, 120)
local DIM_TEXT = Color3.fromRGB(190, 196, 218)

-- Panel, oyuncu yumurta pedine DOKUNUNCA açılır (eskiden 10 stud yakınlıkta açılıp önü kapatıyordu). Mesafe = pedin kenarı ile karakterin
-- gövde kenarı arasındaki yatay boşluk (stud): ENTER'dan küçükse açılır, açıkken EXIT'ten uzaklaşınca kapanır (kenarda titremesin diye EXIT daha geniş).
local ENTER_GAP = 0.5
local EXIT_GAP = 3
local AUTO_INTERVAL = 1.2 -- otomatik açma aralığı (saniye)
local ROBUX = utf8.char(0xE002) -- Roblox'un Robux simgesi (yazı tipinde özel karakter, ShopPanel'deki gibi)

-- (Panel kartlarının rengi petin NADİRLİĞİ'nden gelir: Catalog.rarityOf = Config.Rarities; yumurta açılışındaki kart ve Pets menüsüyle aynı renk)

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Kalın siyah kenarlı yazı: SADECE dünyadaki yumurta etiketleri (BillboardGui, marka anı); panel UIStyle ile yapılır
local function makeText(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = Enum.Font.FredokaOne
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- Yumurtadaki sıralı havuz: en sık çıkandan nadire. luck > 1 ise (Luck Potion etkinken) yüzdeler şansa göre hesaplanır (Catalog.luckWeights, sunucuyla aynı)
local function sortedPool(egg, luck)
	local pool, total = {}, 0
	local weights = Catalog.luckWeights(egg, luck or 1)
	for _, weight in weights do
		total += weight
	end
	for index, entry in egg.pets do
		table.insert(pool, { pet = Catalog.PetById[entry.id], chance = weights[index] / total * 100, base = entry.weight })
	end
	table.sort(pool, function(a, b)
		return a.chance > b.chance
	end)
	return pool
end

-- hooks (isteğe bağlı, init.client sonradan doldurur): showToast(ok, mesaj), openShop('packs') = Shop'u Win paketleri bölümünde aç
function EggShop.init(screenGui, hooks)
	hooks = hooks or {}
	local player = Players.LocalPlayer
	local folder = Workspace:WaitForChild("EggShop")
	local winValue = player:WaitForChild("leaderstats"):WaitForChild(Config.StatWins)
	local openFunction = ReplicatedStorage:WaitForChild("EggOpen")
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")

	-- ---------- Yumurtaların üstündeki etiketler ve ped renkleri ----------
	local entries = {}
	for _, egg in Config.Eggs do
		local pad = folder:WaitForChild(`Pad_{egg.id}`)

		-- Etiketler iki ayrı küçük kutudur (eskiden tek büyük 2 satırlı kutu yan yana/üst üste yumurtaların yazılarını karıştırıyordu):
		--  * isim: yumurtanın üstünde tek satır,
		--  * fiyat: pedin hemen üstünde. Boyutlar stud cinsinden, uzaktayken küçülür; uzaktaki etiketler gizlenir (MaxDistance).
		local nameGui = create("BillboardGui", {
			Size = UDim2.fromOffset(190, 40), -- piksel boyutu, mesafeye göre LabelScaler ölçekler (QA 2026-10-15)
			StudsOffsetWorldSpace = Vector3.new(0, 8.6, 0),
			MaxDistance = 40,
			Adornee = pad,
		}, pad)
		if okScaler then
			LabelScaler.register(nameGui, 190, 40, 16)
		end
		makeText(nameGui, {
			Size = UDim2.fromScale(1, 1),
			TextColor3 = egg.color:Lerp(Color3.new(1, 1, 1), 0.35),
			Text = egg.name,
		}, 2)

		local priceGui = create("BillboardGui", {
			Size = UDim2.fromOffset(150, 30),
			StudsOffsetWorldSpace = Vector3.new(0, 2.1, 0),
			MaxDistance = 28,
			Adornee = pad,
		}, pad)
		if okScaler then
			LabelScaler.register(priceGui, 150, 30, 14)
		end
		local price = makeText(priceGui, {
			Size = UDim2.fromScale(1, 1),
			TextColor3 = Color3.new(1, 1, 1),
			Text = `{Format.number(egg.price)} Wins`,
		}, 2)

		table.insert(entries, { egg = egg, pad = pad, price = price })
	end

	local function petCount()
		local count = 0
		for _ in string.gmatch(player:GetAttribute("OwnedPets") or "", "[^,]+") do
			count += 1
		end
		return count
	end

	local function refreshPads()
		local full = petCount() >= (player:GetAttribute("PetCapacity") or Config.MaxOwnedPets)
		local wins = winValue.Value
		for _, entry in entries do
			local pad, price = entry.pad, entry.price
			if full then
				pad.Color, pad.Material = GRAY, Enum.Material.SmoothPlastic
				price.Text, price.TextColor3 = "Inventory full", DIM_TEXT
			else
				price.Text = `{Format.number(entry.egg.price)} Wins`
				if entry.egg.price <= wins then
					pad.Color, pad.Material = GREEN, Enum.Material.Neon
					price.TextColor3 = GREEN
				else
					pad.Color, pad.Material = DIM, Enum.Material.SmoothPlastic
					price.TextColor3 = DIM_TEXT
				end
			end
		end
	end
	winValue:GetPropertyChangedSignal("Value"):Connect(refreshPads)
	player:GetAttributeChangedSignal("OwnedPets"):Connect(refreshPads)
	player:GetAttributeChangedSignal("PetCapacity"):Connect(refreshPads)
	refreshPads()

	-- ---------- Yaklaşınca açılan panel ----------
	-- Modal olmayan orta boy panel (UIStyle.panel: koyu zemin, ince çerçeve, yumuşak gölge). Gölge kardeşi panelle birlikte gizlenir/gösterilir.
	local Theme = UIStyle.Theme
	local panel, panelShadow = UIStyle.panel(screenGui, {
		name = "EggPanel",
		width = 600,
		size = UDim2.fromOffset(600, 336),
		accent = "primary",
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 68), -- üst çubuğun altı
	})
	panel.Visible = false -- Active = true (UIStyle.panel): panele tıklamak hareket başlatmasın
	if panelShadow then
		panelShadow.Visible = false
	end
	local function setPanelVisible(visible)
		panel.Visible = visible
		if panelShadow then
			panelShadow.Visible = visible
		end
	end

	-- Başlık: yumurta adı + fiyat çipi. Panel uzaklaşınca kendiliğinden kapandığı için X gizli.
	local header = UIStyle.header(panel, { title = "Egg", emoji = "🥚", accent = "primary", chip = "0 Wins" })
	if header.close then
		header.close.Visible = false
	end
	local eggName = header.titleLabel
	local eggPrice = header.chip and header.chip:FindFirstChild("Text")
	if header.chip then
		header.chip.Position = UDim2.new(1, -16, 0.5, 0)
	end
	if not eggPrice then -- UIStyle yedek (düz) moduna düşerse çökmesin
		eggPrice = Instance.new("TextLabel")
	end

	-- Pet kartları: 5 eşit sütun (genişlik ölçekli, dar ekranda taşmaz)
	local cards = create("Frame", {
		Name = "Cards",
		Position = UDim2.fromOffset(12, 70),
		Size = UDim2.new(1, -24, 0, 154),
		BackgroundTransparency = 1,
	}, panel)

	-- ÇARPI İPUCU: kartlara tıklamak o peti 'yumurtadan çıkınca anında sil' diye işaretler
	local crossHint = UIStyle.label(panel, {
		name = "CrossHint",
		text = "Tap a pet to auto-delete it",
		role = "caption",
		align = "center",
		color = Theme.colors.primary.base,
		props = { Position = UDim2.fromOffset(12, 230), Size = UDim2.new(1, -24, 0, 18) },
	})

	-- Altta üç eşit düğme: E Open, R Auto, T Multi xN (tuş harfi küçük klavye çipi)
	local keys = create("Frame", {
		Name = "Keys",
		Position = UDim2.fromOffset(12, 260),
		Size = UDim2.new(1, -24, 0, 56),
		BackgroundTransparency = 1,
	}, panel)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, keys)

	local function makeKey(order, key, kind)
		local button = UIStyle.button(keys, {
			name = `Key_{key}`,
			text = "",
			kind = kind,
			size = "lg",
			width = UDim2.new(1 / 3, -8, 0, 0),
			layout = true,
			props = { LayoutOrder = order },
		})
		-- Klavye çipi: düğmenin solunda küçük tuş
		local cap = create("Frame", {
			Name = "KeyCap",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, -2),
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = Theme.colors.bg,
			BackgroundTransparency = 0.45,
		}, button)
		UIStyle.round(cap, 6)
		UIStyle.label(cap, {
			name = "KeyText",
			text = key,
			role = "bold",
			size = 14,
			align = "center",
			color = Theme.colors.text,
			props = { Size = UDim2.fromScale(1, 1) },
		})
		local caption = button:FindFirstChild("Label", true) or button
		return button, caption
	end
	local openButton, openCaption = makeKey(1, "E", "primary")
	local autoButton, autoCaption = makeKey(2, "R", "secondary")
	local multiButton, multiCaption = makeKey(3, "T", "secondary")
	local autoPass = EggRules.autoPass()
	local passAttributes = {}
	for _, pass in Config.EggPasses do
		table.insert(passAttributes, pass.attribute)
	end

	-- ---------- Durum ----------
	local currentEgg = nil -- panelde gösterilen yumurta
	local multiIndex = 1 -- SEÇİLİ çarpan (Config.EggMultiOptions sırası: 1 / 3 / 10): hep AÇIK bir çarpandır, kilitli çarpan seçilemez (başlıktaki toplam fiyat da ancak açık çarpanla değişir)
	local cursor = 1 -- T'nin imleci: kilitli seçeneklere de uğrar (satın alma/fiyat görünsün diye), seçimi değiştirmez
	local autoOn = false
	local opening = false

	local function owns(pass)
		return EggRules.owns(player, pass)
	end

	-- Seçili çarpanın pass'i (x1 için nil)
	local function multiPass()
		return EggRules.passForCount(Config.EggMultiOptions[multiIndex])
	end

	-- Ücretli özelliğe basılınca: pass satışa açıksa Roblox satın alma penceresi (fiyatı o gösterir), değilse fiyatlı 'coming soon' bildirimi
	local function buyPass(pass)
		if not pass then
			return
		end
		if (pass.GamePassId or 0) > 0 then
			pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, pass.GamePassId)
		elseif hooks.showToast then
			hooks.showToast(false, `{pass.name} ({ROBUX} {pass.Robux}) is coming soon!`)
		end
	end

	-- Win yetmeyince: Shop'u Win paketleri bölümünde aç (sahibi 'Win yetmiyorsa Win paketi satın almayı yönlendirsin' dedi)
	local function offerWins()
		if hooks.showToast then
			hooks.showToast(false, "Not enough Wins! Grab a Win Pack.")
		end
		if hooks.openShop then
			hooks.openShop("packs")
		end
	end

	local function refreshButtons()
		-- Pass elden gittiyse (DEV kilidi) otomatik açma kapanır ve seçili çarpan x1'e döner
		if autoOn and not owns(autoPass) then
			autoOn = false
		end
		if not owns(multiPass()) then
			multiIndex, cursor = 1, 1
		end
		autoCaption.Text = if autoOn then "Auto ON" else "Auto"
		UIStyle.setButtonKind(autoButton, if autoOn then "success" else "secondary")
		local count = Config.EggMultiOptions[multiIndex]
		multiCaption.Text = `Multi x{count}`
		-- Win yetmiyorsa Open 'Get Wins' olur (turuncu) ve Shop'un paket bölümünü açar
		local short = currentEgg ~= nil and winValue.Value < currentEgg.price
		openCaption.Text = if short then "Get Wins" else "Open"
		UIStyle.setButtonKind(openButton, if short then "warn" else "primary")
		if currentEgg then
			eggPrice.Text = if count > 1
				then `{Format.number(currentEgg.price * count)} Wins`
				else `{Format.number(currentEgg.price)} Wins`
		end
	end
	winValue:GetPropertyChangedSignal("Value"):Connect(refreshButtons)
	for _, attribute in passAttributes do
		player:GetAttributeChangedSignal(attribute):Connect(refreshButtons)
	end

	-- crossMarks[petId] = { cross, shade, update }: paneldeki kartlardaki çarpı ve gölge katmanları
	local crossMarks = {}

	-- Sunucudaki "anında sil" işaretlerine göre çarpıları günceller
	local function refreshCrosses()
		local marked = {}
		for id in string.gmatch(player:GetAttribute("AutoDeletePets") or "", "[^,]+") do
			marked[id] = true
		end
		for id, mark in crossMarks do
			mark.cross.Visible = marked[id] == true
			if mark.update then
				mark.update()
			end
		end
	end
	player:GetAttributeChangedSignal("AutoDeletePets"):Connect(refreshCrosses)

	local function showEgg(egg)
		currentEgg = egg
		setPanelVisible(egg ~= nil)
		if not egg then
			autoOn = false
			refreshButtons()
			return
		end

		-- EĞİTİM YUMURTASI (kısıtlı hesap): sabit sıralı döngü; oranlar yerine '25/50' ve sıradaki pet 'NEXT' (Catalog.trainingCycle, sunucuyla aynı)
		local training = player:GetAttribute("PaidRandomRestricted") ~= false
		local trainingCounts, nextPetId
		if training then
			trainingCounts = Catalog.trainingCounts(egg)
			local opened = tonumber(string.match(tostring(player:GetAttribute("TrainingEggs") or ""), egg.id .. ":(%d+)")) or 0
			local cycle = Catalog.trainingCycle(egg)
			nextPetId = cycle[opened % #cycle + 1]
		end
		eggName.Text = string.upper(if training then `{egg.name} (Training)` else egg.name)
		UIStyle.setChipText(header.chip, `{Format.number(egg.price)} Wins`) -- (refreshButtons çarpana göre toplamı günceller)
		crossHint.Text = if training
			then `Training Egg: fixed pet order, repeats every {Catalog.TrainingLength} opens`
			else "Tap a pet to auto-delete it"
		for _, child in cards:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		table.clear(crossMarks)
		local luck = player:GetAttribute("EggLuck") or 1
		local pool = sortedPool(egg, luck)
		for index, entry in pool do
			local pet = entry.pet
			local rarityColor = Catalog.rarityOf(pet).color
			-- Kart bir butondur: üstüne gelince kararır, tıklayınca çarpı konur/kalkar (çarpılı pet çıkınca anında silinir).
			-- Zemin kart rengi + nadirlik tonu, üstte nadirlik rengi şerit; kart başına tek ince çerçeve.
			local card = create("TextButton", {
				Name = `PetCard_{pet.id}`,
				Position = UDim2.new((index - 1) / #pool, 4, 0, 0),
				Size = UDim2.new(1 / #pool, -8, 1, 0),
				Text = "",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				BackgroundColor3 = Theme.colors.card:Lerp(rarityColor, 0.14),
			}, cards)
			UIStyle.round(card, Theme.radius.card)
			create("UIStroke", {
				Thickness = 1.5,
				Color = rarityColor,
				Transparency = 0.5,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}, card)
			local strip = create("Frame", {
				Name = "RarityStrip",
				Position = UDim2.fromOffset(14, 8),
				Size = UDim2.new(1, -28, 0, 4),
				BackgroundColor3 = rarityColor,
				BorderSizePixel = 0,
			}, card)
			UIStyle.round(strip, 2)
			UIStyle.label(card, {
				name = "Bonus",
				text = Format.petBonus(pet.mult),
				role = "number",
				size = 18,
				align = "center",
				color = rarityColor:Lerp(Color3.new(1, 1, 1), 0.35),
				props = { Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 22) },
			})
			-- Pet simgesi: pet renginde sevimli yüz / 3B (UIStyle.safePetIcon)
			UIStyle.safePetIcon(card, pet, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 42),
				Size = UDim2.fromOffset(54, 54),
			})
			UIStyle.label(card, {
				name = "PetName",
				text = pet.name,
				role = "caption",
				size = 13,
				align = "center",
				color = Theme.colors.text,
				props = { Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 16) },
			})
			if training and pet.id == nextPetId then
				UIStyle.chip(card, {
					name = "NextChip",
					text = "NEXT",
					accent = "primary",
					props = { Position = UDim2.fromOffset(4, 38), ZIndex = 7 },
				})
			end
			UIStyle.label(card, {
				name = "Chance",
				text = if training then `{trainingCounts[pet.id] or 0}/{Catalog.TrainingLength}` else string.format("%.1f%%", entry.chance),
				role = "bold",
				size = 16,
				align = "center",
				-- Luck Potion artırdıysa nadir petlerin yüzdesi yeşil
				color = if luck > 1 and entry.base < 20 then Theme.colors.success.base else Theme.colors.text,
				props = { Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, 0, 0, 22) },
			})

			-- Gölge katmanı: üstüne gelince (veya çarpılıyken) kartı karartır
			local shade = create("Frame", {
				Name = "Shade",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, card)
			UIStyle.round(shade, Theme.radius.card)

			-- Çarpı: iki çapraz kırmızı çubuk
			local cross = create("Frame", {
				Name = "Cross",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = false,
				ZIndex = 6,
			}, card)
			for _, angle in { 45, -45 } do
				local bar = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(10, 110),
					Rotation = angle,
					BackgroundColor3 = Theme.colors.danger.base,
					BackgroundTransparency = 0.1,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, cross)
				UIStyle.round(bar, 5)
			end
			local markLabel = UIStyle.label(cross, {
				name = "MarkLabel",
				text = "AUTO-DELETE",
				role = "bold",
				size = 11,
				align = "center",
				color = Theme.colors.danger.text,
				props = {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(0.94, 0, 0, 18),
					BackgroundTransparency = 0.15,
					BackgroundColor3 = Theme.colors.danger.dark,
					ZIndex = 8,
				},
			})
			UIStyle.round(markLabel, 6)
			crossMarks[pet.id] = { cross = cross, shade = shade }

			local hovering = false
			local function updateShade()
				local marked = crossMarks[pet.id].cross.Visible
				shade.BackgroundTransparency = if marked then 0.45 elseif hovering then 0.6 else 1
			end
			card.MouseEnter:Connect(function()
				hovering = true
				updateShade()
			end)
			card.MouseLeave:Connect(function()
				hovering = false
				updateShade()
			end)
			card.MouseButton1Click:Connect(function()
				task.spawn(function()
					local ok, message = shopFunction:InvokeServer("ToggleAutoDelete", pet.id)
					if hooks.showToast and type(message) == "string" then
						hooks.showToast(ok == true, message) -- 'Dragon will be auto-deleted' / 'will be kept'
					end
				end)
			end)
			crossMarks[pet.id].update = updateShade
		end
		refreshCrosses()
		refreshButtons()
	end

	-- Luck Potion başlayınca/bitince açık panelin yüzdeleri güncellenir
	player:GetAttributeChangedSignal("EggLuck"):Connect(function()
		if currentEgg then
			showEgg(currentEgg)
		end
	end)
	-- Eğitim yumurtası sayacı ilerleyince 'NEXT' işareti güncellenir
	player:GetAttributeChangedSignal("TrainingEggs"):Connect(function()
		if currentEgg and player:GetAttribute("PaidRandomRestricted") ~= false then
			showEgg(currentEgg)
		end
	end)

	-- manual: oyuncu E / Open ile mi bastı (Win yetmiyorsa Shop'u açar); otomatik döngü sessizce durur
	local function openEgg(manual)
		if not currentEgg or opening then
			return false
		end
		-- (Seçili çarpan hep açıktır: refreshButtons kilitli çarpanı x1'e çevirir; sunucu da pass'siz x3/x10'u reddeder)
		if not owns(multiPass()) then
			refreshButtons()
			return false
		end
		if winValue.Value < currentEgg.price then
			autoOn = false
			refreshButtons()
			if manual then
				offerWins()
			end
			return false
		end
		opening = true
		-- Açılıştan önce sahip olunan petler: yeni gelenlere "NEW!" rozeti vermek için
		local ownedBefore = {}
		for id in string.gmatch(player:GetAttribute("OwnedPets") or "", "[^,]+") do
			ownedBefore[id] = true
		end
		local hatchedEgg = currentEgg
		local count = Config.EggMultiOptions[multiIndex]
		local automatic = autoOn and not manual
		local ok, message, results = openFunction:InvokeServer(hatchedEgg.id, count, automatic)
		opening = false
		if ok and results and okReveal then
			-- Yumurta kırılma animasyonu SADECE elle açılan TEK yumurtada (çoklu x3/x10 ve otomatik açmada yok: sahibi istedi, hız kesmesin)
			local animatedEgg = if count == 1 and not automatic then hatchedEgg else nil
			local shown, err = pcall(Reveal.show, screenGui, results, ownedBefore, animatedEgg)
			if not shown then
				warn(`[Reveal] {err}`)
			end
		end
		-- Sonuç mesajını sunucu bildirim olarak yollar; başarısızsa (Win bitti, envanter dolu) otomatiği kapat
		if not ok then
			autoOn = false
			refreshButtons()
			-- Win paylaşıldı/bitti ve sunucu 'Not enough Wins' dedi (istemci kontrolünden sonra): elle bastıysa Shop'u aç (bildirimi sunucu zaten gösterdi)
			if manual and string.find(message or "", "Not enough Wins", 1, true) and hooks.openShop then
				hooks.openShop("packs")
			end
		end
		return ok
	end

	-- Otomatik açma: ücretli (Auto Open). Kilitliyse satın alma görünür (fiyat ancak buna basınca çıkar)
	local function toggleAuto()
		if not currentEgg then
			return
		end
		if not owns(autoPass) then
			buyPass(autoPass)
			return
		end
		autoOn = not autoOn
		refreshButtons()
	end

	-- T: imleç x1 > x3 > x10 gezer. Açık seçenekte seçim değişir; KİLİTLİ seçenekte hiçbir şey değişmez (başlıktaki fiyat da), sadece o pass'in satın alma penceresi/fiyatı görünür (shared/EggRules.step)
	local function cycleMulti()
		local newCursor, selected, lockedPass = EggRules.step(Config.EggMultiOptions, cursor, owns)
		cursor = newCursor
		if selected then
			multiIndex = newCursor
			refreshButtons()
		else
			buyPass(lockedPass)
		end
	end

	-- Bir çarpan pass'i satın alınınca (öznitelik true olunca) imlecin üstündeki o çarpan hemen seçilir
	for _, pass in Config.EggPasses do
		if pass.count then
			player:GetAttributeChangedSignal(pass.attribute):Connect(function()
				if owns(pass) and Config.EggMultiOptions[cursor] == pass.count then
					multiIndex = cursor
					refreshButtons()
				end
			end)
		end
	end

	openButton.MouseButton1Click:Connect(function()
		task.spawn(openEgg, true)
	end)
	autoButton.MouseButton1Click:Connect(toggleAuto)
	multiButton.MouseButton1Click:Connect(cycleMulti)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not currentEgg then
			return
		end
		if input.KeyCode == Enum.KeyCode.E then
			task.spawn(openEgg, true)
		elseif input.KeyCode == Enum.KeyCode.R then
			toggleAuto()
		elseif input.KeyCode == Enum.KeyCode.T then
			cycleMulti()
		end
	end)

	-- Karakter bir yumurta pedine dokunacak kadar yaklaşınca (üstüne basınca) paneli göster, uzaklaşınca kapat
	local function padGap(root, pad)
		local local_ = pad.CFrame:PointToObjectSpace(root.Position)
		local dx = math.max(math.abs(local_.X) - pad.Size.X / 2, 0)
		local dz = math.max(math.abs(local_.Z) - pad.Size.Z / 2, 0)
		return math.sqrt(dx * dx + dz * dz) - root.Size.X / 2, math.abs(local_.Y)
	end

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local nearest, nearestGap = nil, math.huge
		if root then
			for _, entry in entries do
				local gap, height = padGap(root, entry.pad)
				local limit = if entry.egg == currentEgg then EXIT_GAP else ENTER_GAP
				if gap <= limit and height <= 12 and gap < nearestGap then
					nearest, nearestGap = entry.egg, gap
				end
			end
		end

		if nearest ~= currentEgg then
			showEgg(nearest)
		end
	end)

	-- Otomatik açma: panel açıkken ve otomatik açıksa belli aralıkla yumurta açar
	task.spawn(function()
		while true do
			task.wait(AUTO_INTERVAL)
			if autoOn and currentEgg then
				openEgg()
			end
		end
	end)
end

return EggShop
