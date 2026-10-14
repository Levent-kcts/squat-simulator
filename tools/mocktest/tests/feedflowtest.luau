-- DUYURU AKIŞI OYUN BAĞLANTISI (büyüme planı sprint 1.1): ilk rebirth (eşik) ve yumurtadan çıkan Legendary/Mythic pet duyurulur; Common/Rare/Epic ve silinen petler duyurulmaz.
local S = require("./stubs")
local Config = require("./Config")
local Catalog = require("./Catalog")
local PlayerStats = require("./PlayerStats")
local GlobalFeed = require("./GlobalFeed")

PlayerStats.init()
GlobalFeed.init()
local delivered = {}
rawset(GlobalFeed.remote, "FireAllClients", function(_, kind, text, tier)
	table.insert(delivered, { kind = kind, text = text, tier = tier })
end)

local hero = S.newInstance("Player")
hero.Name = "Hero"
hero.UserId = 9950
rawset(hero, "DisplayName", "Hero")
rawset(hero, "Parent", {})
S.events.PlayerAdded(hero)
local stats = hero:FindFirstChild("leaderstats")

-- 1) Rebirth 1 eşiği duyurulur
PlayerStats.dev(hero, "MaxLevel")
local ok = PlayerStats.rebirth(hero, true)
assert(ok == true, "rebirth başarılı olmalı")
assert(#delivered == 1 and delivered[1].kind == "rebirth" and delivered[1].text == "Hero reached Rebirth 1!", "rebirth 1 duyurulmalı: " .. tostring(delivered[1] and delivered[1].text))

-- 2) Yumurta: Legendary/Mythic çıkana kadar aç (Luck iksiriyle); duyuru en nadir kalan petin adını taşır. 20 sn oyuncu sınırı: sınır penceresi için ikinci oyuncu kullanılır
local hatcher = S.newInstance("Player")
hatcher.Name = "Hatcher"
hatcher.UserId = 9951
rawset(hatcher, "DisplayName", "Hatcher")
rawset(hatcher, "Parent", {})
S.events.PlayerAdded(hatcher)
PlayerStats.dev(hatcher, "AddWins", 1e9)
PlayerStats.dev(hatcher, "PotionLuck")
local rare = nil
for _ = 1, 8 do
	local before = #delivered
	local okHatch, _, results = PlayerStats.hatchEgg(hatcher, "galaxy", 10)
	if okHatch then
		for _, result in results do
			local name = Catalog.rarityOf(Catalog.PetById[result.id]).name
			if result.kept and (name == "Legendary" or name == "Mythic") then
				rare = Catalog.PetById[result.id]
			end
		end
		if rare then
			assert(#delivered == before + 1, "nadir pet çıkınca TEK duyuru gelmeli")
			local last = delivered[#delivered]
			assert(last.kind == "pet" and string.find(last.text, "^Hatcher hatched a ") and (last.tier == "Legendary" or last.tier == "Mythic"), "duyuru metni: " .. last.text)
			assert(string.find(last.text, string.upper(last.tier), 1, true), "duyuruda nadirlik adı büyük harfle yazmalı: " .. last.text)
			break
		else
			assert(#delivered == before, "Common/Rare/Epic petler duyurulmamalı")
		end
	end
	-- envanter dolmasın: tüm petleri sil
	PlayerStats.dev(hatcher, "FreePet")
	for _, pet in Config.Pets do
		pcall(PlayerStats.toggleAutoDelete, hatcher, pet.id)
	end
end
assert(rare, "Luck iksiriyle 8 x 10 yumurtada en az bir Legendary/Mythic çıkmalı (duyuru yolu denenmeli)")
print("feed flow ok", rare.id)
