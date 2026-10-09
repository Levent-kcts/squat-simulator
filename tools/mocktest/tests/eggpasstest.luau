-- Yumurta game pass'leri: shared/EggRules (hangi açma hangi pass'i ister), server/EggPasses (sahiplik ve DEV anahtarları, satın alma) ve EggShop.checkPasses (sunucuda zorlama)
local S = require("./stubs")

local added = {}
local purchaseHandlers = {}
local owners = {} -- [userId] = { [passId] = true }
local players = {
	PlayerAdded = {
		Connect = function(_, f)
			table.insert(added, f)
			return { Disconnect = function() end }
		end,
	},
	GetPlayers = function()
		return {}
	end,
}
local market = {
	UserOwnsGamePassAsync = function(_, userId, passId)
		return owners[userId] ~= nil and owners[userId][passId] == true
	end,
	PromptGamePassPurchaseFinished = {
		Connect = function(_, f)
			table.insert(purchaseHandlers, f)
			return { Disconnect = function() end }
		end,
	},
}
local originalGetService = S.game.GetService
S.game.GetService = function(self, name)
	if name == "Players" then
		return players
	elseif name == "MarketplaceService" then
		return market
	end
	return originalGetService(self, name)
end

local Config = require("./Config")
local EggRules = require("./EggRules")
local EggPasses = require("./EggPasses")
local EggShop = require("./EggShop")

-- ---- EggRules: kural tablosu
local auto, triple, ten = EggRules.pass("auto"), EggRules.pass("triple"), EggRules.pass("ten")
assert(auto and triple and ten and triple.count == 3 and ten.count == 10, "Config.EggPasses: auto, triple (3), ten (10) olmalı")
assert(EggRules.passForCount(1) == nil and EggRules.passForCount(0) == nil, "tek yumurta ücretsiz")
assert(EggRules.passForCount(2) == triple and EggRules.passForCount(3) == triple, "x2-x3 Triple ister")
assert(EggRules.passForCount(4) == ten and EggRules.passForCount(10) == ten and EggRules.passForCount(99) == ten, "x4 ve üstü Mega ister")
assert(EggRules.autoPass() == auto, "autoPass")

-- ---- Fiyatlar: 150'nin üstünde ama makul (sahibi bu üç ürün için sınırı kaldırdı)
for _, pass in Config.EggPasses do
	assert(pass.Robux > 150 and pass.Robux <= 400, `{pass.id}: fiyat 150 ile 400 arasında olmalı: {pass.Robux}`)
	assert(type(pass.attribute) == "string" and pass.attribute ~= "", pass.id .. ": öznitelik adı")
end

-- ---- Sahte oyuncu
local function fakePlayer(userId)
	local attributes = {}
	local player = { UserId = userId, Parent = {} }
	function player:SetAttribute(key, value)
		attributes[key] = value
	end
	function player:GetAttribute(key)
		return attributes[key]
	end
	return player
end
local messages = {}
local notifyEvent = {
	FireClient = function(_, _, ok, message)
		table.insert(messages, { ok = ok, message = message })
	end,
}

-- 1) Hiçbir pass satışa açık değil (GamePassId 0): hepsi KİLİTLİ, x1 serbest
for _, pass in Config.EggPasses do
	pass.GamePassId = 0
end
EggPasses.init(notifyEvent)
local p1 = fakePlayer(1)
for _, f in added do
	f(p1)
end
for _, pass in Config.EggPasses do
	assert(p1:GetAttribute(pass.attribute) == false, pass.id .. ": satışa açık değilken kilitli olmalı")
end
local okOne = EggShop.checkPasses(p1, 1, false)
assert(okOne, "tek yumurta elle açmak hep serbest")
local okTriple, whyTriple = EggShop.checkPasses(p1, 3, false)
assert(not okTriple and string.find(whyTriple, "Triple Open", 1, true), "x3 kilitliyken reddedilmeli: " .. tostring(whyTriple))
local okTen = EggShop.checkPasses(p1, 10, false)
assert(not okTen, "x10 kilitliyken reddedilmeli")
local okAuto, whyAuto = EggShop.checkPasses(p1, 1, true)
assert(not okAuto and string.find(whyAuto, "Auto Open", 1, true), "otomatik açma kilitliyken reddedilmeli: " .. tostring(whyAuto))

-- 2) DEV 'Egg Upgrades (test)': üçü de açılır; kapatınca tekrar kilitlenir
p1:SetAttribute("DevEggPasses", true)
EggPasses.recheck(p1)
for _, pass in Config.EggPasses do
	assert(p1:GetAttribute(pass.attribute) == true, pass.id .. ": DEV açıkken açık olmalı")
end
assert(EggShop.checkPasses(p1, 10, true), "DEV açıkken x10 + otomatik serbest")
p1:SetAttribute("DevEggPasses", nil)
EggPasses.recheck(p1)
assert(p1:GetAttribute(auto.attribute) == false, "DEV kapanınca tekrar kilitli")

-- 3) Satışa açık pass: sahiplik sunucuda sorulur; satın alma anında açar ve mesaj yollar
triple.GamePassId = 1111
ten.GamePassId = 2222
auto.GamePassId = 3333
owners[2] = { [1111] = true } -- sadece Triple'a sahip
local p2 = fakePlayer(2)
EggPasses.recheck(p2)
assert(p2:GetAttribute(triple.attribute) == true, "sahip olunan pass açık")
assert(p2:GetAttribute(ten.attribute) == false and p2:GetAttribute(auto.attribute) == false, "sahip olunmayan pass kilitli")
assert(EggShop.checkPasses(p2, 3, false), "Triple sahibi x3 açabilir")
assert(not EggShop.checkPasses(p2, 10, false), "Triple sahibi x10 açamaz")
assert(not EggShop.checkPasses(p2, 3, true), "Triple sahibi otomatik açamaz")
-- DEV 'Passes Lock': sahip olsa bile kilitli
p2:SetAttribute("DevPassLock", true)
EggPasses.recheck(p2)
assert(p2:GetAttribute(triple.attribute) == false, "Passes Lock: kilitli görünür")
p2:SetAttribute("DevPassLock", nil)
EggPasses.recheck(p2)
assert(p2:GetAttribute(triple.attribute) == true, "kilit kalkınca tekrar açık")

-- Satın alma: Mega alınınca anında açılır ve mesaj gider; iptal edilirse değişmez
assert(#purchaseHandlers >= 1, "satın alma dinleyicisi kurulmalı")
local handler = purchaseHandlers[#purchaseHandlers]
messages = {}
handler(p2, 2222, false)
assert(p2:GetAttribute(ten.attribute) == false, "iptal edilen satın alma açmamalı")
handler(p2, 2222, true)
assert(p2:GetAttribute(ten.attribute) == true, "satın alınca anında açılmalı")
assert(#messages == 1 and messages[1].ok == true and string.find(messages[1].message, "Mega Open", 1, true), "satın alma mesajı: " .. tostring(messages[1] and messages[1].message))
handler(p2, 9999, true) -- tanınmayan pass
print("EggPasses ok")
