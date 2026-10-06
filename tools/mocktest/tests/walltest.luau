-- Duvar hasarı: aşama içinde artan canlar (25, 30, 40, 50, 60), taşan hasarın aşama sonunu geçmemesi ve kırılan duvar sayısı (günlük görev için)
local S = require("./cstubs")
local Config = require("./Config")
local Layout = require("./Layout")
local Wall = require("./WallService")

local notify = S.newInstance("RemoteEvent")
Wall.init(notify)

local player = S.newInstance("Player")
player.Name = "WallTester"
player.UserId = 5
rawset(player, "Parent", S.newInstance("Players"))
for _, handler in S.playerAdded do
	pcall(handler, player)
end

local character = S.newInstance("Model")
local root = S.newInstance("Part")
root.Position = S.Vector3.new(0, 3, Layout.wallZ(1) + Config.Wall.Thickness / 2 + 4) -- 1. duvarın önü, vuruş menzilinde
rawget(character, "_children")["HumanoidRootPart"] = root
player.Character = character

local expected = { 25, 30, 40, 50, 60 }
for index, hp in expected do
	assert(Layout.maxHp(index) == hp, "duvar " .. index .. " can " .. Layout.maxHp(index) .. " beklenen " .. hp)
end
print("HP 1-5:", table.concat({ Layout.maxHp(1), Layout.maxHp(2), Layout.maxHp(3), Layout.maxHp(4), Layout.maxHp(5) }, ", "))

-- 100 hasar: 25 + 30 + 40 = 95 -> ilk üç duvar kırılır, 4. duvardan 5 can gider
local hit, broken = Wall.hit(player, 100)
print("hit(100):", hit, "broken:", broken)
assert(hit == true and broken == 3, "100 hasarla 3 duvar kırılmalıydı, kırılan: " .. tostring(broken))

-- 1. vuruştan sonra ilk sağlam duvar 4. oldu (28 stud ileride): oyuncu menzil dışındayken vuruş işlemez, 4. duvarın önüne yürüyünce işler
root.Position = S.Vector3.new(0, 3, Layout.wallZ(4) + Config.Wall.Thickness / 2 + 4)
-- Çok büyük hasar: yalnızca aşamanın kalan 2 duvarını kırar (4. ve 5.), 6. duvara geçmez
local hit2, broken2 = Wall.hit(player, 10 ^ 12)
print("hit(1e12):", hit2, "broken:", broken2)
assert(hit2 == true and broken2 == 2, "aşama sonunu geçmemeli, kırılan: " .. tostring(broken2))

-- Aşama bitti, ilk sağlam duvar 6. (uzakta): oyuncu menzilde olmadığı için vuruş geçmez
local hit3, broken3 = Wall.hit(player, 10 ^ 12)
print("hit(1e12) out of reach:", hit3, broken3)
assert(hit3 == false, "menzil dışındayken hasar işlememeli")
print("DONE")
