-- Oyuncu ayarları (Settings penceresi ve teyp bunu kullanır). Ayar, LocalPlayer'ın aynı adlı özniteliğidir: false = kapalı, yoksa/true = açık.
-- Değişiklik hemen bu istemcide uygulanır (diğer modüller özniteliğe bakar) ve sunucuya yollanır; sunucu kaydeder, girişte öznitelik olarak geri verir.
-- Ayar anahtarları Config.Settings'te tanımlıdır (SfxOn, MusicOn, ShowGain, CameraShake, NameTags).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerSettings = {}

local player = Players.LocalPlayer

function PlayerSettings.get(key)
	return player:GetAttribute(key) ~= false
end

function PlayerSettings.set(key, value)
	if PlayerSettings.get(key) == value then
		return
	end
	player:SetAttribute(key, value)
	local shop = ReplicatedStorage:FindFirstChild("Shop")
	if shop then
		task.spawn(pcall, shop.InvokeServer, shop, "SetSetting", key, value)
	end
end

return PlayerSettings
