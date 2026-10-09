-- Auto Click game pass'i (server/AutoClickPass): ID 0 iken herkes için açık; ID varken sahiplik sunucuda sorulur ('HasAutoClick' özniteliği), satın alınca anında true olur ve oyuncuya mesaj gider.
local S = require("./stubs")

local added = {} -- Players.PlayerAdded dinleyicileri
local purchaseHandlers = {} -- MarketplaceService.PromptGamePassPurchaseFinished dinleyicileri
local owners = {} -- [userId] = sahip olduğu pass ID'si
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
		return owners[userId] == passId
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
local AutoClickPass = require("./AutoClickPass")

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
	FireClient = function(_, _, _, message)
		table.insert(messages, message)
	end,
}

local function join(userId)
	local player = fakePlayer(userId)
	added[#added](player)
	return player
end

-- 1) Pass satılmıyorken (ID 0) herkes için Auto Click açık
Config.AutoClick.GamePassId = 0
AutoClickPass.init(notifyEvent)
assert(join(1):GetAttribute("HasAutoClick") == true, "pass yokken Auto Click serbest olmalı")
assert(#purchaseHandlers == 0, "pass yokken satın alma dinleyicisi gerekmez")

-- 2) Pass satılıyor: sahip olan true, olmayan false
added, purchaseHandlers = {}, {}
Config.AutoClick.GamePassId = 777
owners[10] = 777
AutoClickPass.init(notifyEvent)
assert(join(10):GetAttribute("HasAutoClick") == true, "pass'e sahip oyuncuda true olmalı")
local buyer = join(11)
assert(buyer:GetAttribute("HasAutoClick") == false, "pass'i olmayanda false olmalı")

-- 3) Satın alma tamamlanınca anında true + mesaj; başka pass ya da iptal edilen satın alma etkilemez
purchaseHandlers[1](buyer, 999, true)
assert(buyer:GetAttribute("HasAutoClick") == false, "başka pass satın alınınca değişmemeli")
purchaseHandlers[1](buyer, 777, false)
assert(buyer:GetAttribute("HasAutoClick") == false, "iptal edilen satın alma açmamalı")
purchaseHandlers[1](buyer, 777, true)
assert(buyer:GetAttribute("HasAutoClick") == true, "satın alınca anında açılmalı")
assert(#messages == 1 and string.find(messages[1], "Auto Click unlocked", 1, true), "satın alınca mesaj gitmeli")
-- 4) DEV 'Passes Lock': sahip olsa bile false (kilit denemesi); DEV kilidi kalkınca gerçek sahiplik; satın alma DEV kilidini de kaldırır
local owner = join(10)
assert(owner:GetAttribute("HasAutoClick") == true, "sahip: true")
owner:SetAttribute("DevPassLock", true)
AutoClickPass.recheck(owner)
assert(owner:GetAttribute("HasAutoClick") == false, "DEV kilidi açıkken sahip olsa da false olmalı")
owner:SetAttribute("DevPassLock", nil)
AutoClickPass.recheck(owner)
assert(owner:GetAttribute("HasAutoClick") == true, "DEV kilidi kalkınca gerçek sahiplik dönmeli")
owner:SetAttribute("DevPassLock", true)
AutoClickPass.recheck(owner)
purchaseHandlers[#purchaseHandlers](owner, 777, true)
assert(owner:GetAttribute("HasAutoClick") == true and owner:GetAttribute("DevPassLock") == nil, "satın alma DEV kilidini kaldırmalı")
Config.AutoClick.GamePassId = 0
print("auto click pass ok")
print("DONE")
