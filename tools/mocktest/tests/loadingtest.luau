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
local screen = LoadingScreen.build(gui)
assert(screen.gui and screen.root and screen.backdrop and screen.viewport and screen.fill and screen.percent and screen.label, "arayüz parçaları yok")
assert(rawget(screen.gui, "DisplayOrder") == LoadingScreen.DisplayOrder, "DisplayOrder ayarlanmalı")
assert(rawget(screen.backdrop, "Active") == true, "zemin Active olmalı (arkadaki tıklamalar sayılmasın)")
-- 3B tuğlalar: 6 adet, her biri 2x2 (gövde + 4 çıkıntı), hepsi ViewportFrame'in içinde
assert(#screen.bricks == 6, "6 tuğla olmalı: " .. #screen.bricks)
for index, item in screen.bricks do
	local parts = rawget(item.model, "_children")
	local count = 0
	for _ in parts do
		count += 1
	end
	assert(count == 5 and parts.Body and parts.Stud1 and parts.Stud2 and parts.Stud3 and parts.Stud4, "tuğla " .. index .. ": gövde + 4 çıkıntı olmalı, parça sayısı " .. count)
	assert(rawget(parts.Stud1, "Shape") == "PartType.Cylinder", "çıkıntı silindir olmalı")
	assert(rawget(item.model, "PrimaryPart") == parts.Body, "PrimaryPart gövde olmalı")
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
