-- YUMURTA KIRILMA ANİMASYONU (client/Reveal; sahibi 'her yumurta satın aldığında [multi alımlar hariç] yumurta ekranın önüne UI olarak gelsin, sallansın, sonra şu anki animasyon oynasın' dedi):
-- TEK yumurtada önce yumurta (sallanır, çatlar) görünür, kırılınca parıltı + pet kartı gelir; çoklu açılışta ve yumurta verilmezse (otomatik açma) animasyon YOK.
local S = require("../cstubs")
local Config = require("./Config")
local Reveal = require("./Reveal")
local Sfx = require("./Sfx")
-- Sesleri kaydet: Reveal Sfx.play'i çağrı anında modül tablosundan okur
local played = {}
Sfx.play = function(name, opts)
	table.insert(played, { name = name, opts = opts })
end
local function playedCount(name)
	local total = 0
	for _, entry in played do
		if entry.name == name then
			total += 1
		end
	end
	return total
end

local function find(instance, name)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			return child
		end
		local deeper = find(child, name)
		if deeper then
			return deeper
		end
	end
	return nil
end
local function count(instance, name)
	local total = 0
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			total += 1
		end
		total += count(child, name)
	end
	return total
end
-- Zamanı ileri sar: kuyruktaki gecikmeli işlerden süresi 'until' saniyeden kısa olanları çalıştırır (çalışırken yeni kurulan gecikmeler kuyrukta kalır, bir sonraki sarmada işlenir)
local function advance(untilSeconds)
	local batch = table.clone(S.delayed)
	table.clear(S.delayed)
	table.sort(batch, function(a, b)
		return a[1] < b[1]
	end)
	local later = {}
	for _, entry in batch do
		if entry[1] <= untilSeconds then
			pcall(entry[2])
		else
			table.insert(later, entry)
		end
	end
	for _, entry in later do
		table.insert(S.delayed, entry)
	end
end
local function petResults(total)
	local list = {}
	for _ = 1, total do
		table.insert(list, { id = Config.Pets[1].id, kept = true })
	end
	return list
end

local egg = Config.Eggs[1]

-- 1) TEK yumurta + yumurta verildi: önce yumurta ekranın önünde, parıltı ve kart henüz yok; çatlak çizgileri ve gri ışık dairesi YOK (sahibi 'kırılma çizgileri çok kötü, kaldır' dedi)
local root = S.newInstance("Frame")
Reveal.show(root, petResults(1), {}, egg)
local reveal = find(root, "HatchReveal")
assert(reveal, "açılış ekranı kurulmalı")
local eggFrame = find(reveal, "HatchEgg")
assert(eggFrame and find(eggFrame, "HatchEggWhole"), "tek yumurtada önce bütün yumurta görünmeli")
assert(count(eggFrame, "HatchCrack") == 0 and count(eggFrame, "HatchCrackPiece") == 0 and not find(eggFrame, "HatchGlow"), "yumurtada çatlak çizgisi ve gri ışık dairesi olmamalı")
assert(not find(reveal, "HatchFlash"), "yumurta kırılmadan parıltı olmamalı")
assert(Reveal.EggIntroSeconds > Reveal.EggBreakAt and Reveal.EggBreakAt > 0.5, "kırılma anı ve toplam süre tanımlı olmalı")
-- 1b) SES: 'dum dum dum dum dum puf' (sahibi lego kırılma sesini kapattırıp öyle istedi): her büyüme vuruşunda tok 'dum', ses ve perde vuruştan vuruşa yükselir; lego sesi (EggBreak/EggKnock) YOK
assert(Config.Sounds.EggBreak == nil and Config.Sounds.EggKnock == nil, "eski lego kırılma/tık sesleri kaldırılmış olmalı")
assert(Config.Sounds.EggDum and Config.Sounds.EggPuf, "EggDum ve EggPuf sesleri tanımlı olmalı")
assert(#Reveal.EggBeats == 5, "yumurta beş vuruşla büyümeli (dum dum dum dum dum)")
advance(0.2 + Reveal.EggBeats[#Reveal.EggBeats].at + 0.05)
assert(playedCount("EggDum") == 5, "beş vuruşta beş 'dum' çalmalı: " .. playedCount("EggDum"))
assert(playedCount("EggPuf") == 0 and playedCount("EggBreak") == 0, "kırılmadan önce 'puf' çalmamalı")
local lastVolume, lastPitch = 0, 0
for _, entry in played do
	if entry.name == "EggDum" then
		assert(entry.opts and entry.opts.volume > lastVolume and entry.opts.speed > lastPitch, "her 'dum' bir öncekinden yüksek ve tizce olmalı")
		lastVolume, lastPitch = entry.opts.volume, entry.opts.speed
	end
end
-- 2) KIRILMA anı: bütün yumurta kalkar, çatlak çizgisinden İKİ YARI ayrılır (üst + alt), ışık patlar
advance(Reveal.EggBreakAt + 0.05)
assert(not find(eggFrame, "HatchEggWhole"), "kırılınca bütün yumurta kalkmalı")
assert(find(eggFrame, "HatchEggTop") and find(eggFrame, "HatchEggBottom"), "kırılınca iki yarı görünmeli")
assert(find(reveal, "HatchBurst"), "kırılırken ışık patlaması olmalı")
assert(playedCount("EggPuf") == 1 and playedCount("EggDum") == 5, "kırılırken yumuşak 'puf' çalmalı (tek)")
assert(played[#played].name == "EggPuf", "'puf' son vuruşun ardından gelmeli")
-- 3) Yumurta animasyonu bitince yarılar kalkar, mevcut açılış (hafif ışık + pet kartları) oynar
advance(Reveal.EggIntroSeconds + 0.05)
assert(not find(reveal, "HatchEgg"), "animasyon bitince yumurta kalkmalı")
assert(find(reveal, "HatchFlash"), "sonra hafif ışık çakmalı")
assert(find(reveal, "HatchCards"), "pet kartları olmalı")
print("egg break animation ok")

-- 4) ÇOKLU açılış (x3): yumurta animasyonu YOK, parıltı hemen
local rootMulti = S.newInstance("Frame")
Reveal.show(rootMulti, petResults(3), {}, egg)
local revealMulti = find(rootMulti, "HatchReveal")
assert(revealMulti and not find(revealMulti, "HatchEgg"), "çoklu açılışta yumurta animasyonu olmamalı")
assert(find(revealMulti, "HatchFlash"), "çoklu açılışta parıltı hemen çakmalı")

-- 5) Yumurta verilmezse (otomatik açma ya da eski çağrı): tek pet de olsa animasyon yok
local rootAuto = S.newInstance("Frame")
Reveal.show(rootAuto, petResults(1), {}, nil)
local revealAuto = find(rootAuto, "HatchReveal")
assert(revealAuto and not find(revealAuto, "HatchEgg") and find(revealAuto, "HatchFlash"), "yumurta verilmezse animasyon olmamalı")
print("reveal multi/auto ok")

-- 6) KARARTMA TÜM EKRANI KAPLAR (sahibi 'üstü kararmıyor, onu da karart' dedi): açılış, üst çubuk payını ve sağ üst daireleri de örten KENDİ tam ekran ScreenGui'sinde kurulur;
-- kartlar ana arayüzle aynı boyutta kalsın diye ölçek kopyalanır, karartma ölçeksiz tam ekran kalır
local playerGui = S.newInstance("PlayerGui")
playerGui.Name = "PlayerGui"
rawget(S.localPlayer, "_children")["PlayerGui"] = playerGui
local hudRoot = S.newInstance("Frame")
local rootScale = S.newInstance("UIScale")
rootScale.Name = "RootScale"
rawset(rootScale, "Scale", 1.3)
rootScale.Parent = hudRoot
Reveal.show(hudRoot, petResults(1), {}, nil)
local overlayGui = rawget(playerGui, "_children").HatchRevealGui
assert(overlayGui and rawget(overlayGui, "IgnoreGuiInset") == true, "açılış üst çubuk payını da kaplayan (IgnoreGuiInset) kendi ScreenGui'sinde olmalı")
assert(rawget(overlayGui, "DisplayOrder") > 2 and rawget(overlayGui, "DisplayOrder") < 1000, "ana arayüzün ve sağ üst dairelerin üstünde, yükleme ekranının altında olmalı")
local overlayReveal = find(overlayGui, "HatchReveal")
assert(overlayReveal and not find(hudRoot, "HatchReveal"), "açılış ana arayüz çerçevesine değil tam ekran ScreenGui'ye kurulmalı")
local dim = find(overlayReveal, "HatchDim")
assert(dim and rawget(dim, "Parent") == overlayReveal, "karartma ölçeksiz tam ekran kökte olmalı")
local content = find(overlayReveal, "HatchContent")
assert(rawget(content, "ZIndex") > rawget(dim, "ZIndex"), "ürünler (yumurta, pet kartları) karartmanın ÜSTÜNDE olmalı: karartılmaz, aydınlık kalır")
assert(content and find(content, "HatchCards"), "kartlar ölçekli içerikte olmalı")
assert(rawget(rawget(content, "_children").UIScale, "Scale") == 1.3, "içerik ana arayüzün ölçeğini kopyalamalı")
print("reveal full screen ok")
