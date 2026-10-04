-- Ses efektleri: Config.Sounds'taki olay adlarını çalar. Sol menüdeki "Sounds" anahtarı kapalıysa (SoundsOn = false) hiçbir şey çalmaz.
-- Ses dosyası yüklenemezse oyun etkilenmez (sadece o ses çalmaz).
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Sfx = {}

local player = Players.LocalPlayer
local rng = Random.new()
local lastPlayed = {} -- [olay] = zaman: aynı ses saniyede çok sık çalıp kulağı yormasın
local MIN_GAP = 0.06

function Sfx.play(name)
	local def = Config.Sounds and Config.Sounds[name]
	if not def or def.id == nil or def.id == "" then
		return
	end
	if player:GetAttribute("SoundsOn") == false then
		return
	end
	local now = os.clock()
	if now - (lastPlayed[name] or 0) < MIN_GAP then
		return
	end
	lastPlayed[name] = now

	local sound = Instance.new("Sound")
	sound.SoundId = def.id
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

-- Arka plan müziğini başlatır (Config.Music.id doluysa). "Sounds" anahtarı kapanınca sesi 0 olur.
function Sfx.init()
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
