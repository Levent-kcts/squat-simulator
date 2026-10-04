-- Ses efektleri: Config.Sounds'taki olay adlarını çalar. Sol menüdeki "Sounds" anahtarı kapalıysa (SoundsOn = false) hiçbir şey çalmaz.
-- Bir olayın tek sesi (id) ya da rastgele seçilen birkaç sesi (ids) olabilir. Ses dosyası yüklenemezse (kaldırılmış, izin yok) elenir;
-- hepsi elenirse fallback çalar, o da yoksa o olay sessiz kalır. Oyun hiçbir durumda etkilenmez.
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Sfx = {}

local player = Players.LocalPlayer
local rng = Random.new()
local lastPlayed = {} -- [olay] = zaman: aynı ses saniyede çok sık çalıp kulağı yormasın
local failed = {} -- [ses id'si] = true: yüklenemeyen sesler bir daha denenmez
local MIN_GAP = 0.06

-- Bu seferlik çalınacak ses id'si (yüklenemeyenler elenir)
local function pickId(def)
	local list = def.ids or { def.id }
	local usable = {}
	for _, id in list do
		if id ~= nil and id ~= "" and not failed[id] then
			table.insert(usable, id)
		end
	end
	if #usable > 0 then
		return usable[rng:NextInteger(1, #usable)]
	end
	return def.fallback
end

function Sfx.play(name)
	local def = Config.Sounds and Config.Sounds[name]
	if not def then
		return
	end
	if player:GetAttribute("SoundsOn") == false then
		return
	end
	local now = os.clock()
	if now - (lastPlayed[name] or 0) < (def.gap or MIN_GAP) then
		return
	end
	local id = pickId(def)
	if id == nil or id == "" then
		return
	end
	lastPlayed[name] = now

	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = def.volume or 0.5
	local speed = def.speed
	if speed then
		sound.PlaybackSpeed = rng:NextNumber(speed[1], speed[2])
	end
	sound.Parent = SoundService
	sound:Play()
	-- Süre bilinmeden silmemek için bitişte; yüklenemezse de 5 saniye sonra temizlenir
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	Debris:AddItem(sound, 5)
end

-- Tüm ses dosyalarını önceden yükler; yüklenemeyenleri işaretler (Sfx.play onları atlar)
local function preload()
	local probes = {}
	for _, def in Config.Sounds or {} do
		for _, id in def.ids or { def.id } do
			if id ~= nil and id ~= "" and string.find(id, "^rbxassetid://") then
				local probe = Instance.new("Sound")
				probe.SoundId = id
				table.insert(probes, probe)
			end
		end
	end
	pcall(ContentProvider.PreloadAsync, ContentProvider, probes, function(contentId, status)
		if status == Enum.AssetFetchStatus.Failure then
			failed[contentId] = true
			warn(`[Sfx] Ses yüklenemedi, atlanıyor: {contentId}`)
		end
	end)
	for _, probe in probes do
		probe:Destroy()
	end
end

-- Arka plan müziğini başlatır (Config.Music.id doluysa). "Sounds" anahtarı kapanınca sesi 0 olur.
function Sfx.init()
	task.spawn(preload)

	local music = Config.Music
	if not music or music.id == nil or music.id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "Music"
	sound.SoundId = music.id
	sound.Looped = true
	sound.Parent = SoundService
	local function apply()
		sound.Volume = if player:GetAttribute("SoundsOn") == false then 0 else (music.volume or 0.25)
	end
	apply()
	player:GetAttributeChangedSignal("SoundsOn"):Connect(apply)
	sound:Play()
end

return Sfx
