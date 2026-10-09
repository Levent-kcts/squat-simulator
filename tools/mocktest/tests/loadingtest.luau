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
local screen = LoadingScreen.build(gui, "rbxassetid://123")
assert(screen.gui and screen.root and screen.backdrop and screen.fill and screen.percent and screen.label, "arayüz parçaları yok")
assert(rawget(screen.gui, "DisplayOrder") == LoadingScreen.DisplayOrder, "DisplayOrder ayarlanmalı")
assert(rawget(screen.backdrop, "Active") == true, "zemin Active olmalı (arkadaki tıklamalar sayılmasın)")
-- 2D tuğlalar: 6 adet ImageLabel, hepsi aynı resim ama farklı renge boyanmış; 3B (ViewportFrame) yok
assert(#screen.bricks == 6, "6 tuğla olmalı: " .. #screen.bricks)
local colors = {}
for index, item in screen.bricks do
	assert(rawget(item.frame, "ClassName") == "ImageLabel", "tuğla ImageLabel olmalı")
	assert(rawget(item.frame, "Image") == "rbxassetid://123", "tuğla resmi verilen kimlik olmalı")
	local color = rawget(item.frame, "ImageColor3")
	colors[string.format("%.2f/%.2f/%.2f", color.R, color.G, color.B)] = true
end
local distinct = 0
for _ in colors do
	distinct += 1
end
assert(distinct == 6, "6 tuğla 6 farklı renkte olmalı: " .. distinct)
assert(not rawget(screen, "viewport"), "3B ViewportFrame kalmamalı")
-- Kimlik yokken (Config.Icons.LoadingBrick boş) tuğla çizilmez ama ekran hatasız kurulur
local plain = LoadingScreen.build(S.newInstance("PlayerGui"), nil)
assert(#plain.bricks == 0, "resim kimliği yokken tuğla çizilmemeli")
plain.animate(2)
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
