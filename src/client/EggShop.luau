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
local NORMAL = Color3.fromRGB(30, 190, 220)
local WINS_ORANGE = Color3.fromRGB(255, 150, 40) -- Win yetmeyince Open düğmesi

-- (Panel kartlarının rengi petin NADİRLİĞİ'nden gelir: Catalog.rarityOf = Config.Rarities; yumurta açılışındaki kart ve Pets menüsüyle aynı renk)

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
	-- Yumurtanın standı: World 1 'EggShop', World 2 'EggShop_W2' (yumurtanın 'world' alanı)
	local function eggFolder(egg)
		local world = egg.world or 1
		return Workspace:WaitForChild(if world == 1 then "EggShop" else `EggShop_W{world}`)
	end
	local winValue = player:WaitForChild("leaderstats"):WaitForChild(Config.StatWins)
	local openFunction = ReplicatedStorage:WaitForChild("EggOpen")
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")

	-- ---------- Yumurtaların üstündeki etiketler ve ped renkleri ----------
	local entries = {}
	local refreshPads -- aşağıda tanımlanır; ped sonradan gelince renkleri boyar
	-- Bir yumurtanın etiketleri. StreamingEnabled: oyuncudan uzaktaki dünyanın pedleri istemciye ancak yaklaşınca gelir, bu yüzden her ped
	-- KENDİ iş parçacığında beklenir (sırayla beklemek World 1'deki oyuncuda World 2 pedinde takılıp paneli hiç başlatmıyordu)
	local function setupEgg(egg, pad)

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
		if refreshPads then
			refreshPads()
		end
	end
	for _, egg in Config.Eggs do
		task.spawn(function()
			setupEgg(egg, eggFolder(egg):WaitForChild(`Pad_{egg.id}`, math.huge))
		end)
	end

	local function petCount()
		local count = 0
		for _ in string.gmatch(player:GetAttribute("OwnedPets") or "", "[^,]+") do
			count += 1
		end
		return count
	end

	refreshPads = function()
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
	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 68),
		Size = UDim2.fromOffset(580, 338), -- 5 pet kartı yan yana sığsın (+ altta 'çarpı' ipucu satırı)
		BackgroundColor3 = Color3.fromRGB(45, 48, 62),
		BackgroundTransparency = 0.05,
		Active = true, -- panele tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, panel)
	UIStyle.soften(panel, { radius = 14, strength = 0.18, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(30, 190, 220),
	}, panel)
	UIStyle.soften(header, { radius = 12, strength = 0.25 })
	local eggName = makeText(header, {
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(0.55, 0, 1, -12),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)
	local eggPrice = makeText(header, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 4),
		Size = UDim2.new(0.38, 0, 1, -8),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.new(1, 1, 1),
	}, 3)

	-- ÇARPI İPUCU (playtest: 'egg açınca pet anında silindi, kartlara tıklayınca çarpı konduğu hiç belli değildi'): kartlara tıklamak o peti 'yumurtadan çıkınca anında sil' diye işaretler
	local crossHint = makeText(panel, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 220),
		Size = UDim2.new(0.94, 0, 0, 22),
		Text = "Tap a pet to mark it with an X: marked pets are deleted the moment they hatch!",
		TextColor3 = Color3.fromRGB(255, 214, 120),
	}, 2)
	crossHint.TextWrapped = false

	local cards = create("Frame", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, 170),
		BackgroundTransparency = 1,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(104, 150),
		CellPadding = UDim2.fromOffset(8, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, cards)

	-- Panelin altındaki tuş kutuları
	local keys = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 252),
		Size = UDim2.fromOffset(250, 70), -- E / R / T
		BackgroundTransparency = 1,
	}, panel)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 12),
	}, keys)

	local function makeKey(order, key)
		local button = create("TextButton", {
			LayoutOrder = order,
			Size = UDim2.fromOffset(70, 70),
			BackgroundColor3 = Color3.fromRGB(30, 190, 220),
			Text = "",
			AutoButtonColor = true,
		}, keys)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
		UIStyle.soften(button, { radius = 10, strength = 0.28 })
		makeText(button, {
			Position = UDim2.fromScale(0.1, 0.06),
			Size = UDim2.fromScale(0.8, 0.5),
			Text = key,
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
		local caption = makeText(button, {
			Position = UDim2.fromScale(0.04, 0.58),
			Size = UDim2.fromScale(0.92, 0.34),
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
		return button, caption
	end
	local openButton, openCaption = makeKey(1, "E")
	local autoButton, autoCaption = makeKey(2, "R")
	local multiButton, multiCaption = makeKey(3, "T")
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
		autoButton.BackgroundColor3 = if autoOn then Color3.fromRGB(60, 200, 90) else NORMAL
		local count = Config.EggMultiOptions[multiIndex]
		multiCaption.Text = `Multi x{count}`
		-- Win yetmiyorsa Open 'Get Wins' olur (turuncu) ve Shop'un paket bölümünü açar
		local short = currentEgg ~= nil and winValue.Value < currentEgg.price
		openCaption.Text = if short then "Get Wins" else "Open"
		openButton.BackgroundColor3 = if short then WINS_ORANGE else NORMAL
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
		panel.Visible = egg ~= nil
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
		eggName.Text = if training then `{egg.name} (Training)` else egg.name
		crossHint.Text = if training
			then `Training Egg: pets come in a fixed order. Every {Catalog.TrainingLength} opens repeat it.`
			else "Tap a pet to mark it with an X: marked pets are deleted the moment they hatch!"
		for _, child in cards:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		table.clear(crossMarks)
		local luck = player:GetAttribute("EggLuck") or 1
		for index, entry in sortedPool(egg, luck) do
			local pet = entry.pet
			-- Kart bir butondur: üstüne gelince kararır, tıklayınca çarpı konur/kalkar (çarpılı pet çıkınca anında silinir)
			local card = create("TextButton", {
				LayoutOrder = index,
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Catalog.rarityOf(pet).color,
			}, cards)
			create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, card)
			UIStyle.soften(card, { radius = 10, strength = 0.3 })
			makeText(card, {
				Position = UDim2.fromScale(0.05, 0.02),
				Size = UDim2.fromScale(0.9, 0.2),
				Text = Format.petBonus(pet.mult),
				TextColor3 = Color3.new(1, 1, 1),
			}, 2)
			-- Pet simgesi: pet renginde sevimli yüz (UIStyle.petIcon)
			UIStyle.safePetIcon(card, pet, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.235),
				Size = UDim2.fromOffset(58, 58),
			})
			makeText(card, {
				Position = UDim2.fromScale(0.04, 0.62),
				Size = UDim2.fromScale(0.92, 0.14),
				Text = pet.name,
				TextColor3 = Color3.new(1, 1, 1),
			}, 2)
			if training and pet.id == nextPetId then
				makeText(card, { Position = UDim2.fromScale(0.02, 0.0), Size = UDim2.fromScale(0.5, 0.17), Text = "NEXT", TextColor3 = Color3.fromRGB(255, 235, 90), ZIndex = 7 }, 2)
			end
			makeText(card, {
				Position = UDim2.fromScale(0.04, 0.78),
				Size = UDim2.fromScale(0.92, 0.2),
				Text = if training then `{trainingCounts[pet.id] or 0}/{Catalog.TrainingLength}` else string.format("%.1f%%", entry.chance),
				TextColor3 = if luck > 1 and entry.base < 20 then Color3.fromRGB(150, 255, 150) else Color3.new(1, 1, 1), -- Luck Potion artırdıysa nadir petlerin yüzdesi yeşil
			}, 2)

			-- Gölge katmanı: üstüne gelince (veya çarpılıyken) kartı karartır
			local shade = create("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 1,
				ZIndex = 5,
			}, card)
			UIStyle.round(shade, 10)

			-- Çarpı: iki çapraz kırmızı çubuk
			local cross = create("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = false,
				ZIndex = 6,
			}, card)
			for _, angle in { 45, -45 } do
				local bar = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(16, 120),
					Rotation = angle,
					BackgroundColor3 = Color3.fromRGB(235, 45, 65),
					ZIndex = 6,
				}, cross)
				create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, bar)
			end
			local markLabel = makeText(cross, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.94, 0.2),
				Text = "AUTO-DELETE",
				TextColor3 = Color3.fromRGB(255, 80, 90),
				ZIndex = 8,
			}, 3)
			markLabel.BackgroundTransparency = 0.25
			markLabel.BackgroundColor3 = Color3.new(0, 0, 0)
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
