-- DÜNYALAR (World 2, 2026-10-20): Layout.world düzeni (World 1 eskisiyle aynı, World 2 kayık koridor, can/ödül kesintisiz),
-- kayıt alanları (Worlds / World; eski kayıt World 1), dünya açma ve geçiş (PlayerStats.unlockWorld / setWorld).
local S = require("./stubs")
local Config = require("./Config")
local Layout = require("./Layout")
local PlayerStats = require("./PlayerStats")

-- 1) World 1 = modülün kendi alanları (eski kod değişmeden çalışır), eski can formülü birebir
local W1, W2 = Layout.world(1), Layout.world(2)
assert(Layout.worldCount == #Config.Worlds.List and Layout.worldCount >= 2, "en az iki dünya olmalı")
assert(W1.originX == 0 and Layout.wallZ(7) == W1.wallZ(7) and Layout.maxHp(42) == W1.maxHp(42) and Layout.reward(5) == W1.reward(5), "Layout'un kendi alanları World 1 olmalı")
local cfg = Config.Wall
for index = 1, cfg.Count do
	local stage = (index - 1) // cfg.GroupSize + 1
	local list = cfg.GroupHealth
	local base = if stage <= #list then list[stage] else math.floor(list[#list] * cfg.HealthGrowthAfter ^ (stage - #list) + 0.5)
	local step = cfg.GroupHealthSteps[(index - 1) % cfg.GroupSize + 1]
	assert(W1.maxHp(index) == math.max(1, math.floor(base * step + 0.5)), `World 1 duvar canı eski formülle aynı olmalı: duvar {index}`)
end
-- 2) World 2: koridor yana kayık, Z aynı, 20 aşama; can ve ödül World 1'in sonundan DEVAM eder
assert(W2.originX > 600 and W2.StageCount == 20 and W2.wallZ(1) == W1.wallZ(1), "World 2 koridoru yana kayık ve 20 aşama olmalı")
assert(W2.wallPosition(1).X == W2.originX and W2.spawn.X == Config.SpawnPosition.X + W2.originX, "World 2 duvarları ve doğma yeri kendi koridorunda olmalı")
assert(W2.maxHp(1) > W1.maxHp(cfg.Count - cfg.GroupSize + 1), "World 2'nin 1. aşaması World 1'in 20. aşamasından dayanıklı olmalı (aşamaların ilk duvarları)")
assert(W2.reward(1) > W1.reward(W1.StageCount) * 2, "World 2'nin 1. aşama ödülü World 1'in son aşamasını iki kez yapmaktan fazla olmalı")
for stage = 2, W2.StageCount do
	assert(W2.reward(stage) > W2.reward(stage - 1) * 2, "ödül kuralı World 2'de de geçerli: aşama " .. stage)
	assert(W2.maxHp((stage - 1) * 5 + 1) > W2.maxHp((stage - 2) * 5 + 1), "World 2 canı aşama aşama artmalı")
end
assert(#W2.cfg.Themes == W2.StageCount and W2.theme(1).name ~= W1.theme(1).name, "World 2'nin 20 kendi teması olmalı")
for _, theme in W2.cfg.Themes do
	assert(theme.transparency == nil, "duvar temaları saydam olamaz: " .. theme.name)
end
-- withinReach yalnız kendi koridorunda; worldAt en yakın dünya
local front = S.Vector3.new(W2.originX, 3, W2.wallZ(1) + cfg.Thickness / 2 + 2)
assert(W2.withinReach(1, front) and not W1.withinReach(1, front), "vuruş menzili dünyanın kendi koridorunda olmalı")
assert(Layout.worldAt(front) == W2 and Layout.worldAt(S.Vector3.new(0, 3, 0)) == W1, "worldAt doğru dünyayı bulmalı")

-- 3) Kayıt: eski kayıtta dünya alanı yok -> World 1, yalnız World 1 açık
PlayerStats.init()
local function join(userId, name)
	local player = S.newInstance("Player")
	player.Name = name
	player.UserId = userId
	rawset(player, "DisplayName", name)
	rawset(player, "Parent", {})
	S.events.PlayerAdded(player)
	return player
end
S.datastore["Player_9901"] = { Muscle = 50, Wins = 10, Level = 3, Rebirths = 2 }
local old = join(9901, "OldSave")
assert(PlayerStats.currentWorld(old) == 1 and old:GetAttribute("World") == 1 and old:GetAttribute("WorldsUnlocked") == "1", "eski kayıt World 1'de başlamalı")
assert(PlayerStats.worldUnlocked(old, 1) and not PlayerStats.worldUnlocked(old, 2), "eski kayıtta World 2 kapalı olmalı")
-- 4) Kapalı dünyaya geçilemez; açılınca geçilir ve kaydedilir
assert(PlayerStats.setWorld(old, 2) == false and PlayerStats.currentWorld(old) == 1, "kapalı dünyaya geçilemez")
assert(PlayerStats.unlockWorld(old, 2) == true and PlayerStats.unlockWorld(old, 2) == false, "dünya bir kez açılır")
assert(PlayerStats.unlockWorld(old, 99) == false, "olmayan dünya açılamaz")
assert(old:GetAttribute("WorldsUnlocked") == "1,2", "açık dünyalar özniteliği: " .. tostring(old:GetAttribute("WorldsUnlocked")))
assert(PlayerStats.setWorld(old, 2) == true and PlayerStats.currentWorld(old) == 2 and old:GetAttribute("World") == 2, "açık dünyaya geçilmeli")
PlayerStats.saveNow(old)
local saved = S.datastore["Player_9901"]
assert(saved.World == 2 and table.find(saved.Worlds, 2) and table.find(saved.Worlds, 1), "dünya kaydı yazılmalı")
-- 5) Kayıtlı dünya yüklenir; bozuk kayıt güvenli: açık olmayan dünya seçili olamaz
S.datastore["Player_9902"] = { Muscle = 1, Wins = 1, Level = 1, Rebirths = 0, Worlds = { 1, 2 }, World = 2 }
local back = join(9902, "Back")
assert(PlayerStats.currentWorld(back) == 2 and PlayerStats.worldUnlocked(back, 2), "kayıtlı World 2 yüklenmeli")
S.datastore["Player_9903"] = { Muscle = 1, Wins = 1, Level = 1, Rebirths = 0, Worlds = { 1, "x", 77 }, World = 2 }
local broken = join(9903, "Broken")
assert(PlayerStats.currentWorld(broken) == 1 and not PlayerStats.worldUnlocked(broken, 2), "bozuk dünya kaydı World 1'e düşmeli")
-- 6) Rebirth dünyayı değiştirmez (yalnız level ve kas)
PlayerStats.dev(back, "MaxLevel")
PlayerStats.rebirth(back)
assert(PlayerStats.currentWorld(back) == 2, "rebirth sonrası oyuncu World 2'de kalmalı")

print("world test ok")
