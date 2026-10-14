-- ROBLOX ROZETLERİ (büyüme planı: rakiplerde var, oyuncu profilinde görünür, bedava reklam ve 'tamamlama' hissi; araştırma research/02-03): Config.Badges'taki her rozet bir Roblox rozetidir (BadgeService:AwardBadge).
-- Rozet kimliği (id) 0 iken o rozet PASİFTİR: sahibi Creator Hub'da (Engagement > Badges) rozeti oluşturup kimliğini Config.Badges[anahtar].id'ye yazınca (tools/set_robux_ids.py değil, doğrudan Config) devreye girer.
-- Oturum başına her rozet en çok bir kez istenir (Roblox zaten aynı rozeti iki kez vermez). Hata verirse (rozet yok, Studio) sessizce atlanır, oyun etkilenmez.
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Badges = {}

local askedThisSession = setmetatable({}, { __mode = "k" }) -- [oyuncu] = { anahtar = true }

-- key: Config.Badges anahtarı. Dönüş: bu çağrıda Roblox'tan istendi mi
function Badges.award(player, key)
	local def = Config.Badges[key]
	if not def or type(def.id) ~= "number" or def.id <= 0 then
		return false
	end
	local asked = askedThisSession[player]
	if not asked then
		asked = {}
		askedThisSession[player] = asked
	end
	if asked[key] then
		return false
	end
	asked[key] = true
	task.spawn(function()
		local ok, err = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, def.id)
		if not ok then
			warn(`[Badges] Could not award {key}: {err}`)
		end
	end)
	return true
end

return Badges
