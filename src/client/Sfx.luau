-- Ses efektleri: Config.Sounds'taki olay adlarını çalar. Sol menüdeki "Sounds" anahtarı kapalıysa (SoundsOn = false) hiçbir şey çalmaz.
-- Bir olayın tek sesi (id) ya da birkaç sesi (ids) olabilir: varsayılan rastgele seçilir, pick = "first" ise yüklenebilen ilki çalar.
-- Ses dosyası yüklenemezse (kaldırılmış, izin yok) elenir; hepsi elenirse fallback çalar, o da yoksa o olay sessiz kalır.
-- Sesler oyun başında BİR KERE yüklenir ve havuzdan çalınır (her seferinde yeni Sound kurulsaydı çalma gecikirdi). Oyun hiçbir durumda etkilenmez.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Sfx = {}

local player = Players.LocalPlayer
local rng = Random.new()
local lastPlayed = {} -- [olay] = zaman: aynı ses saniyede çok sık çalıp kulağı yormasın
local failed = {} -- [ses id'si] = true: yüklenemeyen sesler bir daha denenmez
local pools = {} -- [ses id'si] = { Sound, ... }: önceden kurulmuş, yüklenmiş sesler
local MIN_GAP = 0.06
local POOL_SIZE = 3 -- aynı ses üst üste bindiğinde en fazla bu kadar kopya

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
		if def.pick == "first" then
			return usable[1]
		end
		return usable[rng:NextInteger(1, #usable)]
	end
	return def.fallback
end

local function newSound(id)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Parent = SoundService
	return sound
end

-- Havuzdan çalmayan bir kopya verir; hepsi çalıyorsa yeni kopya kurar, havuz doluysa ilkini baştan çalar
local function acquire(id)
	local pool = pools[id]
	if not pool then
		pool = { newSound(id) }
		pools[id] = pool
	end
	for _, sound in pool do
		if not sound.IsPlaying then
			return sound
		end
	end
	if #pool < POOL_SIZE then
		local sound = newSound(id)
		table.insert(pool, sound)
		return sound
	end
	return pool[1]
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

	local sound = acquire(id)
	sound.Volume = def.volume or 0.5
	local speed = def.speed
	sound.PlaybackSpeed = if speed then rng:NextNumber(speed[1], speed[2]) else 1
	sound.TimePosition = 0
	sound:Play()
end

-- Tüm ses dosyalarını önceden kurar ve yükler; yüklenemeyenleri işaretler (Sfx.play onları atlar)
local function preload()
	local sounds = {}
	for _, def in Config.Sounds or {} do
		local list = { def.fallback }
		for _, id in def.ids or { def.id } do
			table.insert(list, id)
		end
		for _, id in list do
			if id ~= nil and id ~= "" and not pools[id] then
				local sound = newSound(id)
				pools[id] = { sound }
				table.insert(sounds, sound)
			end
		end
	end
	pcall(ContentProvider.PreloadAsync, ContentProvider, sounds, function(contentId, status)
		if status == Enum.AssetFetchStatus.Failure then
			failed[contentId] = true
			warn(`[Sfx] Ses yüklenemedi, atlanıyor: {contentId}`)
			for _, sound in pools[contentId] or {} do
				sound:Destroy()
			end
			pools[contentId] = nil
		end
	end)
end

-- Arka plan müziği: Config.Music.tracks sırayla çalar, liste bitince baştan başlar. Yüklenemeyen parça atlanır;
-- hiçbiri çalmazsa döngü durur (sonsuz hızlı deneme olmasın). "Sounds" anahtarı kapanınca sesi 0 olur.
local function playlist(music)
	local tracks = music.tracks
	local sound = Instance.new("Sound")
	sound.Name = "Music"
	sound.Looped = false
	sound.Parent = SoundService
	local function apply()
		sound.Volume = if player:GetAttribute("SoundsOn") == false then 0 else (music.volume or 0.2)
	end
	apply()
	player:GetAttributeChangedSignal("SoundsOn"):Connect(apply)

	local index = 1
	local skipped = 0 -- üst üste çalınamayan parça sayısı
	while skipped < #tracks do
		sound.SoundId = tracks[index]
		local started = os.clock()
		while not sound.IsLoaded and os.clock() - started < 15 do
			task.wait(0.1)
		end
		if sound.IsLoaded and sound.TimeLength > 0 then
			skipped = 0
			-- Sıradaki parçayı çalarken önceden indir: geçişte boşluk kalmasın
			local nextId = tracks[index % #tracks + 1]
			task.spawn(function()
				local probe = Instance.new("Sound")
				probe.SoundId = nextId
				pcall(ContentProvider.PreloadAsync, ContentProvider, { probe })
				probe:Destroy()
			end)
			sound:Play()
			sound.Ended:Wait()
		else
			skipped += 1
			warn(`[Sfx] Müzik parçası yüklenemedi, atlanıyor: {tracks[index]}`)
		end
		index = index % #tracks + 1
	end
	warn("[Sfx] Hiçbir müzik parçası çalınamadı, müzik kapalı.")
	sound:Destroy()
end

function Sfx.init()
	task.spawn(preload)

	local music = Config.Music
	if music and music.tracks and #music.tracks > 0 then
		task.spawn(playlist, music)
	end
end

return Sfx
