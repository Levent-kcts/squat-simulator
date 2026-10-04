-- Oyunun tüm ayarları burada. Dengeyi (zorluk, fiyat, hız) değiştirmek için sadece bu dosyayı düzenle.

return {
	-- Oyunun adı (tabelalarda görünür)
	GameName = "Squat Simulator",

	-- Leaderboard'da ve UI'da görünen istatistik isimleri
	StatLegMuscle = "Leg Muscle",
	StatWins = "Win",
	StatLevel = "Level",
	StatRebirths = "Rebirths",

	-- Level: level çubuğu KAZANILAN BACAK KASI ile dolar (tıklama sayısıyla değil). 1. level 10, 10. level 22 kas ister.
	-- Level, rebirth sayısına bağlı bir üst sınıra kadar çıkar. Sınıra gelince rebirth yapılabilir.
	-- Her level tıklama başı kazancı artırır (MultiplierPerLevel).
	Level = {
		BaseTaps = 10, -- 1. level 10 kas ister
		-- Bir sonraki levele geçmek için gereken kas KUVVET YASASIYLA büyür: 10 + (TapsAtLevel10 - 10) / 9^CostPower x (level - 1)^CostPower
		-- (level 1 = 10, level 10 = 22; sonrası hızla artar). Üstel (1.09^level) yerine kuvvet yasası seçildi: rebirth başına süre düzgün uzasın,
		-- tools/simulate.py ile ölçüldü (aktif oyuncu: 1. rebirth ~5 dk, 5. ~2 sa, 12. ~12 sa, 20. ~1.2 gün, 45. ~3.5 gün).
		CostPower = 4.2,
		TapsAtLevel10 = 22,
		BaseMaxLevel = 20, -- hiç rebirth yapmamışken ulaşılabilecek en yüksek level
		MaxLevelPerRebirth = 10, -- her rebirth bu kadar yüksek level izni verir
		MultiplierPerLevel = 0.1, -- level 20 = x2.9
	},

	-- Görünüm: oyuncunun KENDİ skini (ten rengi, gömlek, pantolon) korunur. Sadece bacakların üstünde görünen
	-- ikinci katman (katmanlı kıyafet/eşofman), çanta, şapka gibi aksesuarlar kaldırılır.
	-- Sadece KeepAccessoryTypes listesindeki aksesuarlar (saç, yüz detayları) kalır.
	Appearance = {
		Enabled = true,
		KeepAccessoryTypes = { "Hair", "Face", "Eyebrow", "Eyelash", "Mood" },
		-- Oyuncunun kendi pantolon dokusu kaldırılır, bacaklar ve kaslar tek renk olur (PantsColor ya da ten rengi).
		StandardPants = true,
		PantsColor = nil, -- nil: bacaklar oyuncunun kendi ten rengi olur. Sabit renk için Color3.fromRGB(...) yaz.
		Shorts = true, -- herkese siyah şort/boxer eklenir (kas ne kadar büyürse büyüsün kalça bölgesi kapalı kalır)
		RemoveClassicClothing = false, -- true: gömlek/pantolon da kaldırılır
		UnifySkinColor = false, -- true: tüm vücut kafa rengine boyanır (gömlek/pantolon rengi yerine düz ten)
		-- Skin rafından renk alınınca vücut o renge boyanır; oyuncunun gömleği (üstündeki kıyafet) kalır, sadece ten rengi değişir.
		-- true yaparsan gömlek dokusu da gizlenir (skin bırakılınca geri gelir): gövde ve kollar tam skin rengi görünür.
		HideShirtWithSkin = false,
	},

	-- Karakter boyutu: level arttıkça boy ve genişlik büyür (Roblox'un kendi ölçek sistemi, kıyafetler de uyar).
	-- Level 1'de ince (StartWidth) başlar, MaxLevel'de en büyük boyuta (MaxWidth/MaxHeight) ulaşır ve orada DURUR.
	-- Üst sınırlar koridordan/kapıdan rahat geçecek şekilde seçildi (koridor 32 stud geniş, 24 yüksek).
	-- MaxLevel'den sonra görüntü değişmez; karakter sadece daha güçlü olmaya devam eder (çarpanlar).
	-- Rebirth level'ı 1'e döndürdüğü için karakter yine ince hâline döner.
	Body = {
		MaxLevel = 1000, -- bu levelde en büyük boyuta ulaşılır ve orada durur
		GrowthCurve = 0.5, -- 1 = düz artış, 0.5 = başta hızlı sonra yavaş (ilk levellerde fark görünsün diye)
		StartWidth = 0.9,
		MaxWidth = 2.0,
		StartHeight = 1.0,
		MaxHeight = 2.2,
	},

	-- Bacak kasları: oyun başında HİÇ kas yoktur (ince bacaklar). Kaslar aşağıdaki levellerde belirir ve irileşir:
	-- StageLevels[1] = ilk kaslanma, sonrakiler daha da iri. Son level (1000) aynı zamanda büyümenin durduğu seviyedir.
	-- Aralıklar seyrekleşir: 5, 20, 100, ... Rebirth level'ı 1'e döndürdüğü için kaslar da kaybolur.
	Legs = {
		StageLevels = { 5, 20, 100, 250, 500, 1000 },
		MuscleColor = nil, -- nil: kaslar standart pantolon rengini (veya bacak rengini) alır
		MuscleGrowth = 1, -- kas parçalarının büyüme hızı çarpanı (1 normal, 1.5 daha iri, 0.5 daha küçük)
	},

	-- Rebirth: level 1'e, bacak kası ve Win 0'a döner; ayakkabı ve petler korunur.
	-- Karşılığında kalıcı çarpan: 1 rebirth = x1.5, 2 rebirth = x2.0 ...
	Rebirth = {
		MultiplierPerRebirth = 0.5,
		-- "SKIP?" butonu: Robux ile level şartını atlayıp rebirth yapma. SkipProductId 0 ise buton "yakında" olarak kalır.
		SkipRobuxPrice = 99,
		SkipProductId = 0,
	},

	-- Test araçları (sol üstteki DEV paneli): level, rebirth, Win, kas verme gibi. Sadece Studio'da ve oyunun sahibi
	-- için çalışır, başka oyuncular kullanamaz. Oyunu herkese açmadan önce Enabled = false yapman önerilir.
	DevTools = { Enabled = true },

	-- Oyunun başlangıç alanı. Spawn burası, Win alınca oyuncu buraya ışınlanır.
	SpawnPosition = Vector3.new(0, 5, 0),

	-- Tıklama
	MusclePerClick = 1, -- eşya/pet yokken her tıklamada kaç bacak kası artar (hasar = toplam bacak kası)
	-- Her tıklama bir hareket (animasyon) başlatır; hareket sürerken yeni tıklamalar yok sayılır.
	-- Puan ve hasar hareket BİTTİĞİNDE bir kez verilir. Süreler saniye cinsindendir.
	MoveDuration = { Kick = 0.4, Squat = 0.5 },

	-- Kayıt sistemi
	Save = {
		StoreName = "PlayerData_v1", -- ismi değiştirirsen herkesin kaydı sıfırlanır!
		AutosaveInterval = 30, -- saniye (ayrıca Win/satın alma/pet sonrası da hemen kaydedilir)
	},

	-- Günlük giriş ödülü: her yeni günde (UTC) girişte otomatik verilir; art arda gelen günler seri oluşturur, bir gün atlanırsa seri 1'e döner.
	-- 7 günlük döngü. kind: moves (amount kadar hareketin kazancı = amount x tıklama başı kazanç), stageWins (stage. aşamanın Win ödülü),
	-- boostMuscle / boostWins (BoostMinutes dk 2x), pet (pet id). boosts = true ise iki güçlendirme birden eklenir.
	DailyRewards = {
		{ kind = "moves", amount = 400 },
		{ kind = "boostMuscle" },
		{ kind = "stageWins", stage = 5 },
		{ kind = "moves", amount = 1500 },
		{ kind = "boostWins" },
		{ kind = "pet", pet = "tiger" },
		{ kind = "moves", amount = 5000, boosts = true },
	},

	-- Shop (sol menüdeki Shop butonu): Robux ile alınan Developer Product'lar. productId: Creator Hub > Monetization > Developer Products'ta
	-- oluşturulan ürünün ID'si; 0 = henüz yok, kart "Coming soon" gösterir. Satın alma sunucuda ProcessReceipt ile doğrulanır
	-- (server/Purchases): aynı satın alma iki kez ödül vermez. kind: boostMuscle / boostWins (minutes dk 2x), wins (amount Win),
	-- stageWins (stage. aşamanın Win ödülü kadar), moves (amount hareketlik kas). Fiyatlar (robux) geçicidir.
	Shop = {
		Products = {
			{ id = "boostMuscle30", name = "2x Muscle", detail = "30 minutes", icon = "⚡", kind = "boostMuscle", minutes = 30, robux = 49, productId = 0, color = Color3.fromRGB(255, 150, 40) },
			{ id = "boostWins30", name = "2x Wins", detail = "30 minutes", icon = "🏆", kind = "boostWins", minutes = 30, robux = 49, productId = 0, color = Color3.fromRGB(255, 205, 50) },
			{ id = "musclePack", name = "Muscle Pack", detail = "10,000 squats of muscle", icon = "🦵", kind = "moves", amount = 10000, robux = 39, productId = 0, color = Color3.fromRGB(70, 150, 255) },
			{ id = "winsSmall", name = "Win Pack", detail = "Stage 8 reward", icon = "💰", kind = "stageWins", stage = 8, robux = 29, productId = 0, color = Color3.fromRGB(70, 210, 90) },
			{ id = "winsBig", name = "Mega Win Pack", detail = "Stage 12 reward", icon = "💎", kind = "stageWins", stage = 12, robux = 99, productId = 0, color = Color3.fromRGB(190, 90, 255) },
		},
	},

	-- Kodlar (sol menüdeki CODES butonu): oyuncu kodu yazınca ödül alır, her kod hesap başına bir kez kullanılır (kayıtlı). Büyük/küçük harf fark etmez.
	-- Ödül türleri günlük ödülle aynı (moves, wins, stageWins, boostMuscle, boostWins, pet). Pazarlama için buraya kendi kodlarını ekle.
	Codes = {
		WELCOME = { kind = "moves", amount = 600 },
		SQUAT = { kind = "wins", amount = 25 },
		BOOST = { kind = "boostMuscle" },
	},

	-- Çevrimdışı kazanç: oyundan uzakta geçen süre için girişte küçük bir bacak kası ödülü ("Welcome back!"). Süre MaxHours ile sınırlanır,
	-- MinSeconds'tan kısa aralar sayılmaz. Kazanç = (uzakta geçen saniye / squat süresi) x tıklama başı kazanç x Rate (aktif oynamanın yüzdesi).
	Offline = { Enabled = true, Rate = 0.02, MaxHours = 8, MinSeconds = 300 },

	-- Sesler (client/Sfx). id: "rbxasset://sounds/..." (Roblox'la gelen hazır sesler) ya da "rbxassetid://123456" (Creator Store'dan seçtiğin ses).
	-- id = "" ise o olay sessiz kalır. volume 0-1, speed: { en yavaş, en hızlı } çalma hızı (her çalışta rastgele; ton çeşitliliği).
	-- Aşağıdakiler geçici: Roblox'un kendi hazır sesleri. Daha güzel sesler için Creator Store'dan ses bulup id'leri değiştir.
	Sounds = {
		-- Vücut büyümesi (her level atlayışında karakter büyür): Grow kısa bir güçlenme sesi, GrowBig yeni kas çıkınca/irileşince çalan daha güçlü ses.
		-- Squat/tekme sesi YOK (gecikiyordu, sahibi kaldırttı). pick = "first": yüklenebilen ilk ses çalar (ses her seferinde aynı kalsın).
		Grow = {
			ids = { "rbxassetid://18613451236", "rbxassetid://96518360714287", "rbxassetid://114672007947933" },
			pick = "first",
			volume = 0.35,
			speed = { 0.97, 1.05 },
			gap = 0.4,
		},
		GrowBig = {
			ids = { "rbxassetid://133977339172345", "rbxassetid://90395161583182", "rbxassetid://109916245799751" },
			pick = "first",
			volume = 0.5,
			speed = { 0.97, 1.03 },
			gap = 1,
		},
		-- Duvar kırılma: lego kırılma sesi (Creator Store'daki ücretsiz sesler; her seferinde biri rastgele seçilir, yüklenemeyen elenir).
		-- ids bozulursa fallback çalar. gap: aynı sesin en sık çalma aralığı (bir vuruşta üst üste duvar kırılınca gürültü olmasın)
		WallBreak = {
			ids = { "rbxassetid://15351953300", "rbxassetid://93173820310993", "rbxassetid://90091919296355" },
			fallback = "rbxasset://sounds/action_footsteps_plastic.mp3",
			volume = 0.45,
			speed = { 0.95, 1.1 },
			gap = 0.3,
		},
		Win = { id = "rbxasset://sounds/volume_slider.ogg", volume = 0.4, speed = { 1.5, 1.6 } },
		Rebirth = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.5, speed = { 0.7, 0.75 } },
		Hatch = { id = "rbxasset://sounds/impact_water.mp3", volume = 0.35, speed = { 1.3, 1.5 } },
		Rare = { id = "rbxasset://sounds/volume_slider.ogg", volume = 0.4, speed = { 2.2, 2.4 } }, -- Epic ve üstü pet çıkınca
		Buy = { id = "rbxasset://sounds/volume_slider.ogg", volume = 0.3, speed = { 1.3, 1.4 } },
		Error = { id = "rbxasset://sounds/volume_slider.ogg", volume = 0.25, speed = { 0.6, 0.65 } },
	},

	-- Arka plan müziği (döngüde çalar, "Sounds" anahtarı kapatınca susar). id boşsa müzik yok; Creator Store'dan beğendiğin bir müziğin
	-- "rbxassetid://..." ID'sini yaz. Müzik sesi efektleri bastırmasın diye düşük tutulur.
	Music = { id = "", volume = 0.25 },

	-- Yeni oyuncu yol göstericisi (client/Guide): hiç rebirth yapmamış oyuncuya, ilk MaxStage aşamada duvara/Win pedine giden parlak çizgi.
	Guide = { MaxStage = 3 },

	-- Kameranın en fazla ne kadar uzaklaşabileceği (stud). Koridorun dışından içeriyi görmeyi engeller.
	CameraMaxZoom = 40,

	-- Başlangıç lobisi: spawn'ın bulunduğu geniş kapalı salon
	Lobby = {
		HalfWidth = 62, -- salonun yarı genişliği (stud; salon 124 x 130, referans fotoğraflardaki gibi derli toplu). Sol duvar ayakkabılar, sağ duvar antrenman alanı, arka duvar yumurtalar, ön duvar koridor
		BackZ = 65, -- salonun arka duvarının Z'si (ön duvar koridor girişidir; spawn tam ortadadır)
		Height = 36, -- salonun yüksekliği (koridordan yüksek)
		-- Sol duvardaki raflar: duvar boyunca Z konumu (+ arka duvara/yumurtalara doğru). Her raf rampalarıyla ~51 stud yer kaplar.
		ShoeShelfZ = -36.75, -- ayakkabı rafı: koridor girişi tarafına yaslı (her raf rampalarıyla 50.5 stud, giriş duvarına 3 stud boşluk)
		SkinShelfZ = 15.75, -- skin rafı: ayakkabı rafının hemen yanında (aralarında 2 stud). Sol duvarın arka ucu (z > 41) yeni şeyler için boş
		LeaderboardZ = 53.5, -- sol duvarın arka ucundaki sıralama panoları (skin rafından sonra boş bırakılan köşe)
		TrainingShelfZ = -12, -- SAĞ duvardaki antrenman alanı: koridor tarafına doğru kaydırıldı, duvarın arka ucu (z > 23) yeni şeyler için boş
	},

	-- Tek sıra halinde ard arda duvarlar. En düşük canlı duvardan başlanır, can giderek artar.
	Wall = {
		Count = 100, -- toplam duvar sayısı
		GroupSize = 5, -- her kaç duvardan sonra sarı Win butonu gelsin (hasar da grubun sonunu geçmez)

		-- Duvar canı: AYNI gruptaki (aşamadaki) 5 duvarın canı eşittir. Referans oyundaki değerler:
		-- 1. grup 25, 2. grup 250, 3. grup 3000. Listede olmayan sonraki gruplar, bir öncekinin
		-- HealthGrowthAfter katı olur (3. grup 3000 ise 4. grup 3000 x 5 = 15000).
		-- Sonraki grupları oyunun ekonomisine (çarpanlar, rebirth) göre ayrıca dengelemek gerekecek.
		GroupHealth = { 25, 250, 3000 },
		HealthGrowthAfter = 5, -- 4. grup 3000 x 5 = 15000 ... (12 iken Win ödülleri çok geç yetişiyordu; tools/simulate.py)

		Width = 32, -- koridorun ve duvarın genişliği (stud)
		Height = 23.8, -- kırılan duvarın yüksekliği: zemin üstü (0.2) + 23.8 = 24 = tavanın alt yüzü. CeilingHeight'i değiştirirsen bunu da (CeilingHeight - 0.2) yap, yoksa duvarın üstünde boşluk kalır
		CeilingHeight = 24, -- yan duvarların, tavanın ve lobinin yüksekliği
		Thickness = 3,
		ChamberExtra = 10, -- her aşama sonundaki Win odası koridordan her yana bu kadar (stud) geniştir (0 = koridor genişliğinde); oda 52 stud
		Spacing = 8, -- aynı gruptaki duvarlar arası mesafe (stud)
		ButtonGap = 34, -- grubun son duvarı ile sonraki grubun ilk duvarı arası (Win pedleri ve tabelalar buraya gelir)
		StartZ = -66.5, -- ilk duvarın Z konumu (salonun ön duvarı Z = -65 olacak şekilde; spawn salonun tam ortasında, 0)

		HitRange = 9, -- ilk sağlam duvarın ÖN YÜZÜNE bu mesafeden yakınsan tekme atar ve hasar verirsin (stud)
		RespawnDelay = 15, -- 100. duvar kırılınca (Win'e basılmazsa) kaç saniye sonra tur başa sarılsın

		-- Win ödülü: 1. aşama = 1, sonraki = bir öncekinin RewardGrowth katı + 1  ->  1, 3, 7, 15, 31 ...
		-- RewardGrowth 2 (veya üstü) olduğu sürece bir aşamanın ödülü, bir önceki aşamayı 2 kez
		-- yapmanın ödülünden hep fazladır. Yani oyuncu için ilerlemek, aynı aşamayı tekrarlamaktan karlıdır.
		RewardGrowth = 2,

		-- Her aşamanın duvarlarında yazan isim (20 aşama)
		StageNames = {
			"Paper", "Wood", "Clay", "Brick", "Stone", "Copper", "Iron", "Silver", "Gold", "Candy",
			"Ice", "Lava", "Jade", "Ruby", "Sapphire", "Emerald", "Amethyst", "Obsidian", "Crystal", "Diamond",
		},
	},

	-- Her 5'li grubun sonundaki boşlukta duran Win butonları.
	-- side: koridora bakarken -1 = sol, 1 = sağ. rewardMultiplier: ödül çarpanı (varsayılan 1).
	WinButtons = {
		-- VIP pedi: solda, normalin 2 katı Win verir; game pass'i olmayana Robux satın alma penceresi açar (VipGamePassId).
		{ id = "vip", side = -1, vip = true, rewardMultiplier = 2 },
		{ id = "normal", side = 1 },
	},

	-- VIP game pass'in ID'si (Roblox Creator Hub'da game pass oluşturunca verilir). 0 = henüz yok: VIP pedine ("2x WINS") basınca
	-- 'coming soon' mesajı çıkar. ID girilince pede basan, pass'i olmayana Robux satın alma penceresi açılır; pass'i olan 2x Win alır.
	VipGamePassId = 0,

	-- Ayakkabılar: lobideki raflardan, üstlerine basarak satın alınır (alt sıra ucuz, üst sıra pahalı).
	-- damage = duvara verilen hasar çarpanı (hasar = bacak kası x damage). Bacak kazancını ETKİLEMEZ. Takılı ayakkabı geçerlidir, toplanmaz (sahip olduğun ucuz ayakkabılara basıp istediğini takabilirsin).
	-- Fiyatlar (Win) GEÇİCİDİR, oyunun ekonomisi oturunca birlikte ayarlanacak.
	MaxGlowShoeId = "neon", -- ayakkabı parlaklığı bu ayakkabıya (Neon Kicks) kadar artar, daha güçlüleri aynı parlaklıkta kalır
	Items = {
		{ id = "oldsneakers", name = "Old Sneakers", price = 3, damage = 1.5, color = Color3.fromRGB(170, 255, 70) },
		{ id = "canvas", name = "Canvas Shoes", price = 8, damage = 2, color = Color3.fromRGB(120, 170, 255) },
		{ id = "running", name = "Running Shoes", price = 20, damage = 3, color = Color3.fromRGB(255, 140, 60) },
		{ id = "trail", name = "Trail Boots", price = 45, damage = 4, color = Color3.fromRGB(0, 230, 170) },
		{ id = "hightops", name = "High-Tops", price = 100, damage = 6, color = Color3.fromRGB(255, 70, 160) },
		{ id = "cleats", name = "Cleats", price = 220, damage = 8, color = Color3.fromRGB(60, 220, 90) },
		{ id = "jump", name = "Jump Shoes", price = 450, damage = 12, color = Color3.fromRGB(255, 230, 60) },
		{ id = "speed", name = "Speed Sneakers", price = 900, damage = 16, color = Color3.fromRGB(60, 200, 255) },
		{ id = "power", name = "Power Boots", price = 1800, damage = 25, color = Color3.fromRGB(255, 70, 70) },
		{ id = "titan", name = "Titan Boots", price = 3600, damage = 35, color = Color3.fromRGB(40, 80, 255) },
		{ id = "neon", name = "Neon Kicks", price = 7500, damage = 50, color = Color3.fromRGB(255, 60, 230) },
		{ id = "golden", name = "Golden Sneakers", price = 15000, damage = 75, color = Color3.fromRGB(255, 200, 40) },
		{ id = "crystal", name = "Crystal Kicks", price = 30000, damage = 100, color = Color3.fromRGB(150, 240, 255) },
		{ id = "thunder", name = "Thunder Boots", price = 60000, damage = 150, color = Color3.fromRGB(170, 90, 255) },
		{ id = "radiant", name = "Radiant Shoes", price = 120000, damage = 250, color = Color3.fromRGB(255, 255, 140) },
	},

	-- Skinler (Lobi sol duvar, ayakkabı rafının yanındaki raf): Win ile alınır, karakter o renge boyanır.
	-- mult = bacak kası kazancı çarpanı (ayakkabı gibi takılı olan geçerlidir, toplanmaz; aura/pet/level çarpanlarıyla çarpılır).
	-- Rebirth ayakkabılar gibi skinleri de sıfırlar. Sadece fantezi renkler var (gerçek ten tonları fiyat/güç sıralamasına girmesin diye).
	Skins = {
		{ id = "mint", name = "Mint", price = 5, mult = 1.1, color = Color3.fromRGB(150, 235, 190) },
		{ id = "lemon", name = "Lemon", price = 15, mult = 1.2, color = Color3.fromRGB(255, 240, 110) },
		{ id = "coral", name = "Coral", price = 40, mult = 1.3, color = Color3.fromRGB(255, 127, 110) },
		{ id = "bubblegum", name = "Bubblegum", price = 90, mult = 1.4, color = Color3.fromRGB(255, 150, 200) },
		{ id = "orange", name = "Orange Pop", price = 200, mult = 1.5, color = Color3.fromRGB(255, 150, 50) },
		{ id = "lime", name = "Lime Zap", price = 450, mult = 1.6, color = Color3.fromRGB(140, 230, 60) },
		{ id = "teal", name = "Ocean Teal", price = 900, mult = 1.8, color = Color3.fromRGB(40, 200, 190) },
		{ id = "sky", name = "Sky Blue", price = 1800, mult = 2, color = Color3.fromRGB(80, 170, 255) },
		{ id = "violet", name = "Violet", price = 3600, mult = 2.2, color = Color3.fromRGB(150, 90, 230) },
		{ id = "ruby", name = "Ruby Red", price = 7000, mult = 2.4, color = Color3.fromRGB(225, 40, 60) },
		{ id = "silver", name = "Silver", price = 14000, mult = 2.6, color = Color3.fromRGB(205, 210, 220) },
		{ id = "gold", name = "Golden", price = 28000, mult = 2.9, color = Color3.fromRGB(255, 200, 40) },
		{ id = "ice", name = "Frozen", price = 56000, mult = 3.2, color = Color3.fromRGB(150, 235, 255) },
		{ id = "magma", name = "Magma", price = 110000, mult = 3.6, color = Color3.fromRGB(255, 90, 20) },
		{ id = "galaxy", name = "Galaxy", price = 220000, mult = 4, color = Color3.fromRGB(70, 45, 150) },
	},

	-- Antrenman alanı (SAĞ duvar, 3 basamakta 4 + 3 + 3 = 10 büyük ped): pede girince karakter otomatik squat yapar ve kazanç o pedin
	-- çarpanıyla çarpılır. Pedler SADECE REBIRTH ile açılır: rebirths = N ise oyuncunun N rebirth'i olunca açılır (0 = ücretsiz).
	-- Her pedde bir antrenör yer tutucusu durur, her antrenörün bir ismi var (trainer; etiketlerde görünür). Özel antrenör modelleri sonra gelecek. Sıra: önce 1. basamak (4), sonra 2. (3), sonra 3. (3).
	Training = {
		RowCounts = { 4, 3, 3 }, -- basamaklardaki ped sayıları (alttan üste)
		-- Üst basamaklara çıktıkça ped, antrenör ve şerit büyür (referans fotoğraftaki gibi); her şeridin ped dizisi RowLength'i doldurur
		RowPadSizes = { 8.5, 11, 13.5 }, -- ped boyutu (stud)
		RowDepths = { 12, 14.5, 17 }, -- şerit derinliği (stud)
		RowLength = 48, -- her şeridin ped dizisinin uzunluğu
		TrainerScales = { 1, 1.25, 1.5 }, -- antrenör boyutu (1 = ~5.3 stud boy)
		Areas = {
			{ id = "green", name = "Green Zone", trainer = "Coach Sprout", mult = 1, rebirths = 0, color = Color3.fromRGB(60, 220, 90) },
			{ id = "blue", name = "Blue Zone", trainer = "Coach Wave", mult = 1.5, rebirths = 1, color = Color3.fromRGB(60, 100, 255) },
			{ id = "red", name = "Red Zone", trainer = "Coach Blaze", mult = 3, rebirths = 3, color = Color3.fromRGB(255, 50, 50) },
			{ id = "orange", name = "Orange Zone", trainer = "Coach Ember", mult = 5, rebirths = 5, color = Color3.fromRGB(255, 150, 30) },
			{ id = "magenta", name = "Magenta Zone", trainer = "Coach Pixel", mult = 9, rebirths = 8, color = Color3.fromRGB(255, 50, 230) },
			{ id = "cyan", name = "Cyan Zone", trainer = "Coach Frost", mult = 18, rebirths = 12, color = Color3.fromRGB(50, 230, 255) },
			{ id = "yellow", name = "Yellow Zone", trainer = "Coach Volt", mult = 36, rebirths = 17, color = Color3.fromRGB(255, 230, 40) },
			{ id = "purple", name = "Purple Zone", trainer = "Coach Nova", mult = 100, rebirths = 24, color = Color3.fromRGB(160, 80, 255) },
			{ id = "rainbow", name = "Rainbow Zone", trainer = "Coach Prism", mult = 250, rebirths = 32, color = Color3.fromRGB(255, 255, 255), rainbow = true },
			{ id = "black", name = "Black Zone", trainer = "Coach Shadow", mult = 999, rebirths = 45, color = Color3.fromRGB(35, 35, 48) },
		},
	},

	-- Petler. mult = bacak kası çarpanına eklenen oran (0.1 = +%10). Hangi yumurtadan çıktıkları aşağıdaki Eggs listesindedir.
	-- Pet nadirliği (çarpanına göre): yumurta açılış ekranında kart rengi ve etiket. maxMult: bu değerin ALTINDAKİ petler bu sınıftadır.
	Rarities = {
		{ name = "Common", maxMult = 0.3, color = Color3.fromRGB(185, 190, 205) },
		{ name = "Rare", maxMult = 0.7, color = Color3.fromRGB(70, 170, 255) },
		{ name = "Epic", maxMult = 1.2, color = Color3.fromRGB(180, 90, 255) },
		{ name = "Legendary", maxMult = 3.5, color = Color3.fromRGB(255, 190, 40) },
		{ name = "Mythic", maxMult = math.huge, color = Color3.fromRGB(255, 70, 140) },
	},
	MaxEquippedPets = 3, -- aynı anda takılı pet sayısı (en güçlüler otomatik takılır)
	MaxOwnedPets = 50,
	Pets = {
		{ id = "cat", name = "Cat", mult = 0.1, color = Color3.fromRGB(255, 190, 120) },
		{ id = "dog", name = "Dog", mult = 0.15, color = Color3.fromRGB(170, 120, 80) },
		{ id = "bunny", name = "Bunny", mult = 0.2, color = Color3.fromRGB(250, 220, 235) },
		{ id = "fox", name = "Fox", mult = 0.35, color = Color3.fromRGB(255, 120, 40) },
		{ id = "panda", name = "Panda", mult = 0.5, color = Color3.fromRGB(235, 235, 235) },
		{ id = "tiger", name = "Tiger", mult = 0.8, color = Color3.fromRGB(255, 170, 40) },
		{ id = "wolf", name = "Wolf", mult = 1.0, color = Color3.fromRGB(140, 150, 170) },
		{ id = "dragon", name = "Dragon", mult = 1.5, color = Color3.fromRGB(180, 60, 255) },
		{ id = "phoenix", name = "Phoenix", mult = 2.0, color = Color3.fromRGB(255, 80, 40) },
		{ id = "unicorn", name = "Unicorn", mult = 3.0, color = Color3.fromRGB(255, 130, 230) },
		{ id = "robot", name = "Robot", mult = 4.0, color = Color3.fromRGB(100, 220, 255) },
		{ id = "galaxy", name = "Galaxy Cat", mult = 6.0, color = Color3.fromRGB(120, 80, 255) },
		{ id = "titan", name = "Titan", mult = 10.0, color = Color3.fromRGB(255, 220, 60) },
	},

	-- Yumurta paneli: "T" tuşu bu seçenekler arasında geçiş yapar (bir seferde kaç yumurta açılacağı)
	EggMultiOptions = { 1, 3, 10 },

	-- Yumurtalar (lobinin arka duvarında): üstündeki pedin üstüne basınca Win karşılığı açılır.
	-- pets = o yumurtadan çıkabilecek petler ve ağırlıkları (büyük sayı = daha sık çıkar). Fiyatlar geçicidir.
	-- color/accent = yumurtanın ana rengi ve benek rengi.
	Eggs = {
		{ id = "starter", name = "Starter Egg", price = 5, color = Color3.fromRGB(90, 190, 255), accent = Color3.fromRGB(255, 220, 60),
			pets = { { id = "cat", weight = 60 }, { id = "dog", weight = 30 }, { id = "bunny", weight = 10 } } },
		{ id = "forest", name = "Forest Egg", price = 50, color = Color3.fromRGB(90, 220, 120), accent = Color3.fromRGB(40, 120, 60),
			pets = { { id = "dog", weight = 40 }, { id = "bunny", weight = 30 }, { id = "fox", weight = 20 }, { id = "panda", weight = 10 } } },
		{ id = "desert", name = "Desert Egg", price = 500, color = Color3.fromRGB(255, 200, 90), accent = Color3.fromRGB(190, 110, 30),
			pets = { { id = "fox", weight = 40 }, { id = "panda", weight = 30 }, { id = "tiger", weight = 20 }, { id = "wolf", weight = 10 } } },
		{ id = "ice", name = "Ice Egg", price = 2500, color = Color3.fromRGB(190, 240, 255), accent = Color3.fromRGB(90, 160, 255),
			pets = { { id = "tiger", weight = 40 }, { id = "wolf", weight = 30 }, { id = "dragon", weight = 20 }, { id = "phoenix", weight = 10 } } },
		{ id = "lava", name = "Lava Egg", price = 10000, color = Color3.fromRGB(255, 90, 50), accent = Color3.fromRGB(255, 220, 60),
			pets = { { id = "dragon", weight = 40 }, { id = "phoenix", weight = 30 }, { id = "unicorn", weight = 20 }, { id = "robot", weight = 10 } } },
		{ id = "galaxy", name = "Galaxy Egg", price = 50000, color = Color3.fromRGB(110, 70, 220), accent = Color3.fromRGB(255, 255, 255),
			pets = { { id = "unicorn", weight = 40 }, { id = "robot", weight = 30 }, { id = "galaxy", weight = 20 }, { id = "titan", weight = 10 } } },
	},

	-- İz (trail) efektleri: karakterin arkasında renkli bir iz bırakır ve yürüme hızını artırır (speed = ek hız, stud/sn).
	-- Win ile alınır (winPrice). robuxPrice + robuxProductId: Robux butonu; robuxProductId 0 ise buton "yakında" olarak kalır.
	-- Gerçek satış için Creator Hub'da Developer Product oluşturup ID'sini robuxProductId'ye yazmak ve sunucuda
	-- MarketplaceService.ProcessReceipt'i bağlamak gerekir (henüz yok). Fiyatlar geçicidir.
	BaseWalkSpeed = 16,
	Trails = {
		{ id = "red", name = "Red Trail", speed = 4, winPrice = 50, robuxPrice = 25, robuxProductId = 0, color = Color3.fromRGB(255, 60, 60) },
		{ id = "orange", name = "Orange Trail", speed = 6, winPrice = 150, robuxPrice = 45, robuxProductId = 0, color = Color3.fromRGB(255, 150, 40) },
		{ id = "yellow", name = "Yellow Trail", speed = 8, winPrice = 400, robuxPrice = 75, robuxProductId = 0, color = Color3.fromRGB(255, 230, 60) },
		{ id = "green", name = "Green Trail", speed = 10, winPrice = 1000, robuxPrice = 120, robuxProductId = 0, color = Color3.fromRGB(70, 220, 90) },
		{ id = "cyan", name = "Cyan Trail", speed = 12, winPrice = 2500, robuxPrice = 180, robuxProductId = 0, color = Color3.fromRGB(60, 220, 255) },
		{ id = "blue", name = "Blue Trail", speed = 14, winPrice = 6000, robuxPrice = 250, robuxProductId = 0, color = Color3.fromRGB(70, 110, 255) },
		{ id = "purple", name = "Purple Trail", speed = 16, winPrice = 15000, robuxPrice = 350, robuxProductId = 0, color = Color3.fromRGB(170, 80, 255) },
		{ id = "pink", name = "Pink Trail", speed = 18, winPrice = 40000, robuxPrice = 500, robuxProductId = 0, color = Color3.fromRGB(255, 100, 200) },
		{ id = "rainbow", name = "Rainbow Trail", speed = 24, winPrice = 100000, robuxPrice = 800, robuxProductId = 0, color = Color3.fromRGB(255, 255, 255), rainbow = true },
	},

	-- Aura efektleri (Backpack > Auras): karakterin etrafında renkli parıltı. mult = bacak kası kazancı çarpanı.
	-- Win (winPrice) ile alınır; Robux butonu robuxProductId 0 iken "yakında" olarak kalır. Fiyatlar geçicidir.
	Auras = {
		{ id = "red", name = "Red Aura", mult = 1.2, winPrice = 1500, robuxPrice = 25, robuxProductId = 0, color = Color3.fromRGB(255, 60, 60) },
		{ id = "green", name = "Green Aura", mult = 1.4, winPrice = 5000, robuxPrice = 65, robuxProductId = 0, color = Color3.fromRGB(70, 220, 90) },
		{ id = "blue", name = "Blue Aura", mult = 1.6, winPrice = 15000, robuxPrice = 105, robuxProductId = 0, color = Color3.fromRGB(70, 130, 255) },
		{ id = "purple", name = "Purple Aura", mult = 1.8, winPrice = 40000, robuxPrice = 175, robuxProductId = 0, color = Color3.fromRGB(170, 80, 255) },
		{ id = "gold", name = "Gold Aura", mult = 2.2, winPrice = 90000, robuxPrice = 275, robuxProductId = 0, color = Color3.fromRGB(255, 205, 50) },
		{ id = "rainbow", name = "Rainbow Aura", mult = 3.0, winPrice = 200000, robuxPrice = 450, robuxProductId = 0, color = Color3.fromRGB(255, 255, 255), rainbow = true },
	},

	-- Oyun süresi ödülleri (Gifts > Playtime Rewards): oyuna girdikten time saniye sonra alınabilir.
	-- kind: muscle (amount kadar bacak kası), wins (amount Win), pet (pet id), boostMuscle / boostWins (BoostMinutes dk 2x).
	-- Ödüller her oyuna girişte yeniden başlar (kayıt edilmez). SkipRobux: "Unlock" butonları Robux yer tutucusu.
	BoostMinutes = 10,
	GiftRewards = {
		{ time = 60, kind = "muscle", amount = 300 },
		{ time = 150, kind = "wins", amount = 10 },
		{ time = 270, kind = "muscle", amount = 1000 },
		{ time = 420, kind = "wins", amount = 50 },
		{ time = 600, kind = "pet", pet = "dragon" },
		{ time = 780, kind = "muscle", amount = 5000 },
		{ time = 1080, kind = "boostMuscle" },
		{ time = 1380, kind = "wins", amount = 1000 },
		{ time = 1800, kind = "boostWins" },
		{ time = 2400, kind = "pet", pet = "phoenix" },
	},
	GiftUnlockAllRobux = 219,
	GiftUnlockNextRobux = 29,
}
