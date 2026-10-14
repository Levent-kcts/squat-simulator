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

-- ---- EggRules: kural tablosu (İKİ pass: Auto Open ve Multi Open; Multi hem x3 hem x10 modunu açar)
local auto, multi = EggRules.pass("auto"), EggRules.pass("multi")
assert(auto and multi and multi.count == 10 and #Config.EggPasses == 2, "Config.EggPasses: yalnız auto ve multi (count 10) olmalı")
assert(EggRules.passForCount(1) == nil and EggRules.passForCount(0) == nil, "tek yumurta ücretsiz")
assert(EggRules.passForCount(2) == multi and EggRules.passForCount(3) == multi, "x2-x3 Multi ister")
assert(EggRules.passForCount(4) == multi and EggRules.passForCount(10) == multi and EggRules.passForCount(99) == multi, "x4 ve üstü de Multi ister")
assert(EggRules.autoPass() == auto, "autoPass")

-- T tuşu (EggRules.step): imleç x1 > x3 > x10 > x1 gezer; kilitli seçenekte seçim DEĞİŞMEZ ama Multi pass'i döner; açıkta seçilir
local options = Config.EggMultiOptions
local function ownsOnly(...)
	local set = {}
	for _, pass in { ... } do
		set[pass] = true
	end
	return function(pass)
		return pass == nil or set[pass] == true
	end
end
local cursorAfter, selectedCount, lockedPass = EggRules.step(options, 1, ownsOnly())
assert(cursorAfter == 2 and selectedCount == nil and lockedPass == multi, "pass yokken T x3'e gelir ama SEÇMEZ ve Multi'yi önerir")
cursorAfter, selectedCount, lockedPass = EggRules.step(options, 2, ownsOnly())
assert(cursorAfter == 3 and selectedCount == nil and lockedPass == multi, "imleç x10'a gelir, seçmez, yine Multi'yi önerir")
cursorAfter, selectedCount, lockedPass = EggRules.step(options, 3, ownsOnly())
assert(cursorAfter == 1 and selectedCount == 1 and lockedPass == nil, "imleç x1'e dönünce x1 her zaman seçilir")
cursorAfter, selectedCount, lockedPass = EggRules.step(options, 1, ownsOnly(multi))
assert(cursorAfter == 2 and selectedCount == 3 and lockedPass == nil, "Multi varken x3 seçilir")
cursorAfter, selectedCount, lockedPass = EggRules.step(options, 2, ownsOnly(multi))
assert(cursorAfter == 3 and selectedCount == 10 and lockedPass == nil, "Multi varken x10 seçilir (T ile modlar arasında gezilir)")

-- ---- Fiyatlar: 150'nin üstünde ama makul (sahibi bu iki ürün için sınırı kaldırdı)
for _, pass in Config.EggPasses do
	assert(pass.Robux > 0 and pass.Robux <= 400, `{pass.id}: fiyat makul olmalı (<= 400): {pass.Robux}`)
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
local okThree, whyThree = EggShop.checkPasses(p1, 3, false)
assert(not okThree and string.find(whyThree, "Multi Open", 1, true), "x3 kilitliyken reddedilmeli: " .. tostring(whyThree))
assert(not EggShop.checkPasses(p1, 10, false), "x10 kilitliyken reddedilmeli")
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
multi.GamePassId = 2222
auto.GamePassId = 3333
owners[2] = { [2222] = true } -- sadece Multi'ye sahip
local p2 = fakePlayer(2)
EggPasses.recheck(p2)
assert(p2:GetAttribute(multi.attribute) == true, "sahip olunan pass açık")
assert(p2:GetAttribute(auto.attribute) == false, "sahip olunmayan pass kilitli")
assert(EggShop.checkPasses(p2, 3, false) and EggShop.checkPasses(p2, 10, false), "Multi sahibi hem x3 hem x10 açabilir")
assert(not EggShop.checkPasses(p2, 1, true), "Multi sahibi otomatik açamaz (Auto ayrı pass)")
-- DEV 'Passes Lock': sahip olsa bile kilitli
p2:SetAttribute("DevPassLock", true)
EggPasses.recheck(p2)
assert(p2:GetAttribute(multi.attribute) == false, "Passes Lock: kilitli görünür")
p2:SetAttribute("DevPassLock", nil)
EggPasses.recheck(p2)
assert(p2:GetAttribute(multi.attribute) == true, "kilit kalkınca tekrar açık")

-- Satın alma: Auto alınınca anında açılır ve mesaj gider; iptal edilirse değişmez
assert(#purchaseHandlers >= 1, "satın alma dinleyicisi kurulmalı")
local handler = purchaseHandlers[#purchaseHandlers]
messages = {}
handler(p2, 3333, false)
assert(p2:GetAttribute(auto.attribute) == false, "iptal edilen satın alma açmamalı")
handler(p2, 3333, true)
assert(p2:GetAttribute(auto.attribute) == true, "satın alınca anında açılmalı")
assert(#messages == 1 and messages[1].ok == true and string.find(messages[1].message, "Auto Open", 1, true), "satın alma mesajı: " .. tostring(messages[1] and messages[1].message))
handler(p2, 9999, true) -- tanınmayan pass
print("EggPasses ok")
