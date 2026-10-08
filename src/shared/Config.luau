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
	-- Hareket (animasyon) boştayken gelen tıklama bir hareket başlatır; duvara HASAR bu hareketle gelir: squat'ta hareket BİTTİĞİNDE, tekmede ayağın duvara DEĞDİĞİ anda (hareket süresinin MoveContact oranı).
	-- Eskiden tekmede de hareket bitince verilirdi: ayak 0.2 sn'de değiyor, duvar 0.4 sn + ping sonra kırılıyor, ses ve görüntü tekmeden geç kalıyordu. Süreler saniye cinsindendir.
	MoveDuration = { Kick = 0.4, Squat = 0.5 },
	-- HER TIKLAMA bacak kasını ANINDA verir (sahibi 'her clickte leg power alayım, squat'ın bitmesini beklemesin' dedi; hareketin bitmesi beklenmez).
	-- Hareket (animasyon) ve duvara hasar ise sadece hareket boştayken başlar: bir hareket sürerken gelen tıklama kas verir ama yeni hareket/hasar başlatmaz.
	-- Hile önlemi: sunucu tıklamaları jeton kovasıyla sınırlar (saniyede en çok PerSecond, ani seri için Burst). Auto Click ve antrenman alanındaki otomatik squat hareket başına bir tıklamadır.
	ClickLimit = { PerSecond = 12, Burst = 6 },
	-- AUTO CLICK düğmesi açıkken (antrenman pedinde, koçun yanında da) istemci SERİ SERİ tıklar: saniyede PerSecond tıklama (elle hızlı tıklamayla aynı), her biri anında kas verir.
	-- Sunucu sınırının (ClickLimit.PerSecond) biraz altında tutulur ki otomatik tıklamalar reddedilmesin. Antrenman pedinde Auto Click KAPALIYKEN pedin kendi otomatik squat'ı hareket başına bir tıklamadır.
	AutoClick = { PerSecond = 10 },
	MoveContact = { Kick = 0.5 }, -- Moves.luau'daki tekme animasyonunda bacak 0.20 / 0.40 = %50'de tam uzanır (animasyonu değiştirirsen bunu da ayarla)

	-- Kayıt sistemi
	Save = {
		StoreName = "PlayerData_v1", -- ismi değiştirirsen herkesin kaydı sıfırlanır!
		AutosaveInterval = 30, -- saniye (ayrıca Win/satın alma/pet sonrası da hemen kaydedilir)
	},

	-- Shop (sol menüdeki Shop butonu): Robux ile alınan Developer Product'lar. productId: Creator Hub > Monetization > Developer Products'ta
	-- oluşturulan ürünün ID'si; 0 = henüz yok, kart "Coming soon" gösterir. Satın alma sunucuda ProcessReceipt ile doğrulanır
	-- (server/Purchases): aynı satın alma iki kez ödül vermez. kind: boostLuck / boostMuscle / boostWins / boostRainbow (iksirler ARTIK Shop.Potions listesindedir), petSpace (amount ek pet envanter yeri; Pets menüsündeki çanta + işareti bu pencereyi açar), wins (amount Win),
	-- stageWins (stage. aşamanın Win ödülü kadar), moves (amount hareketlik kas).
	-- FİYAT KURALI (sahibi 2026-10-09: 'ucuz olsun, en pahalı şey 150 Robux'u geçmesin'): bütün Robux fiyatları (Shop ürünleri, iksirler, iz/aura, Rebirth SKIP, Offline DOUBLE, Gifts kilidi, VIP game pass) en çok 150'dir; tools/mocktest/tests/pricetest.luau denetler.
	Shop = {
		Products = {
			{ id = "petSpace25", name = "Pet Space", detail = "+25 pet slots", icon = "🎒", kind = "petSpace", amount = 25, robux = 49, productId = 0, color = Color3.fromRGB(235, 70, 70) },
			-- HIZLI SATIN ALMA (quick = true): Auto Click'in solundaki '+1K Power / +10K Power / +100K Power' düğmeleri (sahibi referans görselle istedi); amount kadar tıklamalık bacak kası (kazanç x amount) anında verilir. Fiyatlar geçicidir
			{ id = "power1k", name = "+1K Power", detail = "1,000 squats of leg power", icon = "🦵", kind = "moves", amount = 1000, robux = 15, productId = 0, quick = true, color = Color3.fromRGB(255, 45, 140) },
			{ id = "power10k", name = "+10K Power", detail = "10,000 squats of leg power", icon = "🦵", kind = "moves", amount = 10000, robux = 49, productId = 0, quick = true, color = Color3.fromRGB(232, 32, 112) },
			{ id = "power100k", name = "+100K Power", detail = "100,000 squats of leg power", icon = "🦵", kind = "moves", amount = 100000, robux = 149, productId = 0, quick = true, color = Color3.fromRGB(180, 20, 70) },
			{ id = "winsSmall", name = "Win Pack", detail = "Stage 8 reward", icon = "💰", kind = "stageWins", stage = 8, robux = 25, productId = 0, color = Color3.fromRGB(70, 210, 90) },
			{ id = "winsBig", name = "Mega Win Pack", detail = "Stage 12 reward", icon = "💎", kind = "stageWins", stage = 12, robux = 99, productId = 0, color = Color3.fromRGB(190, 90, 255) },
		},
		-- İKSİR ÜRÜNLERİ (Shop > Potions bölümü): her iksir (Config.Potions.List) x süre. id = iksir id + dakika (luck15, luck60, muscle15 ...).
		-- Çarktan / Gifts'ten / günlük görev bonusundan çıkan iksirler ENVANTERE girer (kayıtlı) ve burada fiyat yerine 'USE xN' yazar; envanterde yoksa fiyat yazar,
		-- Robux ile alınan iksir hemen içilir. productId: Creator Hub'da oluşturulan Developer Product (0 = 'coming soon').
		Potions = {
			{ id = "luck15", potion = "luck", minutes = 15, robux = 29, productId = 0 },
			{ id = "luck60", potion = "luck", minutes = 60, robux = 89, productId = 0 },
			{ id = "muscle15", potion = "muscle", minutes = 15, robux = 19, productId = 0 },
			{ id = "muscle60", potion = "muscle", minutes = 60, robux = 59, productId = 0 },
			{ id = "wins15", potion = "wins", minutes = 15, robux = 19, productId = 0 },
			{ id = "wins60", potion = "wins", minutes = 60, robux = 59, productId = 0 },
			{ id = "rainbow15", potion = "rainbow", minutes = 15, robux = 49, productId = 0 },
			{ id = "rainbow60", potion = "rainbow", minutes = 60, robux = 149, productId = 0 },
		},
	},

	-- Çevrimdışı kazanç (Offline Earnings): oyundan uzakta geçen süre için bacak kası birikir; girişte açılan pencerede CLAIM'e basınca verilir.
	-- Süre MaxHours ile sınırlanır, MinSeconds'tan kısa aralar sayılmaz. Kazanç = (uzakta geçen saniye / squat süresi) x tıklama başı kazanç x Rate
	-- (Rate = aktif oynamanın yüzdesi: 0.02 = %2). Alınmayan kazanç kayıtlı kalır. Kayıt gerektirir (yayınlanmış oyun + API); Studio'da DEV > Offline 3h ile denenir.
	-- DoubleProductId: pencerenin 'DOUBLE IT!' butonu (Robux ile bekleyen kazancın 2 katı). Creator Hub'da Developer Product oluşturup ID'sini yaz;
	-- 0 iken buton 'COMING SOON' der. DoubleRobux sadece butonda gösterilen fiyattır (gerçek fiyatı Developer Product belirler).
	Offline = { Enabled = true, Rate = 0.02, MaxHours = 8, MinSeconds = 300, DoubleProductId = 0, DoubleRobux = 19 },

	-- Sesler (client/Sfx). id: "rbxasset://sounds/..." (Roblox'la gelen hazır sesler) ya da "rbxassetid://123456" (Creator Store'dan seçtiğin ses).
	-- id = "" ise o olay sessiz kalır. volume 0-1, speed: { en yavaş, en hızlı } çalma hızı (her çalışta rastgele; ton çeşitliliği).
	-- Aşağıdakiler geçici: Roblox'un kendi hazır sesleri. Daha güzel sesler için Creator Store'dan ses bulup id'leri değiştir.
	Sounds = {
		-- Vücut büyümesi (her level atlayışında karakter büyür): Grow kısa bir güçlenme sesi, GrowBig yeni kas çıkınca/irileşince çalan daha güçlü ses.
		-- Squat sesi YOK (gecikiyordu, sahibi kaldırttı). Tekme sesi VAR ama sunucudan gelmez: istemci ayak duvara değdiği anda (Config.MoveContact) kendisi çalar,
		-- yani ağ gecikmesi yok. pick = "first": yüklenebilen ilk ses çalar (ses her seferinde aynı kalsın).
		-- startAt (isteğe bağlı): sesin başındaki sessizliği atlamak için saniye; ses dosyasının başında boşluk varsa (gecikmeli duyuluyorsa) artır.
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
		Kick = {
			ids = { "rbxassetid://138488212707530", "rbxassetid://140119737822165", "rbxassetid://119801699610817" }, -- 'Kick Impact', 'Kick Hit', 'hit_kick2' (Creator Store, kısa)
			fallback = "rbxasset://sounds/action_footsteps_plastic.mp3",
			pick = "first",
			volume = 0.4,
			speed = { 0.95, 1.08 },
			gap = 0.15,
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

	-- Arka plan müziği (sağ alttaki teyp, client/MusicPlayer): tracks SIRAYLA çalar, liste bitince baştan başlar (sonsuz döngü).
	-- Yüklenemeyen parça atlanır. Hepsi Creator Store'dan ücretsiz, sözsüz, neşeli parçalar (~22 dk); name teypte kayan yazıyla görünür.
	-- Ses kademeli ayarlanır: kademe x volumeStep = ses (0 = sessiz, defaultLevel başlangıç kademesi). "Sounds" anahtarı kapatınca ses 0 olur.
	-- Müzik sesi efektleri bastırmasın diye varsayılan düşük tutulur (4 x 0.045 = 0.18).
	Music = {
		maxLevel = 10,
		defaultLevel = 4,
		volumeStep = 0.045,
		tracks = {
			{ id = "rbxassetid://93310229093873", name = "Green Hill Cubes" }, -- 2:05
			{ id = "rbxassetid://103462270700363", name = "Blend and Bounce" }, -- 2:53
			{ id = "rbxassetid://84770156902104", name = "Mining Fun" }, -- 2:11
			{ id = "rbxassetid://101506812412180", name = "Primary Color Party" }, -- 2:18
			{ id = "rbxassetid://95159768281123", name = "Craft & Jump" }, -- 2:00
			{ id = "rbxassetid://134096897250664", name = "Gradient Hopscotch" }, -- 2:09
			{ id = "rbxassetid://127582244484162", name = "Sunny Mine Day" }, -- 2:02
			{ id = "rbxassetid://113182399122383", name = "Color Wheel Spin" }, -- 2:13
			{ id = "rbxassetid://87764582879259", name = "Pixel Picnic" }, -- 2:10
			{ id = "rbxassetid://86374052601075", name = "Swatch Dance" }, -- 2:16
		},
	},

	-- Arkadaş bonusu: aynı sunucudaki her arkadaş için bacak kası kazancına +PercentPerFriend yüzdesi eklenir (en çok MaxFriends arkadaş sayılır).
	-- Arkadaşlığı Roblox söyler (server/FriendBonus). Oyuncuya arkadaşını oyuna çağırtmak için; sağ taraftaki FRIEND BONUS kutusunda görünür.
	Friends = { Enabled = true, PercentPerFriend = 10, MaxFriends = 5 },

	-- Pet Index (koleksiyon defteri, sağ üstteki kitap simgesi): sahip olunan her YENİ pet türü kalıcı olarak keşfedilir (pet silinse de kalır);
	-- keşfedilen her tür bacak kası kazancına +PercentPerPet yüzdesi ekler (13 tür = en çok +%13). Küçük tutuldu, dengeyi bozmasın diye.
	Index = { PercentPerPet = 1 },

	-- Oyuncu ayarları (sol menüdeki Settings penceresi, client/SettingsPanel). key = Player özniteliği: false kapalı, yoksa/true açık.
	-- Sunucu bu anahtarları kaydeder (PlayerStats.setSetting; listede olmayan anahtar kabul edilmez). Yeni ayar eklemek için buraya satır ekle
	-- ve ilgili yerde özniteliğe bak.
	Settings = {
		{ key = "SfxOn", name = "Sound effects", detail = "Wall breaks, growing, buying..." },
		{ key = "MusicOn", name = "Music", detail = "Background music (tape at the bottom right)" },
		{ key = "ShowGain", name = "Gain numbers", detail = "The +N that pops up on your screen" },
		{ key = "CameraShake", name = "Screen shake", detail = "Shake when walls break" },
		{ key = "NameTags", name = "Name tags", detail = "Power and name above players" },
	},

	-- Sol menüdeki ve sayaçtaki ikonlar. Roblox'a yüklenmiş görsellerin "rbxassetid://..." değeri; BOŞ ikon emoji olarak görünür.
	-- Hazır, şeffaf arka planlı görseller assets/icons/ klasöründe (shop, rebirth, settings, backpack, pets, gifts: 256x256 PNG).
	-- Studio'da Asset Manager > Bulk Import ile yükle, çıkan ID'leri buraya yaz.
	-- Arayüz ölçeği: ana ekran arayüzü (HUD ve pencereler) ekran YÜKSEKLİĞİYLE orantılı büyür/küçülür (client/init.client, UIScale).
	-- scale = ekran yüksekliği / ReferenceHeight, MinScale ile MaxScale arasına sıkıştırılır. Sahibi 'arayüz referans oyuna göre küçük' dedi: referans oyunun
	-- sol butonları, level çubuğu ve sayaçları bu oranda büyük ölçüldü (bu bilgisayarda ekran yüksekliği ~862 iken 1.3). Daha büyük istersen ReferenceHeight'i küçült.
	-- Sağ üst daireler ayrı ScreenGui'dedir (RightHud.CornerGui), bu ölçekten ETKİLENMEZ (referanstakilerden zaten büyüktü).
	UI = { ReferenceHeight = 663, MinScale = 0.75, MaxScale = 1.75 },

	Icons = {
		Quests = "", -- sağ üstteki günlük görevler düğmesinin simgesi (boşken 📜 emojisi)
		Index = "", -- sağ üstteki Pet Index düğmesinin simgesi (görsel yüklenince ID; boşken 📖 emojisi)
		Stats = "", -- sağ üstteki Stats düğmesinin simgesi (boşken 📊 emojisi)
		Trash = "rbxassetid://72909566398443", -- Pets menüsündeki çöp kutusu simgesi: sahibinin yüklediği gri çöp kutusu (assets/icons/trash.png, Image türü, doğrulandı). Boş bırakılırsa aynı görünümde Frame'lerden çizilir
		WheelFace = "", -- günlük çarkın hazır yüzü (daire şeklinde, şeffaf köşeli PNG: tools/make_wheel_image.py -> assets/icons/wheel.png). Yüklenince Image ID yazılır; boşken yüz arayüz nesneleriyle çizilir
		Wins = "", -- sol üstteki Win sayacının kupa simgesi (görsel yüklenince ID yazılır; boşken 🏆 emojisi)
		Friends = "rbxassetid://139194631320002", -- sağ üstteki arkadaş bonusu simgesi: sahibinin yüklediği 'friends' görseli (Image türü, doğrulandı). Boş bırakılırsa 👥 emojisi
		LegMuscle = "rbxassetid://81118324194991", -- Offline Earnings penceresindeki büyük bacak kası simgesi: sahibinin yüklediği "leg-emoji-clipart-xl" görseli (Image türü, doğrulandı). Boş bırakılırsa 🦵 emojisi görünür
		Shop = "rbxassetid://88209777338839",
		Rebirth = "rbxassetid://92894421841396",
		Settings = "rbxassetid://82994218844234",
		Backpack = "rbxassetid://139523703798238",
		Pets = "rbxassetid://122036590660446",
		Gifts = "rbxassetid://107783706209695",
		Potions = { luck = "rbxassetid://104522704182798", muscle = "rbxassetid://114736473334553", wins = "rbxassetid://91281796981948", rainbow = "rbxassetid://92804106754602" }, -- iksir görselleri (assets/icons/potion_<id>.png, tools/blender/potions.py): sahibinin yüklediği Image'lar, doğrulandı. Boş bırakılırsa kodla çizilen şişe (UIStyle.potionIcon)
		Click = "rbxassetid://138038526402176", -- Auto Click düğmesinin ortasındaki (yazının arkasında) tıklama simgesi: sahibinin yüklediği görsel (Image türü, doğrulandı). Boş bırakılırsa simge çizilmez
		Trails = "rbxassetid://127034765324159", -- Backpack > Trails düğmesinin simgesi: sahibinin yüklediği görsel (assets/icons/trails.png, Image türü, doğrulandı). Boş bırakılırsa ✨ emojisi
		Auras = "rbxassetid://80241008587441", -- Backpack > Auras düğmesinin simgesi: sahibinin yüklediği görsel (assets/icons/auras.png, Image türü, doğrulandı). Boş bırakılırsa 🔮 emojisi
	}, -- sahibinin yüklediği görseller (hepsi Image türünde, doğrulandı)
	-- Menü düğmelerindeki simge kenarı (piksel, varsayılan 56). Görsel kenarlara kadar doluysa küçült: Auras alevi 56'da düğmeden taşıyordu (sahibi söyledi).
	IconSizes = { Auras = 44 },

	-- Eğitim (tutorial): SADECE yeni oyuncuya gösterilir (üstteki yönerge yazısı ve yol gösterici çizgi), oyuncu İLK SKİNİNİ alana kadar sürer. Kayıtta 'TutorialDone' tutulur;
	-- eski kayıtlarda ilerleme varsa (kas, Win, rebirth, eşya, pet, skin) eğitim bitmiş sayılır. Adımlar: duvarları kır, Win pedine bas, ilk skin fiyatına (Config.Skins[1]) yetince skin rafına git ve al.
	-- Çizgi ve yazı client/Guide ve init.client'tadır.
	-- İlk adım: oyun başında 'Click to squat and get stronger! (0/30)': ClickGoal kez tıklayınca (hareket başlayınca, sunucu sayar, kayıtlı) oyuncu duvara yönlendirilir.
	Tutorial = { ClickGoal = 30 },

	-- Kameranın en fazla ne kadar uzaklaşabileceği (stud). Koridorun dışından içeriyi görmeyi engeller.
	CameraMaxZoom = 40,

	-- Işıklandırma ve ışık efekti (server/EnvironmentService). Kapalı mekanda aydınlığı ortam ışığı verir (karanlık/mavi hava istenmedi).
	-- PanelGlow: lobideki tavan panellerinin çevresinde SADECE tavan yüzeyinde yumuşak bir hale (üst üste bindirilmiş şeffaf katmanlar);
	-- aşağıya inen parıltı yok. Size = hale genişliği (stud; panel 7), Layers = katman sayısı (çok = daha yumuşak), Alpha = her katmanın
	-- görünürlüğü (0.05 = %5; tavan fazla beyazlaşırsa düşür).
	-- Bloom: TÜM EKRANI saran parıltı efekti. Denendi, bu parlak sahnede her şeyi beyaza boğdu ve aşağıya kadar indi: KAPALI. Açarsan
	-- Threshold'u yüksek tut (>= 1.5) ve Intensity'yi düşük (<= 0.2); denemeden açma.
	Lighting = {
		Brightness = 2,
		Exposure = 0,
		Ambient = Color3.fromRGB(172, 175, 196),
		-- Panel rengi: Neon malzeme rengi ne kadar açıksa o kadar göz alır (saf beyaz kör ediyordu); tavan rengine yakın, yumuşak bir ton.
		-- Daha parlak istersen PanelColor'ı beyaza doğru aç, göz alırsa tavan rengine (150,160,215) doğru kapat. LightBrightness = nokta ışığı gücü.
		PanelColor = Color3.fromRGB(205, 212, 240),
		PanelLightBrightness = 0.25,
		PanelGlow = { Enabled = true, Size = 14, Layers = 6, Alpha = 0.03 },
		Bloom = { Enabled = false, Intensity = 0.2, Size = 16, Threshold = 1.5 },
		Color = { Saturation = 0.1, Contrast = 0.06 }, -- hafif canlı renk (ColorCorrection); Saturation = 0 ve Contrast = 0 ise etkisiz
	},

	-- Başlangıç lobisi: spawn'ın bulunduğu geniş kapalı salon
	Lobby = {
		HalfWidth = 62, -- salonun yarı genişliği (stud; salon 124 x 130, referans fotoğraflardaki gibi derli toplu). Sol duvar ayakkabılar, sağ duvar antrenman alanı, arka duvar yumurtalar, ön duvar koridor
		BackZ = 65, -- salonun arka duvarının Z'si (ön duvar koridor girişidir; spawn tam ortadadır)
		Height = 36, -- salonun yüksekliği (koridordan yüksek)
		SpawnPadSize = 8, -- klasik Roblox doğma yeri (beyaz zemin, siyah patlama deseni) kenar uzunluğu; klasiği 6, salon geniş olduğu için 8
		-- Sol duvardaki raflar: duvar boyunca Z konumu (+ arka duvara/yumurtalara doğru). Her raf rampalarıyla ~51 stud yer kaplar.
		ShoeShelfZ = -36.75, -- ayakkabı rafı: koridor girişi tarafına yaslı (her raf rampalarıyla 50.5 stud, giriş duvarına 3 stud boşluk)
		SkinShelfZ = 15.75, -- skin rafı: ayakkabı rafının hemen yanında (aralarında 2 stud). Sol duvarın arka ucu (z > 41) yeni şeyler için boş
		-- Sıralama panoları sol arka köşede DUVARA YASLI DEĞİL, bağımsız stand olarak durur (sahibi referans görselle 'duvarda olmasın' dedi): stand merkezi (LeaderboardX, LeaderboardZ),
		-- LeaderboardAngle: standın lobi ortasına doğru kaç derece döndüğü. Skin rafı z = 41'de biter, arka duvar z = 65; sütunlarla birlikte stand z 43 - 64 arasını kaplar.
		LeaderboardX = -50,
		LeaderboardZ = 53.5,
		LeaderboardAngle = 28,
		-- Günlük çark: SAĞ ARKA köşede (arka duvar ile antrenman alanının arasındaki boş köşe; sahibi Studio görüntüsünde 'bu köşeye koy' dedi). Sağ duvar x = 62, arka duvar z = 65,
		-- yumurta standı x = 27'de biter, antrenman alanı z = 23'te biter; çark (kapı çerçevesiyle ~9 stud yarıçaplı) buraya sığar. WheelFaceX/Z: çarkın baktığı nokta (lobinin ortası).
		WheelX = 47,
		WheelZ = 46,
		WheelFaceX = 0,
		WheelFaceZ = 0,
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
		-- Bir aşamadaki 5 duvarın canı kendi içinde de artar (sahibi: 25, 30, 40, 50, 60 gibi): her duvarın canı = aşama canı x GroupHealthSteps[sırası].
		-- 1. aşama 25, 30, 40, 50, 60; 2. aşama 250, 300, 400, 500, 600 ... Dengelemesi sonra yapılacak (sahibi 'dengelemeyi sonra yaparız' dedi). Taşan hasar yine aşama sonunu geçmez.
		GroupHealthSteps = { 1, 1.2, 1.6, 2, 2.4 },
		HealthGrowthAfter = 4.5, -- 4. grup 3000 x 5 = 15000 ... (12 iken Win ödülleri çok geç yetişiyordu; tools/simulate.py)

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

		-- Son aşamanın (20.) sonundaki bitiş duvarına konan tabelanın yazısı (WallService, 100. duvara DEĞİL): yeni dünya/aşamalar gelene kadar 'COMING SOON'. nil ya da boş yapılırsa tabela kalkar.
		FinalWallText = "COMING SOON",

		-- Her aşamanın duvar TEMASI (20 aşama, ZAYIFTAN GÜÇLÜYE: ilk aşama en zayıf, sondan bir önceki Bedrock, son Blackhole). Sıra oyuncunun ilerleme sırasıdır;
		-- isim duvarın üstünde yazar, renk duvarın, koridorun yan duvar/tavan renginin ve parçacıkların temelidir. Alanlar:
		--   name, color (tema rengi: koridor, parçacık, lego parçaları), accent (parıltı/parçacık ikinci rengi), reflect (parlaklık, metal ve mücevher için),
		--   material (duvarın GERÇEK 3B malzemesi, Enum.Material adı: Wood Brick = WoodPlanks, Clay = Brick, Stone = Cobblestone, metaller Metal/CorrodedMetal/DiamondPlate/Foil,
		--     mücevherler Glass, Meteor = CrackedLava, Bedrock = Basalt, Blackhole = Neon), materialColor (malzemeye uygulanan renk; yoksa color. Lav/bazalt dokusu koyu renkle ölür, o yüzden açık verilir),
		--     transparency (cam duvarın saydamlığı: mücevher duvarlarının arkası hafif görünür),
		--   fx (kırılma parçacık ailesi: puff toz/kağıt, chips kırıntı, sparks kıvılcım, gems parıltı, embers kor, implode içeri çekilme; client/Juice),
		--   decor (tuğla yüzüne eklenen süs, yoksa yok: lines defter çizgisi, shine metal parıltısı, facet mücevher yüzü, swirl girdap; ahşap/taş/lav zaten malzemesinden dokulu; client/WallClient),
		--   ambient (duvar sağlamken etrafında dolaşan parçacık: sparkle, embers, implode; yoksa yok).
		-- ('Lego' markası bilerek yazılmadı: oyunda marka adı kullanmak Roblox'ta sorun çıkarabilir; 'Brick' lego tuğlasının genel adıdır.)
		-- Aşama sayısı (Count / GroupSize = 20) ile aynı olmalı.
		Themes = {
			{ name = "Paper Brick", color = Color3.fromRGB(238, 232, 214), accent = Color3.fromRGB(255, 255, 255), material = "SmoothPlastic", fx = "puff", decor = "lines" },
			{ name = "Cardboard Brick", color = Color3.fromRGB(190, 142, 92), accent = Color3.fromRGB(228, 188, 134), material = "Fabric", fx = "puff" },
			{ name = "Wood Brick", color = Color3.fromRGB(142, 92, 50), accent = Color3.fromRGB(204, 150, 88), material = "WoodPlanks", fx = "chips" },
			{ name = "Clay Brick", color = Color3.fromRGB(200, 98, 62), accent = Color3.fromRGB(240, 150, 110), material = "Brick", fx = "puff" },
			{ name = "Stone Brick", color = Color3.fromRGB(136, 140, 150), accent = Color3.fromRGB(204, 208, 218), material = "Cobblestone", fx = "chips" },
			{ name = "Copper Brick", color = Color3.fromRGB(196, 112, 66), accent = Color3.fromRGB(255, 190, 130), material = "Metal", reflect = 0.12, fx = "sparks", decor = "shine" },
			{ name = "Iron Brick", color = Color3.fromRGB(104, 110, 124), accent = Color3.fromRGB(190, 200, 222), material = "CorrodedMetal", reflect = 0.1, fx = "sparks", decor = "shine" },
			{ name = "Steel Brick", color = Color3.fromRGB(158, 172, 192), accent = Color3.fromRGB(235, 245, 255), material = "DiamondPlate", reflect = 0.2, fx = "sparks", decor = "shine" },
			{ name = "Silver Brick", color = Color3.fromRGB(204, 210, 222), accent = Color3.fromRGB(255, 255, 255), material = "Foil", reflect = 0.25, fx = "sparks", decor = "shine" },
			{ name = "Gold Brick", color = Color3.fromRGB(246, 196, 44), accent = Color3.fromRGB(255, 240, 150), material = "Foil", reflect = 0.25, fx = "sparks", decor = "shine", ambient = "sparkle" },
			{ name = "Ruby Brick", color = Color3.fromRGB(214, 36, 64), accent = Color3.fromRGB(255, 130, 150), material = "Glass", transparency = 0.15, reflect = 0.1, fx = "gems", decor = "facet", ambient = "sparkle" },
			{ name = "Sapphire Brick", color = Color3.fromRGB(40, 92, 228), accent = Color3.fromRGB(140, 190, 255), material = "Glass", transparency = 0.15, reflect = 0.1, fx = "gems", decor = "facet", ambient = "sparkle" },
			{ name = "Emerald Brick", color = Color3.fromRGB(30, 184, 96), accent = Color3.fromRGB(140, 255, 190), material = "Glass", transparency = 0.15, reflect = 0.1, fx = "gems", decor = "facet", ambient = "sparkle" },
			{ name = "Amethyst Brick", color = Color3.fromRGB(156, 84, 222), accent = Color3.fromRGB(225, 170, 255), material = "Glass", transparency = 0.15, reflect = 0.1, fx = "gems", decor = "facet", ambient = "sparkle" },
			{ name = "Diamond Brick", color = Color3.fromRGB(144, 228, 250), accent = Color3.fromRGB(255, 255, 255), material = "Glass", transparency = 0.25, reflect = 0.3, fx = "gems", decor = "facet", ambient = "sparkle" },
			{ name = "Titanium Brick", color = Color3.fromRGB(74, 96, 122), accent = Color3.fromRGB(150, 185, 225), material = "Metal", reflect = 0.2, fx = "sparks", decor = "shine" },
			{ name = "Obsidian Brick", color = Color3.fromRGB(34, 26, 50), accent = Color3.fromRGB(150, 90, 255), material = "Glass", reflect = 0.35, fx = "gems", decor = "shine", ambient = "sparkle" },
			{ name = "Meteor Brick", color = Color3.fromRGB(112, 66, 48), accent = Color3.fromRGB(255, 150, 40), material = "CrackedLava", materialColor = Color3.fromRGB(255, 236, 222), fx = "embers", ambient = "embers" },
			{ name = "Bedrock Brick", color = Color3.fromRGB(66, 66, 74), accent = Color3.fromRGB(150, 150, 172), material = "Basalt", materialColor = Color3.fromRGB(140, 140, 150), fx = "chips" },
			{ name = "Blackhole Brick", color = Color3.fromRGB(14, 10, 26), accent = Color3.fromRGB(170, 80, 255), material = "Neon", materialColor = Color3.fromRGB(46, 14, 92), fx = "implode", decor = "swirl", ambient = "implode" },
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
	-- Fiyatlar (Win) skin fiyatlarıyla AYNIDIR (sahibi istedi: i. ayakkabı = i. skin fiyatı: 5, 15, 40, 90, 200, 450, 900, 1.8K, 3.6K, 7K, 14K, 28K, 56K, 110K, 220K); biri değişirse ötekini de değiştir. GEÇİCİDİR, ekonomi oturunca birlikte ayarlanacak.
	MaxGlowShoeId = "neon", -- ayakkabı parlaklığı bu ayakkabıya (Neon Kicks) kadar artar, daha güçlüleri aynı parlaklıkta kalır
	-- Ayakkabı parlaklığı (sahibi 'bütün ayakkabıların parlaklığını kıs' dedi; eskiden renk %55-%87, ayak ışığı 0.4-2.6 parlaklık / 5-16 menzildi, hepsi yaklaşık yarıya indi).
	-- Parlaklık güce göre artar (ShoeModel.tier, MaxGlowShoeId'de durur). Daha da kısmak için değerleri küçült, açmak için büyüt.
	ShoeGlow = {
		ColorBase = 0.33, -- en zayıf ayakkabının neon rengi (renk x oran; 1 = tam parlak)
		ColorGain = 0.3, -- en güçlü parlaklıktaki (Neon Kicks) ayakkabıya eklenen oran: en güçlüsü ~0.54
		FootLightBrightness = { 0.15, 1.5 }, -- ayaktaki ışık: en zayıf, tier = 1 (Neon Kicks'te ~1.1)
		FootLightRange = { 4, 10 },
		ShelfLightScale = 0.5, -- raftaki ayakkabı postamentinin ışığı ve parıltı parçacıkları bu oranda kısılır
		-- EN GÜÇLÜ ayakkabı (listenin sonu) kendini belli etsin diye biraz daha parlaktır; kör edecek kadar değil (rengi ~0.64, ayak ışığı ~1.7 parlaklık)
		TopBonus = { Color = 0.1, LightBrightness = 0.6, LightRange = 2 },
	},

	-- En güçlü ayakkabılar yürürken arkalarında parçacık izi bırakır (Golden Sneakers, Crystal Kicks, Thunder Boots, Radiant Shoes). Parçacıklar ayakkabının renginde,
	-- ayaklardan geriye doğru çıkar ve sadece yürürken/koşarken akar. Count: kaç ayakkabı (listenin sonundan), Rate/Size: zayıftan güçlüye bu ayakkabılar için sn başına parçacık ve boyut.
	ShoeTrail = {
		Count = 4,
		Rate = { 8, 12, 17, 24 },
		Size = { 0.55, 0.65, 0.8, 1.0 },
	},
	Items = {
		{ id = "oldsneakers", name = "Old Sneakers", price = 5, damage = 1.5, color = Color3.fromRGB(170, 255, 70) },
		{ id = "canvas", name = "Canvas Shoes", price = 15, damage = 2, color = Color3.fromRGB(120, 170, 255) },
		{ id = "running", name = "Running Shoes", price = 40, damage = 3, color = Color3.fromRGB(255, 140, 60) },
		{ id = "trail", name = "Trail Boots", price = 90, damage = 4, color = Color3.fromRGB(0, 230, 170) },
		{ id = "hightops", name = "High-Tops", price = 200, damage = 6, color = Color3.fromRGB(255, 70, 160) },
		{ id = "cleats", name = "Cleats", price = 450, damage = 8, color = Color3.fromRGB(60, 220, 90) },
		{ id = "jump", name = "Jump Shoes", price = 900, damage = 12, color = Color3.fromRGB(255, 230, 60) },
		{ id = "speed", name = "Speed Sneakers", price = 1800, damage = 16, color = Color3.fromRGB(60, 200, 255) },
		{ id = "power", name = "Power Boots", price = 3600, damage = 25, color = Color3.fromRGB(255, 70, 70) },
		{ id = "titan", name = "Titan Boots", price = 7000, damage = 35, color = Color3.fromRGB(40, 80, 255) },
		{ id = "neon", name = "Neon Kicks", price = 14000, damage = 50, color = Color3.fromRGB(255, 60, 230) },
		{ id = "golden", name = "Golden Sneakers", price = 28000, damage = 75, color = Color3.fromRGB(255, 200, 40) },
		{ id = "crystal", name = "Crystal Kicks", price = 56000, damage = 100, color = Color3.fromRGB(150, 240, 255) },
		{ id = "thunder", name = "Thunder Boots", price = 110000, damage = 150, color = Color3.fromRGB(170, 90, 255) },
		{ id = "radiant", name = "Radiant Shoes", price = 220000, damage = 250, color = Color3.fromRGB(255, 255, 140) },
	},

	-- Skinler (Lobi sol duvar, ayakkabı rafının yanındaki raf): Win ile alınır, karakter o renge boyanır.
	-- bonus = tıklama başı bacak kası kazancına eklenen SABİT sayı ('+100 Power'; çarpan DEĞİL, sahibi çarpan gibi yazılmasını istemedi). Takılı olan geçerlidir, toplanmaz.
	-- Pet/level/rebirth/aura çarpanlarından SONRA eklenir, süreli 2x güçlendirmeyle, arkadaş ve Index yüzdeleriyle çarpılır (PlayerStats.refresh). Sabit sayı olduğu için
	-- oyun ilerledikçe (çarpanlar büyüdükçe) etkisi azalır; rebirth skinleri zaten sıfırlar, her turda yeniden alınır. Değerler fiyatın ~0.7. kuvvetine göre seçildi.
	-- Rebirth ayakkabılar gibi skinleri de sıfırlar. Sadece fantezi renkler var (gerçek ten tonları fiyat/güç sıralamasına girmesin diye).
	Skins = {
		{ id = "mint", name = "Mint", price = 5, bonus = 1, color = Color3.fromRGB(150, 235, 190) },
		{ id = "lemon", name = "Lemon", price = 15, bonus = 3, color = Color3.fromRGB(255, 240, 110) },
		{ id = "coral", name = "Coral", price = 40, bonus = 6, color = Color3.fromRGB(255, 127, 110) },
		{ id = "bubblegum", name = "Bubblegum", price = 90, bonus = 10, color = Color3.fromRGB(255, 150, 200) },
		{ id = "orange", name = "Orange Pop", price = 200, bonus = 20, color = Color3.fromRGB(255, 150, 50) },
		{ id = "lime", name = "Lime Zap", price = 450, bonus = 35, color = Color3.fromRGB(140, 230, 60) },
		{ id = "teal", name = "Ocean Teal", price = 900, bonus = 60, color = Color3.fromRGB(40, 200, 190) },
		{ id = "sky", name = "Sky Blue", price = 1800, bonus = 100, color = Color3.fromRGB(80, 170, 255) },
		{ id = "violet", name = "Violet", price = 3600, bonus = 170, color = Color3.fromRGB(150, 90, 230) },
		{ id = "ruby", name = "Ruby Red", price = 7000, bonus = 280, color = Color3.fromRGB(225, 40, 60) },
		{ id = "silver", name = "Silver", price = 14000, bonus = 450, color = Color3.fromRGB(205, 210, 220) },
		{ id = "gold", name = "Golden", price = 28000, bonus = 700, color = Color3.fromRGB(255, 200, 40) },
		{ id = "ice", name = "Frozen", price = 56000, bonus = 1100, color = Color3.fromRGB(150, 235, 255) },
		{ id = "magma", name = "Magma", price = 110000, bonus = 1700, color = Color3.fromRGB(255, 90, 20) },
		{ id = "galaxy", name = "Galaxy", price = 220000, bonus = 2600, color = Color3.fromRGB(70, 45, 150) },
	},

	-- Antrenman alanı (SAĞ duvar, 3 basamakta 4 + 3 + 3 = 10 büyük ped): pede girince karakter otomatik squat yapar ve kazanç o pedin
	-- çarpanıyla çarpılır. Pedler SADECE REBIRTH ile açılır: rebirths = N ise oyuncunun N rebirth'i olunca açılır (0 = ücretsiz).
	-- Her pedde bir antrenör yer tutucusu durur, her antrenörün bir ismi var (trainer; etiketlerde görünür). Her antrenörün kendine özgü bir kıyafeti/parçacığı vardır (outfit: leaf, wave, flame, ember, pixel, frost, volt, nova, prism, shadow; server/Mannequin), gerçek modeller sonra gelecek. Sıra: önce 1. basamak (4), sonra 2. (3), sonra 3. (3).
	Training = {
		RowCounts = { 4, 3, 3 }, -- basamaklardaki ped sayıları (alttan üste)
		-- Üst basamaklara çıktıkça ped, antrenör ve şerit büyür (referans fotoğraftaki gibi); her şeridin ped dizisi RowLength'i doldurur
		RowPadSizes = { 8.5, 11, 13.5 }, -- ped boyutu (stud)
		RowDepths = { 12, 14.5, 17 }, -- şerit derinliği (stud)
		RowLength = 48, -- her şeridin ped dizisinin uzunluğu
		TrainerScales = { 1, 1.25, 1.5 }, -- antrenör boyutu (1 = ~5.3 stud boy)
		Areas = {
			{ id = "green", name = "Green Zone", trainer = "Coach Sprout", outfit = "leaf", mult = 1, rebirths = 0, color = Color3.fromRGB(60, 220, 90) },
			{ id = "blue", name = "Blue Zone", trainer = "Coach Wave", outfit = "wave", mult = 1.5, rebirths = 1, color = Color3.fromRGB(60, 100, 255) },
			{ id = "red", name = "Red Zone", trainer = "Coach Blaze", outfit = "flame", mult = 3, rebirths = 3, color = Color3.fromRGB(255, 50, 50) },
			{ id = "orange", name = "Orange Zone", trainer = "Coach Ember", outfit = "ember", mult = 5, rebirths = 5, color = Color3.fromRGB(255, 150, 30) },
			{ id = "magenta", name = "Magenta Zone", trainer = "Coach Pixel", outfit = "pixel", mult = 9, rebirths = 8, color = Color3.fromRGB(255, 50, 230) },
			{ id = "cyan", name = "Cyan Zone", trainer = "Coach Frost", outfit = "frost", mult = 18, rebirths = 12, color = Color3.fromRGB(50, 230, 255) },
			{ id = "yellow", name = "Yellow Zone", trainer = "Coach Volt", outfit = "volt", mult = 36, rebirths = 17, color = Color3.fromRGB(255, 230, 40) },
			{ id = "purple", name = "Purple Zone", trainer = "Coach Nova", outfit = "nova", mult = 100, rebirths = 24, color = Color3.fromRGB(160, 80, 255) },
			{ id = "rainbow", name = "Rainbow Zone", trainer = "Coach Prism", outfit = "prism", mult = 250, rebirths = 32, color = Color3.fromRGB(255, 255, 255), rainbow = true },
			{ id = "black", name = "Black Zone", trainer = "Coach Shadow", outfit = "shadow", mult = 999, rebirths = 45, color = Color3.fromRGB(35, 35, 48) },
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
	-- BLENDER MODELLERİ (tools/blender, shared/ModelLibrary + ModelInfo): ReplicatedStorage > GameModels klasöründe adı 'pet_<id>' / 'egg_<id>' olan model varsa oyun onu kullanır, yoksa eski küre/kod yumurtası.
	-- PetScale: kutu pet ölçeği (1 = Blender'daki ~2.1 stud küp); PetHover: modelin tabanının takipçi merkezine (HumanoidRootPart) göre yüksekliği (eksi = zemine yakın); EggScale: yumurta ölçeği.
	Models = {
		PetScale = 0.8,
		PetHover = -1.8,
		EggScale = 1,
		ShoeScale = 0.62, -- raftaki ayakkabı modeli (Blender'da ~3.9 stud uzun, rafta ~2.4 stud)
		CoachScale = 1, -- antrenör modeli (Blender'da ~5.25 stud boy, 4.98 geniş); Training.TrainerScales ile çarpılır
		-- Menülerdeki 3B pet simgesi (client/UIStyle.petModelIcon, ViewportFrame): kamera açıları ve ışık. Distance = en büyük boyutun katı (küçüldükçe pet büyür),
		-- Azimuth: yandan açı (derece), Elevation: yukarıdan açı, DimColor: keşfedilmemiş petin siluet rengi (Pet Index).
		PetIcon = {
			Distance = 2.1,
			Azimuth = -24,
			Elevation = 14,
			FieldOfView = 30,
			Ambient = Color3.fromRGB(190, 190, 205),
			LightColor = Color3.fromRGB(255, 250, 240),
			LightDirection = Vector3.new(0.5, -0.9, 0.7),
			DimColor = Color3.fromRGB(58, 60, 76),
		},
		MuscleScale = 1, -- bacak kası modelleri (muscle_s<aşama>_thigh|glute|calf): bacak ölçüsüne göre ölçeğin ek çarpanı (1.1 = %10 daha iri)
		LegRef = { Upper = Vector3.new(1, 1.217, 1), Lower = Vector3.new(1, 1.193, 1) }, -- kas modellerinin çizildiği referans R15 bacak ölçüsü (x genişlik, y boy, z derinlik); tools/blender/muscles.py ile aynı
		FlipFront = true, -- Roblox içe aktarıcısı modelin önünü +Z'ye koyar (Studio'da görüldü); true = yerleşirken 180 derece çevir, ön -Z'ye baksın. Model farklı dışa aktarılırsa false yap
	},

	-- GÜNLÜK ÇARK (server/WheelService: lobinin sağ arka köşesinde duran dönen çark, client/WheelPanel: E'ye basınca açılan arayüz, client/WheelController: dönüş animasyonu; mantık PlayerStats.spinWheel): her oyuncu günde 1 kez (UTC gün) çevirir,
	-- sonucu ve ödülü SUNUCU seçer, ödül hemen verilir ve kaydedilir (kayıtta WheelDay). Prizes sırası = dilimlerin saat yönündeki sırası (1. dilim üstte, ibrenin hemen sağında başlar); TAM 8 dilim olmalı (shared/WheelFace dik üçgenlerle çizer); weight = şans ağırlığı (toplam 100).
	-- kind: wins (tahmini aşama ödülü x mult, görev ödülü gibi), muscle (tıklama başı kazanç x clicks), boostMuscle / boostWins (minutes dakika 2x), pet (PetEgg yumurtasının havuzundan, envanter doluysa Win),
	-- jackpot (hem Win mult hem kas clicks). icon/label/color sadece çarkın görünüşü içindir; miktarlar oyuncunun gücüne göre ölçeklendiği için çarkta yazmaz, sonuçta gösterilir.
	Wheel = {
		Debug = false, -- TEST (şu an kapalı): çarka basınca ekranda 'server received' bildirimi çıkar (E'ye basınca bir şey olmuyorsa nerede koptuğunu görmek için); çark çalışınca false yap
		Radius = 4.6, -- görünen yuvarlak yüzün yarıçapı (stud); lobideki çarkın altın halkası bunun 1.45 katına kadar uzanır (kare yüzün köşelerini örter)
		SpinSeconds = 5.5, -- dönüş süresi
		IdleSpeed = 9, -- beklerken yavaş dönüş (derece / saniye)
		PetEgg = 3, -- 'pet' dilimi Config.Eggs içindeki bu sıradaki yumurtanın havuzundan pet verir
		Prizes = {
			{ kind = "wins", mult = 2, weight = 24, icon = "🏆", label = "Wins", color = Color3.fromRGB(235, 80, 90) },
			{ kind = "muscle", clicks = 500, weight = 24, icon = "💪", label = "Muscle", color = Color3.fromRGB(70, 140, 235) },
			{ kind = "boostMuscle", minutes = 15, weight = 14, icon = "💪", label = "Muscle Potion", color = Color3.fromRGB(70, 195, 110) },
			{ kind = "wins", mult = 6, weight = 10, icon = "🏆", label = "Big Wins", color = Color3.fromRGB(255, 160, 40) },
			{ kind = "muscle", clicks = 2000, weight = 14, icon = "💪", label = "Big Muscle", color = Color3.fromRGB(160, 90, 235) },
			{ kind = "boostWins", minutes = 15, weight = 8, icon = "🏆", label = "Wins Potion", color = Color3.fromRGB(50, 190, 200) },
			{ kind = "pet", weight = 5, icon = "🐾", label = "Pet!", color = Color3.fromRGB(255, 120, 190) },
			{ kind = "jackpot", mult = 20, clicks = 5000, weight = 1, icon = "💎", label = "JACKPOT", color = Color3.fromRGB(255, 205, 50) },
		},
	},
	MaxEquippedPets = 3, -- aynı anda takılı pet sayısı (en güçlüler otomatik takılır)
	MaxOwnedPets = 50, -- başlangıç pet envanteri; Shop'tan alınan 'Pet Space' (kind = petSpace) ile artar (kayıtlı, en çok MaxExtraPetSlots ek yer)
	MaxExtraPetSlots = 200,

	-- GÜNLÜK GÖREVLER (SADECE sağ üstteki 📜 dairesi açar, client/QuestPanel; lobideki görev panosu sahibinin isteğiyle KALDIRILDI): her gün PerDay görev (sırayla kolay, orta, zor), gece yarısı (UTC) yenilenir;
	-- aynı gün herkes aynı görevleri görür (gün sayısıyla seçilir). İlerlemeyi, ödülü ve günü SUNUCU tutar (PlayerStats), kayıtlıdır. Pool: id (olay adı), text ({goal} yerine hedef yazılır),
	-- goals (kolay/orta/zor slot hedefi), hardOnly (sadece zor slotta çıkar). Rewards: slot başına ödül: muscle = tıklama başı kazanç x clicks, wins = tahmini Win turu ödülü x mult
	-- (Layout.reward(tahmini aşama), tahmin rebirth sayısından). Üçü de bitince BonusBoostMinutes dakikalık RAINBOW POTION (Luck + Muscle + Wins 2x).
	Quests = {
		PerDay = 3,
		BonusBoostMinutes = 15,
		Pool = {
			{ id = "walls", text = "Break {goal} walls", goals = { 12, 25, 50 } },
			{ id = "clicks", text = "Squat or kick {goal} times", goals = { 120, 250, 500 } },
			{ id = "hatch", text = "Hatch {goal} eggs", goals = { 2, 4, 8 } },
			{ id = "winpads", text = "Step on the Win button {goal} times", goals = { 2, 3, 5 } },
			{ id = "fuse", text = "Merge pets {goal}x", goals = { 1, 1, 2 }, hardOnly = true },
			{ id = "rebirth", text = "Rebirth {goal}x", goals = { 1 }, hardOnly = true },
		},
		Rewards = {
			{ kind = "muscle", clicks = 600 },
			{ kind = "wins", mult = 4 },
			{ kind = "muscle", clicks = 3000 },
		},
	},

	-- PET BİRLEŞTİRME (Pets menüsündeki Merge düğmesi, client/PetsPanel; lobideki makine KALDIRILDI): Cost tane AYNI pet (aynı tür ve aynı boy) tek bir BİR ÜST BOYLU pete dönüşür.
	-- Boy arttıkça petin çarpanı PowerFactor katına çıkar ve kürenin boyu Scale kadar büyür, adı öne ek alır. Birleşmiş petin id'si 'cat@2' gibidir (Catalog.PetById bunları da üretir);
	-- Pet Index türe (ilk boy) bakar. PowerFactor DÜŞÜK tutuldu: fazlalık petler hiç boşa gitmediği için birleştirme zaten güç şişirir; tools/simulate.py (oyuncu hemen birleştirir diye en iyimser):
	-- 3.3 -> 12. rebirth 2.3 saatte (eskiden 11.8 saat), 2.0 -> 5.3, 1.6 -> 7.6, 1.5 -> 8.2, 1.3 -> 9.8, 1.2 -> 10.7 saat (240 saatte 125 rebirth yerine 179 / 216 / 159). 1.3 seçildi. Çarpanı yükseltmeden önce simulate.py ile (fusion=0/1, fusion_factor=...) dene.
	PetFusion = {
		Cost = 3,
		MaxTier = 4,
		PowerFactor = 1.3,
		-- Boylar: Small (yumurtadan çıkan), Normal, Big (en büyük boy) ve Boss (Big ile aynı boy, üstüne parlayan efekt: PetFollowers, Pets menüsü). Sahibi 'en büyük hali big, boss da üzerine efekt' dedi.
		TierNames = { "Small", "Normal", "Big", "Boss" },
		TierColors = { Color3.fromRGB(140, 200, 255), Color3.fromRGB(110, 230, 140), Color3.fromRGB(255, 190, 60), Color3.fromRGB(255, 70, 130) },
		Scale = { 1, 1.4, 1.9, 1.9 },
	},
	Pets = {
		-- Starter Egg
		{ id = "cat", name = "Cat", mult = 0.1, color = Color3.fromRGB(255, 190, 120) },
		{ id = "chick", name = "Chick", mult = 0.12, color = Color3.fromRGB(255, 225, 90) },
		{ id = "dog", name = "Dog", mult = 0.15, color = Color3.fromRGB(170, 120, 80) },
		{ id = "hamster", name = "Hamster", mult = 0.18, color = Color3.fromRGB(240, 200, 150) },
		{ id = "bunny", name = "Bunny", mult = 0.2, color = Color3.fromRGB(250, 220, 235) },
		-- Forest Egg
		{ id = "frog", name = "Frog", mult = 0.25, color = Color3.fromRGB(80, 210, 110) },
		{ id = "deer", name = "Deer", mult = 0.3, color = Color3.fromRGB(205, 150, 90) },
		{ id = "fox", name = "Fox", mult = 0.35, color = Color3.fromRGB(255, 120, 40) },
		{ id = "owl", name = "Owl", mult = 0.42, color = Color3.fromRGB(160, 130, 100) },
		{ id = "panda", name = "Panda", mult = 0.5, color = Color3.fromRGB(235, 235, 235) },
		-- Desert Egg
		{ id = "snake", name = "Snake", mult = 0.55, color = Color3.fromRGB(120, 190, 100) },
		{ id = "scorpion", name = "Scorpion", mult = 0.65, color = Color3.fromRGB(170, 60, 50) },
		{ id = "camel", name = "Camel", mult = 0.72, color = Color3.fromRGB(225, 195, 140) },
		{ id = "tiger", name = "Tiger", mult = 0.8, color = Color3.fromRGB(255, 170, 40) },
		{ id = "lion", name = "Lion", mult = 0.9, color = Color3.fromRGB(235, 190, 100) },
		-- Ice Egg
		{ id = "penguin", name = "Penguin", mult = 0.85, color = Color3.fromRGB(45, 55, 85) },
		{ id = "seal", name = "Seal", mult = 0.92, color = Color3.fromRGB(150, 165, 185) },
		{ id = "wolf", name = "Wolf", mult = 1.0, color = Color3.fromRGB(140, 150, 170) },
		{ id = "polarbear", name = "Polar Bear", mult = 1.15, color = Color3.fromRGB(245, 248, 255) },
		{ id = "yeti", name = "Yeti", mult = 1.3, color = Color3.fromRGB(170, 215, 245) },
		-- Lava Egg
		{ id = "salamander", name = "Salamander", mult = 1.4, color = Color3.fromRGB(255, 150, 60) },
		{ id = "dragon", name = "Dragon", mult = 1.5, color = Color3.fromRGB(180, 60, 255) },
		{ id = "lavacrab", name = "Lava Crab", mult = 1.75, color = Color3.fromRGB(225, 70, 50) },
		{ id = "phoenix", name = "Phoenix", mult = 2.0, color = Color3.fromRGB(255, 80, 40) },
		{ id = "golem", name = "Magma Golem", mult = 2.4, color = Color3.fromRGB(110, 95, 110) },
		-- Galaxy Egg
		{ id = "unicorn", name = "Unicorn", mult = 3.0, color = Color3.fromRGB(255, 130, 230) },
		{ id = "alien", name = "Alien", mult = 3.5, color = Color3.fromRGB(140, 235, 160) },
		{ id = "robot", name = "Robot", mult = 4.0, color = Color3.fromRGB(100, 220, 255) },
		{ id = "galaxy", name = "Galaxy Cat", mult = 6.0, color = Color3.fromRGB(120, 80, 255) },
		{ id = "titan", name = "Titan", mult = 10.0, color = Color3.fromRGB(255, 220, 60) },
	},

	-- Yumurta paneli: "T" tuşu bu seçenekler arasında geçiş yapar (bir seferde kaç yumurta açılacağı)
	EggMultiOptions = { 1, 3, 10 },

	-- İKSİRLER (süreli güçlendirmeler; kalan süre kayda girer, oyundan çıkıp girince sürer): sol altta geri sayımlı şişe simgesiyle görünür (client/BoostHud). Hepsi Mult (2) kat etki eder.
	-- Luck Potion: yumurta açarken nadir petlerin ağırlığı artar (Catalog.luckWeights: havuz sıklığa göre sıralanır, en sık pete x1, en nadir pete x2, arası düzgün artar).
	-- Muscle Potion: tıklama başı bacak kazancı x2. Wins Potion: kazanılan Win x2.
	-- Rainbow Potion: 'bütün iksirlerden almışsın gibi' sayılır, yani Luck + Muscle + Wins etkisi BİRLİKTE (tek şişe, tek geri sayım). Aynı etki üst üste çarpmaz (iki kaynak da olsa hep x2).
	-- kind: ödül türü (Shop, Gifts, Wheel, DEV'de bu adla geçer); attribute: oyuncuya yayınlanan bitiş zamanı (sunucu saati).
	Potions = {
		Mult = 2,
		Durations = { 15, 60 }, -- Shop'ta satılan süreler (dakika); çark/Gifts/görev bonusu iksirleri bunlardan birindedir (BoostMinutes)
		List = {
			{ id = "luck", kind = "boostLuck", attribute = "LuckBoostUntil", name = "Luck Potion", effect = "2x Egg Luck", description = "Rare pets hatch from eggs up to 2x more often.", emoji = "🍀", color = Color3.fromRGB(70, 210, 90) },
			{ id = "muscle", kind = "boostMuscle", attribute = "MuscleBoostUntil", name = "Muscle Potion", effect = "2x Leg Muscle", description = "Doubles the Leg Muscle you get from every squat.", emoji = "💪", color = Color3.fromRGB(255, 120, 50) },
			{ id = "wins", kind = "boostWins", attribute = "WinBoostUntil", name = "Wins Potion", effect = "2x Wins", description = "Doubles every Win you earn.", emoji = "🏆", color = Color3.fromRGB(255, 205, 50) },
			{ id = "rainbow", kind = "boostRainbow", attribute = "RainbowBoostUntil", name = "Rainbow Potion", effect = "2x Luck, Muscle & Wins", description = "Counts as ALL potions: 2x egg luck, 2x muscle and 2x Wins!", emoji = "🌈", rainbow = true, color = Color3.fromRGB(255, 255, 255) },
		},
	},

	-- Yumurtalar (lobinin arka duvarında): üstündeki pedin üstüne basınca Win karşılığı açılır.
	-- pets = o yumurtadan çıkabilecek petler ve ağırlıkları (büyük sayı = daha sık çıkar; her yumurtada 50/30/13/5/2: en sık -> en nadir. Sahibi 'pet şanslarını düşür, iksirler olsun' dedi: nadir petler ZOR, Luck Potion (Config.Potions) nadirleri artırır). HER PET SADECE BİR YUMURTADA ÇIKAR (sahibi 'her yumurtanın hayvanı kendine özel olsun' dedi): 6 yumurta x 5 pet = 30 pet;
	-- yeni pet eklerken önce hangi yumurtaya ait olduğunu seç, Config.Pets'te o yumurtanın grubuna koy, Blender modelini (tools/blender/pets_more.py) ekle. Fiyatlar geçicidir.
	-- color/accent = yumurtanın ana rengi ve benek rengi.
	Eggs = {
		{ id = "starter", name = "Starter Egg", price = 5, color = Color3.fromRGB(90, 190, 255), accent = Color3.fromRGB(255, 220, 60),
			pets = { { id = "cat", weight = 50 }, { id = "chick", weight = 30 }, { id = "dog", weight = 13 }, { id = "hamster", weight = 5 }, { id = "bunny", weight = 2 } } },
		{ id = "forest", name = "Forest Egg", price = 50, color = Color3.fromRGB(90, 220, 120), accent = Color3.fromRGB(40, 120, 60),
			pets = { { id = "frog", weight = 50 }, { id = "deer", weight = 30 }, { id = "fox", weight = 13 }, { id = "owl", weight = 5 }, { id = "panda", weight = 2 } } },
		{ id = "desert", name = "Desert Egg", price = 500, color = Color3.fromRGB(255, 200, 90), accent = Color3.fromRGB(190, 110, 30),
			pets = { { id = "snake", weight = 50 }, { id = "scorpion", weight = 30 }, { id = "camel", weight = 13 }, { id = "tiger", weight = 5 }, { id = "lion", weight = 2 } } },
		{ id = "ice", name = "Ice Egg", price = 2500, color = Color3.fromRGB(190, 240, 255), accent = Color3.fromRGB(90, 160, 255),
			pets = { { id = "penguin", weight = 50 }, { id = "seal", weight = 30 }, { id = "wolf", weight = 13 }, { id = "polarbear", weight = 5 }, { id = "yeti", weight = 2 } } },
		{ id = "lava", name = "Lava Egg", price = 10000, color = Color3.fromRGB(255, 90, 50), accent = Color3.fromRGB(255, 220, 60),
			pets = { { id = "salamander", weight = 50 }, { id = "dragon", weight = 30 }, { id = "lavacrab", weight = 13 }, { id = "phoenix", weight = 5 }, { id = "golem", weight = 2 } } },
		{ id = "galaxy", name = "Galaxy Egg", price = 50000, color = Color3.fromRGB(110, 70, 220), accent = Color3.fromRGB(255, 255, 255),
			pets = { { id = "unicorn", weight = 50 }, { id = "alien", weight = 30 }, { id = "robot", weight = 13 }, { id = "galaxy", weight = 5 }, { id = "titan", weight = 2 } } },
	},

	-- İz (trail) efektleri: karakterin arkasında renkli bir iz bırakır ve yürüme hızını artırır (speed = ek hız, stud/sn).
	-- Win ile alınır (winPrice). robuxPrice + robuxProductId: Robux butonu; robuxProductId 0 ise buton "yakında" olarak kalır.
	-- Gerçek satış için Creator Hub'da Developer Product oluşturup ID'sini robuxProductId'ye yazmak ve sunucuda
	-- MarketplaceService.ProcessReceipt'i bağlamak gerekir (henüz yok). Fiyatlar geçicidir.
	BaseWalkSpeed = 16,
	Trails = {
		{ id = "red", name = "Red Trail", speed = 4, winPrice = 50, robuxPrice = 9, robuxProductId = 0, color = Color3.fromRGB(255, 60, 60) },
		{ id = "orange", name = "Orange Trail", speed = 6, winPrice = 150, robuxPrice = 19, robuxProductId = 0, color = Color3.fromRGB(255, 150, 40) },
		{ id = "yellow", name = "Yellow Trail", speed = 8, winPrice = 400, robuxPrice = 29, robuxProductId = 0, color = Color3.fromRGB(255, 230, 60) },
		{ id = "green", name = "Green Trail", speed = 10, winPrice = 1000, robuxPrice = 39, robuxProductId = 0, color = Color3.fromRGB(70, 220, 90) },
		{ id = "cyan", name = "Cyan Trail", speed = 12, winPrice = 2500, robuxPrice = 59, robuxProductId = 0, color = Color3.fromRGB(60, 220, 255) },
		{ id = "blue", name = "Blue Trail", speed = 14, winPrice = 6000, robuxPrice = 79, robuxProductId = 0, color = Color3.fromRGB(70, 110, 255) },
		{ id = "purple", name = "Purple Trail", speed = 16, winPrice = 15000, robuxPrice = 99, robuxProductId = 0, color = Color3.fromRGB(170, 80, 255) },
		{ id = "pink", name = "Pink Trail", speed = 18, winPrice = 40000, robuxPrice = 129, robuxProductId = 0, color = Color3.fromRGB(255, 100, 200) },
		{ id = "rainbow", name = "Rainbow Trail", speed = 24, winPrice = 100000, robuxPrice = 149, robuxProductId = 0, color = Color3.fromRGB(255, 255, 255), rainbow = true },
	},

	-- Aura efektleri (Backpack > Auras): karakterin etrafında renkli parıltı. mult = bacak kası kazancı çarpanı.
	-- Win (winPrice) ile alınır; Robux butonu robuxProductId 0 iken "yakında" olarak kalır. Fiyatlar geçicidir.
	Auras = {
		{ id = "red", name = "Red Aura", mult = 1.2, winPrice = 1500, robuxPrice = 19, robuxProductId = 0, color = Color3.fromRGB(255, 60, 60) },
		{ id = "green", name = "Green Aura", mult = 1.4, winPrice = 5000, robuxPrice = 39, robuxProductId = 0, color = Color3.fromRGB(70, 220, 90) },
		{ id = "blue", name = "Blue Aura", mult = 1.6, winPrice = 15000, robuxPrice = 59, robuxProductId = 0, color = Color3.fromRGB(70, 130, 255) },
		{ id = "purple", name = "Purple Aura", mult = 1.8, winPrice = 40000, robuxPrice = 89, robuxProductId = 0, color = Color3.fromRGB(170, 80, 255) },
		{ id = "gold", name = "Gold Aura", mult = 2.2, winPrice = 90000, robuxPrice = 119, robuxProductId = 0, color = Color3.fromRGB(255, 205, 50) },
		{ id = "rainbow", name = "Rainbow Aura", mult = 3.0, winPrice = 200000, robuxPrice = 149, robuxProductId = 0, color = Color3.fromRGB(255, 255, 255), rainbow = true },
	},

	-- Oyun süresi ödülleri (Gifts > Playtime Rewards): oyuna girdikten time saniye sonra alınabilir.
	-- kind: muscle (amount kadar bacak kası), wins (amount Win), pet (pet id), boostLuck / boostMuscle / boostWins / boostRainbow (iksirler, BoostMinutes dk 2x).
	-- Ödüller her oyuna girişte yeniden başlar (kayıt edilmez). SkipRobux: "Unlock" butonları Robux yer tutucusu.
	BoostMinutes = 15, -- Gifts / Çark / günlük bonus iksirlerinin süresi; Shop.Potions'taki SKU sürelerinden biri olmalı (15 ya da 60)
	GiftRewards = {
		{ time = 60, kind = "muscle", amount = 300 },
		{ time = 150, kind = "wins", amount = 10 },
		{ time = 270, kind = "muscle", amount = 1000 },
		{ time = 420, kind = "wins", amount = 50 },
		{ time = 600, kind = "pet", pet = "dragon" },
		{ time = 780, kind = "muscle", amount = 5000 },
		{ time = 1080, kind = "boostMuscle" },
		{ time = 1380, kind = "boostLuck" },
		{ time = 1800, kind = "boostWins" },
		{ time = 2400, kind = "pet", pet = "phoenix" },
	},
	GiftUnlockAllRobux = 149,
	GiftUnlockNextRobux = 19,
}
