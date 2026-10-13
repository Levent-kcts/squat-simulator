-- YUMURTA KIRILMA ANİMASYONU (client/Reveal; sahibi 'her yumurta satın aldığında [multi alımlar hariç] yumurta ekranın önüne UI olarak gelsin, sallansın, sonra şu anki animasyon oynasın' dedi):
-- TEK yumurtada önce yumurta (sallanır, çatlar) görünür, kırılınca parıltı + pet kartı gelir; çoklu açılışta ve yumurta verilmezse (otomatik açma) animasyon YOK.
local S = require("../cstubs")
local Config = require("./Config")
local Reveal = require("./Reveal")

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
-- Zamanı ileri sar: kuyruktaki gecikmeli işlerden süresi 'until' saniyeden kısa olanları çalıştırır
local function advance(untilSeconds)
	local pending = S.delayed
	table.sort(pending, function(a, b)
		return a[1] < b[1]
	end)
	local remaining = {}
	for _, entry in pending do
		if entry[1] <= untilSeconds then
			pcall(entry[2])
		else
			table.insert(remaining, entry)
		end
	end
	table.clear(pending)
	for _, entry in remaining do
		table.insert(pending, entry)
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

-- 1) TEK yumurta + yumurta verildi: önce yumurta ekranın önünde (sallanır, çatlaklar), parıltı ve kart henüz yok
local root = S.newInstance("Frame")
Reveal.show(root, petResults(1), {}, egg)
local reveal = find(root, "HatchReveal")
assert(reveal, "açılış ekranı kurulmalı")
local eggFrame = find(reveal, "HatchEgg")
assert(eggFrame, "tek yumurtada önce yumurta görünmeli")
assert(count(eggFrame, "HatchCrack") == 3, "yumurtada çatlaklar olmalı")
assert(not find(reveal, "HatchFlash"), "yumurta kırılmadan parıltı olmamalı")
-- 2) Yumurta kırılınca (süre dolunca) yumurta kalkar, parıltı çakar ve mevcut açılış (kartlar) oynar
advance(2.5)
assert(not find(reveal, "HatchEgg"), "kırılınca yumurta kalkmalı")
assert(find(reveal, "HatchFlash"), "kırılınca parıltı çakmalı")
assert(find(reveal, "HatchCards"), "pet kartları olmalı")
print("egg break animation ok")

-- 3) ÇOKLU açılış (x3): yumurta animasyonu YOK, parıltı hemen
local rootMulti = S.newInstance("Frame")
Reveal.show(rootMulti, petResults(3), {}, egg)
local revealMulti = find(rootMulti, "HatchReveal")
assert(revealMulti and not find(revealMulti, "HatchEgg"), "çoklu açılışta yumurta animasyonu olmamalı")
assert(find(revealMulti, "HatchFlash"), "çoklu açılışta parıltı hemen çakmalı")

-- 4) Yumurta verilmezse (otomatik açma ya da eski çağrı): tek pet de olsa animasyon yok
local rootAuto = S.newInstance("Frame")
Reveal.show(rootAuto, petResults(1), {}, nil)
local revealAuto = find(rootAuto, "HatchReveal")
assert(revealAuto and not find(revealAuto, "HatchEgg") and find(revealAuto, "HatchFlash"), "yumurta verilmezse animasyon olmamalı")
print("reveal multi/auto ok")
