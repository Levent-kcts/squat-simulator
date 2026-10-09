-- Yükleme ekranı (src/loading/LoadingScreen): ağırlıklar, ilerleme hesabı, yumuşatma, nokta animasyonu, simge toplama ve arayüzün kurulması
local S = require("../cstubs")
local LoadingScreen = require("./LoadingScreen")

-- Aşama ağırlıkları toplam 1
local total = 0
for _, weight in LoadingScreen.Stages do
	total += weight
end
assert(math.abs(total - 1) < 1e-9, "aşama ağırlıkları toplamı 1 olmalı: " .. total)

-- Hedef: hiçbir şey bitmedi = 0, hepsi bitti = 1, yarım aşama orantılı, 1'den büyük/negatif değerler sıkıştırılır
assert(LoadingScreen.target({}) == 0, "boş ilerleme 0 olmalı")
assert(math.abs(LoadingScreen.target({ game = 1, world = 1, assets = 1, character = 1, client = 1 }) - 1) < 1e-9, "hepsi bitince 1 olmalı")
assert(math.abs(LoadingScreen.target({ assets = 0.5 }) - 0.15) < 1e-9, "yarım simge aşaması 0.15 olmalı")
assert(math.abs(LoadingScreen.target({ game = 5, world = -3 }) - LoadingScreen.Stages.game) < 1e-9, "değerler 0..1'e sıkıştırılmalı")

-- Yumuşatma: hedefe yaklaşır, asla geçmez, asla geri gitmez, yakın hedefte bile ilerler
local shown = 0
for _ = 1, 600 do
	local before = shown
	shown = LoadingScreen.ease(shown, 0.6, 1 / 60)
	assert(shown >= before and shown <= 0.6 + 1e-9, "ease hedefi geçmemeli ve geri gitmemeli")
end
assert(math.abs(shown - 0.6) < 1e-6, "ease hedefe ulaşmalı: " .. shown)
assert(LoadingScreen.ease(0.8, 0.5, 1 / 60) == 0.8, "hedef gerideyse çubuk geri gitmemeli")
assert(LoadingScreen.ease(0.9999, 1, 1 / 60) > 0.9999, "hedefe çok yakınken de ilerlemeli")

-- Yazı: her zaman 10 karakter (LOADING + nokta + boşluk), nokta sayısı 0-3 arasında döner
local seen = {}
for tick = 0, 40 do
	local text = LoadingScreen.dots(tick * 0.1)
	assert(#text == 10 and string.sub(text, 1, 7) == "LOADING", "yazı sabit genişlikte olmalı: '" .. text .. "'")
	seen[#string.gsub(text, "[^.]", "")] = true
end
assert(seen[0] and seen[1] and seen[2] and seen[3], "noktalar 0'dan 3'e dönmeli")

-- Simge toplama: iç içe tablolardaki rbxassetid adresleri, boş ve yabancı değerler atlanır
local list = LoadingScreen.collectAssets({ A = "rbxassetid://1", B = "", C = { D = "rbxassetid://2", E = "http://x" }, F = 5 })
table.sort(list)
assert(#list == 2 and list[1] == "rbxassetid://1" and list[2] == "rbxassetid://2", "simge listesi yanlış: " .. #list)
assert(#LoadingScreen.collectAssets(nil) == 0, "tablo yoksa liste boş olmalı")

-- Arayüz: kurulur, ilerleme ve yüzde yazısı güncellenir, hata vermeden animasyon ve solma çalışır
local gui = S.newInstance("PlayerGui")
local screen = LoadingScreen.build(gui, { brick = "rbxassetid://123", barbell = "rbxassetid://456", muscle = "rbxassetid://789" })
assert(screen.gui and screen.root and screen.backdrop and screen.fill and screen.percent and screen.label, "arayüz parçaları yok")
assert(rawget(screen.gui, "DisplayOrder") == LoadingScreen.DisplayOrder, "DisplayOrder ayarlanmalı")
assert(rawget(screen.backdrop, "Active") == true, "zemin Active olmalı (arkadaki tıklamalar sayılmasın)")
-- Tüm ekran dolar: 8 sütun x 5 sıra, çift sıralarda 8, tek sıralarda 9 süs = 42; üç tür de bulunur
local expected = 0
for row = 0, LoadingScreen.Grid.Rows - 1 do
	expected += if row % 2 == 1 then LoadingScreen.Grid.Columns + 1 else LoadingScreen.Grid.Columns
end
assert(#screen.decor == expected and expected == 42, "tüm ekranı dolduran desen " .. expected .. " süs olmalı: " .. #screen.decor)
local counts = { Brick = 0, Barbell = 0, Muscle = 0 }
local colors, spreadMinX, spreadMaxX, spreadMinY, spreadMaxY = {}, 1, 0, 1, 0
for _, item in screen.decor do
	assert(rawget(item.frame, "ClassName") == "ImageLabel", "süs ImageLabel olmalı")
	counts[item.kind] += 1
	spreadMinX, spreadMaxX = math.min(spreadMinX, item.x), math.max(spreadMaxX, item.x)
	spreadMinY, spreadMaxY = math.min(spreadMinY, item.y), math.max(spreadMaxY, item.y)
	if item.kind == "Brick" then
		assert(rawget(item.frame, "Image") == "rbxassetid://123", "tuğla resmi")
		local color = rawget(item.frame, "ImageColor3")
		colors[string.format("%.2f/%.2f/%.2f", color.R, color.G, color.B)] = true
	elseif item.kind == "Barbell" then
		assert(rawget(item.frame, "Image") == "rbxassetid://456", "barbell resmi")
		assert(rawget(item.frame, "ImageColor3") == nil, "barbell boyanmamalı (olduğu gibi gösterilir)")
		assert(item.scale == nil, "barbell kasılmaz")
	else
		assert(rawget(item.frame, "Image") == "rbxassetid://789", "kas resmi")
		assert(item.scale and item.pulse and item.pulse > 0 and item.pulse < 0.3, "kas kasılıp gevşemeli (UIScale)")
	end
end
assert(counts.Brick > 15 and counts.Barbell > 5 and counts.Muscle > 5, "üç tür de bol olmalı: " .. counts.Brick .. "/" .. counts.Barbell .. "/" .. counts.Muscle)
assert(#screen.bricks == counts.Brick, "bricks listesi tuğlaları içermeli")
local distinct = 0
for _ in colors do
	distinct += 1
end
assert(distinct == 6, "tuğlalar 6 farklı renkte olmalı: " .. distinct)
assert(spreadMinX < 0.1 and spreadMaxX > 0.9 and spreadMinY < 0.15 and spreadMaxY > 0.85, "süsler ekranın her yerine yayılmalı")
assert(not rawget(screen, "viewport"), "3B ViewportFrame kalmamalı")
-- Metin bölgesindeki süsler yarı saydam, dışındakiler opak
local ghosted, solid = 0, 0
for _, item in screen.decor do
	local inside = item.x > 0.14 and item.x < 0.86 and item.y > 0.2 and item.y < 0.72
	local transparency = rawget(item.frame, "ImageTransparency")
	if inside then
		assert(transparency == LoadingScreen.TextZoneTransparency, "metin bölgesindeki süs yarı saydam olmalı")
		ghosted += 1
	else
		assert(transparency == nil, "metin bölgesi dışındaki süs opak olmalı")
		solid += 1
	end
end
assert(ghosted > 5 and solid > 10, "hem yarı saydam hem opak süs olmalı: " .. ghosted .. "/" .. solid)
-- Kasılma ölçeği her zaman pozitif ve makul kalmalı (negatif/sıfır ölçek resmi bozar)
for _, clock in { 0, 0.4, 1.3, 2.9, 7.7 } do
	screen.animate(clock)
	for _, item in screen.decor do
		if item.scale then
			local value = rawget(item.scale, "Scale")
			assert(value > 0.7 and value < 1.3, "kas ölçeği makul aralıkta olmalı: " .. value)
		end
	end
end
-- Resim kimlikleri yokken ({} = hiçbiri) hiçbir süs çizilmez ama ekran hatasız kurulur
local plain = LoadingScreen.build(S.newInstance("PlayerGui"), {})
assert(#plain.bricks == 0 and #plain.decor == 0, "resim kimliği yokken süs çizilmemeli")
plain.animate(2)
-- Sadece bacak kası yüklüyse (barbell/tuğla henüz yüklenmemişken) tüm ekran kaslarla dolar
local onlyMuscle = LoadingScreen.build(S.newInstance("PlayerGui"), { muscle = "rbxassetid://5" })
assert(#onlyMuscle.decor == expected and #onlyMuscle.bricks == 0, "sadece kas: tüm desen kaslarla dolmalı: " .. #onlyMuscle.decor)
for _, item in onlyMuscle.decor do
	assert(item.kind == "Muscle", "sadece kas yüklüyse hepsi kas olmalı")
end
screen.setProgress(0.5)
assert(rawget(screen.percent, "Text") == "50%", "yüzde yazısı: " .. tostring(rawget(screen.percent, "Text")))
screen.setProgress(2)
assert(rawget(screen.percent, "Text") == "100%", "1'den büyük değer 100% olmalı")
screen.setProgress(-1)
assert(rawget(screen.percent, "Text") == "0%", "negatif değer 0% olmalı")
screen.setDots(0.8)
assert(rawget(screen.label, "Text") == LoadingScreen.dots(0.8), "nokta yazısı güncellenmeli")
screen.animate(1.5)
screen.animate(7.25) -- zaman ilerleyince de hata vermemeli
local ok, err = pcall(screen.fadeOut, 0.5)
assert(ok, "fadeOut hata verdi: " .. tostring(err))
print("LoadingScreen ok")
