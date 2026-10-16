-- Ses efektleri: Config.Sounds'taki olay adlarını çalar. Settings penceresinde "Sound effects" kapalıysa (SfxOn = false) efekt çalmaz; "Music" kapalıysa (MusicOn = false) müziğin sesi 0 olur.
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
local warming = {} -- [Sound] = true: ısınma çalması sürerken gerçek çalmada kullanılmaz
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
	-- Henüz yüklenmemiş sese basmak çalmayı geciktirir: yüklü olan varsa sadece onlar arasından seç
	local ready = {}
	for _, id in usable do
		local first = pools[id] and pools[id][1]
		if first and first.IsLoaded then
			table.insert(ready, id)
		end
	end
	if #ready > 0 then
		usable = ready
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
		if not sound.IsPlaying and not warming[sound] then
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

-- opts (isteğe bağlı): { volume = çarpan, speed = çarpan } olayın ses ve perdesini o çalış için ölçekler (Reveal: yumurta büyüdükçe 'dum' yükselir);
-- startAt = parçanın bu saniyesinden başlat, stopAfter = bu kadar sn sonra (0.06 sn'de sönerek) dur: TEK dosyadan bölüm çalmak için (Power Hour teması: giriş ve bitiş ayrı anlarda)
function Sfx.play(name, opts)
	local def = Config.Sounds and Config.Sounds[name]
	if not def then
		return
	end
	if player:GetAttribute("SfxOn") == false then
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
	sound.Volume = (def.volume or 0.5) * (opts and opts.volume or 1)
	-- fallback çalıyorsa (asıl ses henüz yüklenmedi/yüklenemedi) ona özel perde: fallbackSpeed
	local speed = if id == def.fallback and def.fallbackSpeed then def.fallbackSpeed else def.speed
	sound.PlaybackSpeed = (if speed then rng:NextNumber(speed[1], speed[2]) else 1) * (opts and opts.speed or 1)
	sound.TimePosition = (opts and opts.startAt) or def.startAt or 0
	sound:Play()
	local stopAfter = opts and opts.stopAfter
	if stopAfter then
		local volume = sound.Volume
		task.delay(stopAfter, function()
			if not sound.IsPlaying then
				return
			end
			for i = 1, 3 do
				sound.Volume = volume * (1 - i / 3)
				task.wait(0.02)
			end
			sound:Stop()
			sound.Volume = volume
		end)
	end
	return sound
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

	-- Isınma: yüklenen her sesi sessizce bir an çalıp durdururuz. Ses motoru çözme işini ilk çalmada yaparsa o ilk efekt (özellikle duvar kırılma sesi)
	-- gecikmeli duyulur; böylece çözme önceden yapılmış olur.
	local toWarm = {}
	for _, pool in pools do
		table.insert(toWarm, pool[1])
	end
	for _, sound in toWarm do
		if sound.Parent and sound.IsLoaded then
			local volume = sound.Volume
			warming[sound] = true
			sound.Volume = 0
			sound:Play()
			task.wait(0.03)
			sound:Stop()
			sound.Volume = volume
			warming[sound] = nil
		end
	end
end

-- =====================================================================
-- ARKA PLAN MÜZİĞİ (arayüzü client/MusicPlayer: ses kademesi, duraklat, önceki/sonraki şarkı, şarkı adı)
-- =====================================================================
-- Config.Music.tracks sırayla çalar, liste bitince baştan başlar. Yüklenemeyen parça atlanır; hiçbiri çalmazsa döngü durur
-- (sonsuz hızlı deneme olmasın). Settings'te "Music" kapanınca müziğin sesi 0 olur.
local musicSound = nil
local musicLevel = (Config.Music and Config.Music.defaultLevel) or 4 -- ses kademesi: 0 .. maxLevel
local currentTrack = { name = "", index = 0, total = 0 } -- çalan (ya da yüklenen) parça
local trackListeners = {}
local levelListeners = {}
local skipRequested = false
local pendingStep = 1 -- bir sonraki parça için yön: +1 sonraki, -1 önceki
local musicPaused = false
local pauseListeners = {}

local function musicMaxLevel()
	return (Config.Music and Config.Music.maxLevel) or 10
end

-- MÜZİK DEĞİŞTİRME (Sfx.playMusicOverride): Power Hour müziği bir süre normal müziğin YERİNE, sağ alttaki TEYPTEN çalar (2026-10-16, sahibi 'ses yükselme
-- azalma olmasın, sağ alttaki radyoya entegre olsun, hep aynı seste çalsın' dedi): ses = teypin müzik kademesi (normal müzikle AYNI), kısma/sönme YOK, geçişler anında;
-- normal parça o sürede DURAKLATILIR ve sonra kaldığı yerden devam eder; teypte şarkı adı olarak override adı görünür; teypin duraklat düğmesi geçerli, ileri/geri basmak
-- özel müziği bitirir. Parçalar sırayla çalar: { id, startAt = baştan sn, stopAt = bu sn'de geç, loopFor = en az bu kadar sn DÖNGÜDE çal ve bir tur bitince geç }.
local overrideSound = nil
local overrideGain = 1
local overrideToken = 0
local overrideActive = false
local playlistTrack = nil -- özel müzik çalarken normal listenin (görünmeyen) güncel parçası

local function applyMusicVolume()
	local step = (Config.Music and Config.Music.volumeStep) or 0.045
	local base = if player:GetAttribute("MusicOn") == false then 0 else musicLevel * step
	if musicSound then
		musicSound.Volume = base
	end
	if overrideSound then
		overrideSound.Volume = base * overrideGain
	end
end

local function notifyTrack()
	for _, listener in trackListeners do
		task.spawn(listener, currentTrack)
	end
end

-- Özel müziği bitirir (anında, sönmeden): normal parça kaldığı yerden devam eder, teypte eski şarkı adı döner
function Sfx.stopMusicOverride()
	if not overrideActive then
		return
	end
	overrideToken += 1
	overrideActive = false
	if overrideSound then
		overrideSound:Destroy()
		overrideSound = nil
	end
	if musicSound and not musicPaused and musicSound.IsPaused then
		musicSound:Resume()
	end
	if playlistTrack then
		currentTrack = playlistTrack
		notifyTrack()
	end
	applyMusicVolume()
end

-- parts: sırayla çalınacak bölümler (yukarıdaki açıklama). displayName: teypte görünecek ad. gain: müzik kademesine göre çarpan (1 = normal müzikle aynı ses).
function Sfx.playMusicOverride(parts, displayName, gain)
	if type(parts) ~= "table" or #parts == 0 or type(parts[1].id) ~= "string" or parts[1].id == "" then
		return false
	end
	Sfx.stopMusicOverride()
	overrideToken += 1
	local token = overrideToken
	overrideActive = true
	overrideGain = gain or 1
	if musicSound and musicSound.IsPlaying then
		musicSound:Pause() -- normal parça burada bekler (playlist döngüsü overrideActive iken ilerlemez)
	end
	playlistTrack = currentTrack
	currentTrack = { name = displayName or "Special", index = playlistTrack.index, total = playlistTrack.total, override = true }
	notifyTrack()

	task.spawn(function()
		for _, part in parts do
			if overrideToken ~= token or type(part.id) ~= "string" or part.id == "" then
				break
			end
			local sound = Instance.new("Sound")
			sound.Name = "MusicOverride"
			sound.SoundId = part.id
			sound.Looped = part.loopFor ~= nil
			sound.Parent = SoundService
			local previous = overrideSound
			overrideSound = sound
			applyMusicVolume()
			sound.TimePosition = part.startAt or 0
			sound:Play()
			if musicPaused then
				sound:Pause()
			end
			if previous then
				previous:Destroy() -- anında geçiş (sönme yok)
			end
			-- Bölümün bitmesini bekle. Bekleme sınırı sadece ÇALAN süreyi sayar (teyp duraklatılınca durur): parça yüklenemezse sonsuza kadar takılmasın.
			local played = 0
			local last = os.clock()
			local function tick()
				task.wait()
				local now = os.clock()
				if not musicPaused then
					played += now - last
				end
				last = now
			end
			if part.loopFor then
				local loops = 0
				local done = false
				local connection = sound.DidLoop:Connect(function()
					loops += 1
					if loops * (sound.TimeLength or 0) >= part.loopFor then
						done = true -- süre doldu ve tur TAM bitti: sıradaki bölüm (bitiş) tam bu anda başlar
					end
				end)
				while not done and overrideToken == token and played < part.loopFor + 120 do
					tick()
				end
				connection:Disconnect()
			elseif part.stopAt then
				while overrideToken == token and (sound.TimePosition or 0) < part.stopAt and played < part.stopAt - (part.startAt or 0) + 20 do
					tick()
				end
			else
				while overrideToken == token and (sound.IsPlaying or sound.IsPaused or played < 3) and played < 600 do
					tick()
				end
			end
		end
		if overrideToken == token then
			Sfx.stopMusicOverride()
		end
	end)
	return true
end

function Sfx.isOverrideActive()
	return overrideActive
end

local function setTrack(name, index, total)
	if overrideActive then
		playlistTrack = { name = name, index = index, total = total } -- özel müzik çalarken teyp onun adını gösterir; liste parçası sonra geri gelir
		return
	end
	currentTrack = { name = name, index = index, total = total }
	notifyTrack()
end

function Sfx.getMusicLevel()
	return musicLevel
end

function Sfx.getMusicMaxLevel()
	return musicMaxLevel()
end

-- Ses kademesini ayarlar. silent = true ise sunucuya kaydedilmez (kayıttan okunan değer için).
-- Kullanıcı değişikliği 2 sn sessiz kalınca sunucuya yollanır (art arda tıklamalar tek istek olur).
local saveToken = 0
local function scheduleSave()
	saveToken += 1
	local token = saveToken
	task.delay(2, function()
		local shop = ReplicatedStorage:FindFirstChild("Shop")
		if token == saveToken and shop then
			pcall(shop.InvokeServer, shop, "SetMusicLevel", musicLevel)
		end
	end)
end

function Sfx.setMusicLevel(level, silent)
	level = math.clamp(math.floor(level + 0.5), 0, musicMaxLevel())
	if level == musicLevel then
		return
	end
	musicLevel = level
	applyMusicVolume()
	if not silent then
		scheduleSave()
	end
	for _, listener in levelListeners do
		task.spawn(listener, level)
	end
end

-- Şu an çalan parça: { name, index, total } (yüklenirken name = "Loading...")
function Sfx.getTrack()
	return currentTrack
end

-- Duraklatma durumunu değiştirir (müzik çalar dinleyicilerine haber verir)
local function setPaused(paused)
	if musicPaused == paused then
		return
	end
	musicPaused = paused
	if musicSound and not overrideActive then
		if paused then
			musicSound:Pause()
		elseif musicSound.IsPaused then
			musicSound:Resume()
		end
	end
	-- Özel müzik (Power Hour) de teypin duraklat düğmesine uyar
	if overrideSound then
		if paused then
			overrideSound:Pause()
		elseif overrideSound.IsPaused then
			overrideSound:Resume()
		else
			overrideSound:Play()
		end
	end
	for _, listener in pauseListeners do
		task.spawn(listener, paused)
	end
end

function Sfx.isPaused()
	return musicPaused
end

function Sfx.togglePause()
	setPaused(not musicPaused)
end

-- Sonraki / önceki parçaya geç. Duraklatılmışsa yeni parça çalmaya başlar.
local function skipTrack(step)
	if overrideActive then
		-- Power Hour müziği çalarken ileri/geri: özel müzik biter, normal parça kaldığı yerden devam eder
		Sfx.stopMusicOverride()
		setPaused(false)
		return
	end
	pendingStep = step
	skipRequested = true
	setPaused(false)
	if musicSound then
		musicSound:Stop()
	end
end

function Sfx.nextTrack()
	skipTrack(1)
end

function Sfx.previousTrack()
	skipTrack(-1)
end

function Sfx.onPausedChanged(listener)
	table.insert(pauseListeners, listener)
end

function Sfx.onTrackChanged(listener)
	table.insert(trackListeners, listener)
end

function Sfx.onMusicLevelChanged(listener)
	table.insert(levelListeners, listener)
end

-- Sunucudaki kayıtlı ses kademesini uygular (oyuncu verisi yüklenince MusicLevel özniteliği gelir)
local function syncSavedLevel()
	local saved = player:GetAttribute("MusicLevel")
	if type(saved) == "number" then
		Sfx.setMusicLevel(saved, true)
	end
end

local function waitForData(timeout)
	local waited = 0
	while player:GetAttribute("DataLoaded") ~= true and waited < timeout do
		task.wait(0.2)
		waited += 0.2
	end
end

local function playlist(music)
	local tracks = music.tracks
	local sound = Instance.new("Sound")
	sound.Name = "Music"
	sound.Looped = false
	sound.Parent = SoundService
	musicSound = sound
	applyMusicVolume()
	player:GetAttributeChangedSignal("MusicOn"):Connect(applyMusicVolume)

	-- İlk parça, kayıtlı ses kademesiyle başlasın (veri yüklenmezse en fazla 10 sn beklenir)
	waitForData(10)
	syncSavedLevel()

	local index = 1
	local skipped = 0 -- üst üste çalınamayan parça sayısı
	while skipped < #tracks do
		local track = tracks[index]
		setTrack("Loading...", index, #tracks)
		sound.SoundId = track.id
		local started = os.clock()
		while not sound.IsLoaded and not skipRequested and os.clock() - started < 15 do
			task.wait(0.1)
		end
		if skipRequested then
			skipRequested = false
		elseif sound.IsLoaded and sound.TimeLength > 0 then
			skipped = 0
			-- Sıradaki parçayı çalarken önceden indir: geçişte boşluk kalmasın
			local nextId = tracks[index % #tracks + 1].id
			task.spawn(function()
				local probe = Instance.new("Sound")
				probe.SoundId = nextId
				pcall(ContentProvider.PreloadAsync, ContentProvider, { probe })
				probe:Destroy()
			end)
			setTrack(track.name, index, #tracks)
			-- Duraklatılmışken ya da özel müzik (Power Hour) çalarken parça başlamaz; sonra çalar
			while (musicPaused or overrideActive) and not skipRequested do
				task.wait(0.2)
			end
			if not skipRequested then
				if not sound.IsPlaying then
					sound:Play()
				end
				-- Parça bitene, duraklatılana ya da önceki/sonraki istenene kadar bekle (çalmaya başlaması için 3 sn tolerans)
				local began = os.clock()
				while not skipRequested and (sound.IsPlaying or musicPaused or overrideActive or os.clock() - began < 3) do
					task.wait(0.2)
				end
			end
			skipRequested = false
		else
			skipped += 1
			warn(`[Sfx] Müzik parçası yüklenemedi, atlanıyor: {track.id}`)
		end
		sound:Stop()
		index = (index - 1 + pendingStep) % #tracks + 1
		pendingStep = 1
	end
	warn("[Sfx] Hiçbir müzik parçası çalınamadı, müzik kapalı.")
	setTrack("No music", 0, 0)
	musicSound = nil
	sound:Destroy()
end

function Sfx.init()
	task.spawn(preload)

	-- Veri geç yüklenirse de kayıtlı kademe uygulansın
	task.spawn(function()
		waitForData(60)
		syncSavedLevel()
	end)

	local music = Config.Music
	if music and music.tracks and #music.tracks > 0 then
		task.spawn(playlist, music)
	end
end

return Sfx
