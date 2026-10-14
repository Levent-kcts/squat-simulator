-- ÇAPRAZ SUNUCU DUYURU AKIŞI (2026-10-14 büyüme planı, sprint 1.1; araştırma: research/01, 04): nadir pet (Legendary/Mythic) ve rebirth eşikleri tüm sunuculara küçük bir duyuru olarak gider.
-- Neden: oyuncu sayısı azken (16 oyuncu) her sunucuda 1-2 kişi vardır; başka sunucudaki birinin Mythic açtığını görmek oyunu 'dolu' gösterir (sosyal kanıt) ve klip yemi olur.
-- Güvenlik: metin SADECE sunucu şablonlarından ve oyuncunun Roblox'un süzdüğü DisplayName'inden gelir (serbest oyuncu yazısı YOK); en çok 90 karakter; oyuncu başına 20 sn, sunucu başına dakikada 8 duyuru sınırı.
-- İstemci: client/FeedHud (sağda küçük, kısa süren şerit; Settings > Server feed ile kapatılır). Sadece görsel: oyun mantığını etkilemez, hata verirse duyuru atlanır.
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalFeed = {}

local TOPIC = "SquatFeed_v1"
local PER_PLAYER_GAP = 20 -- aynı oyuncudan duyuru arası en az saniye
local PER_MINUTE = 8 -- bir sunucunun dakikada yayabileceği duyuru (yerel + dış)
local MAX_LENGTH = 90
local KINDS = { pet = true, rebirth = true, stage = true } -- izin verilen duyuru türleri
local SERVER_ID = HttpService:GenerateGUID(false)

local remote = nil
local lastByPlayer = setmetatable({}, { __mode = "k" })
local stamps = {} -- son dakikadaki yayın zamanları (sunucu sınırı)

local function underLimit()
	local now = os.time()
	local kept = {}
	for _, stamp in stamps do
		if now - stamp < 60 then
			table.insert(kept, stamp)
		end
	end
	stamps = kept
	if #stamps >= PER_MINUTE then
		return false
	end
	table.insert(stamps, now)
	return true
end

-- Metni temizler (denetim karakterleri atılır, uzunluk sınırlanır)
local function clean(text)
	text = string.gsub(tostring(text), "[%c<>]", "")
	if #text > MAX_LENGTH then
		text = string.sub(text, 1, MAX_LENGTH)
	end
	return text
end

-- Bu sunucudaki bütün oyunculara gösterir. kind: pet/rebirth/stage, tier: nadirlik adı (Config.Rarities) ya da 'rebirth' (renk için)
local function deliver(kind, text, tier)
	if not remote or not KINDS[kind] or type(text) ~= "string" or text == "" then
		return
	end
	pcall(function()
		remote:FireAllClients(kind, clean(text), tostring(tier or ""))
	end)
end

-- Oyuncu bir şey başardı: 'hatched a LEGENDARY Dragon!' gibi şablon metni verilir, başına oyuncunun adı eklenir. Dönüş: yayınlandı mı
function GlobalFeed.announce(player, kind, text, tier)
	if not KINDS[kind] then
		return false
	end
	local now = os.clock()
	if now - (lastByPlayer[player] or -1e9) < PER_PLAYER_GAP or not underLimit() then
		return false
	end
	lastByPlayer[player] = now
	local full = clean(`{player.DisplayName or player.Name} {text}`)
	deliver(kind, full, tier)
	-- Diğer sunucular (Studio'da ya da yayınlanmamış oyunda hata verebilir: sessizce atlanır)
	task.spawn(function()
		pcall(MessagingService.PublishAsync, MessagingService, TOPIC, { s = SERVER_ID, k = kind, t = full, r = tostring(tier or "") })
	end)
	return true
end

-- Başka sunucudan gelen duyuru: aynı sunucudan gelen ya da biçimi bozuk olanlar atılır
function GlobalFeed.receive(message)
	local data = message and message.Data
	if type(data) ~= "table" or data.s == SERVER_ID or not KINDS[data.k] or type(data.t) ~= "string" or data.t == "" then
		return false
	end
	if not underLimit() then
		return false
	end
	deliver(data.k, data.t, data.r)
	return true
end

function GlobalFeed.init()
	remote = Instance.new("RemoteEvent")
	remote.Name = "Feed"
	remote.Parent = ReplicatedStorage
	GlobalFeed.remote = remote
	task.spawn(function()
		pcall(MessagingService.SubscribeAsync, MessagingService, TOPIC, GlobalFeed.receive)
	end)
end

GlobalFeed.SERVER_ID = SERVER_ID
GlobalFeed.TOPIC = TOPIC

return GlobalFeed
