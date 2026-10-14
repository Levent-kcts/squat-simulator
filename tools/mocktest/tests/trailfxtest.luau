-- OYUNA UYGUN İZLER (tester E4: 'Backpack trail'leri oyunla alakasız görünüyor'; sahibi 2026-10-14 'önce E4 ve E3'ü yap' dedi): her iz oyunla ilgili bir temadır (tuğla tozu, ter damlası, pati, kupa, bacak kası...),
-- düz renkli şerit değil, karakterin arkasından akan parçacık efektidir; parçacıklar sadece koşarken açılır; Rainbow Legend ince şerit de ekler.
local S = require("./stubs")
local Config = require("./Config")
local TrailService = require("./TrailService")

-- Yapılandırma: 9 iz, benzersiz oyun temalı isim ('Red Trail' gibi düz renk adı YOK), bilinen bir efekt, simge/emoji
local seenNames = {}
local seenFx = {}
assert(#Config.Trails == 9, "9 iz olmalı: " .. #Config.Trails)
for _, trail in Config.Trails do
	assert(type(trail.name) == "string" and not string.find(trail.name, "^%a+ Trail$"), `{trail.id}: ad oyuna uygun olmalı, düz renk adı değil: {trail.name}`)
	assert(not seenNames[trail.name], "iz adları benzersiz olmalı: " .. trail.name)
	seenNames[trail.name] = true
	assert(TrailService.FX[trail.fx], `{trail.id}: bilinmeyen efekt '{tostring(trail.fx)}'`)
	assert(not seenFx[trail.fx], `iz efektleri benzersiz olmalı: {trail.fx}`)
	seenFx[trail.fx] = true
	local iconId = trail.icon and Config.Icons[trail.icon]
	assert((type(iconId) == "string" and iconId ~= "") or type(trail.emoji) == "string", `{trail.id}: panelde simge ya da yedek emoji olmalı`)
	if trail.icon then
		assert(Config.Icons[trail.icon] ~= nil, `{trail.id}: icon anahtarı Config.Icons'ta yok: {trail.icon}`)
	end
end

-- Kurulum: sahte karakter (gövde + insan)
local torso = S.newInstance("Part")
torso.Name = "UpperTorso"
rawset(torso, "Size", { X = 2, Y = 1.6, Z = 1 })
local runningHandler, disconnected = nil, 0
local humanoid = S.newInstance("Humanoid")
rawset(humanoid, "MoveDirection", { Magnitude = 0 })
rawset(humanoid, "Running", {
	Connect = function(_, handler)
		runningHandler = handler
		return {
			Disconnect = function()
				disconnected += 1
			end,
		}
	end,
})
local character = S.newInstance("Model")
rawset(character, "FindFirstChild", function(_, name)
	if name == "UpperTorso" then
		return torso
	end
	return nil
end)
rawset(character, "FindFirstChildOfClass", function()
	return humanoid
end)

for _, trail in Config.Trails do
	runningHandler = nil
	local emitters = TrailService.build(character, trail)
	assert(#emitters >= 1, `{trail.id} ({trail.fx}): en az bir parçacık yayıcı kurmalı`)
	local anchor = rawget(torso, "_children").TrailBack
	assert(anchor, `{trail.id}: parçacıklar sırtın arkasındaki 'TrailBack' noktasından çıkmalı`)
	for _, emitter in emitters do
		local texture = rawget(emitter, "Texture")
		assert(type(texture) == "string" and texture ~= "", `{trail.id}: parçacığın dokusu olmalı`)
		assert(rawget(emitter, "Rate") > 0, `{trail.id}: yayıcı hızı > 0`)
		assert(rawget(emitter, "Enabled") == false, `{trail.id}: duruyorken parçacık çıkmamalı`)
	end
	assert(runningHandler, `{trail.id}: koşu olayına bağlanmalı`)
	runningHandler(16)
	for _, emitter in emitters do
		assert(rawget(emitter, "Enabled") == true, `{trail.id}: koşarken parçacık çıkmalı`)
	end
	runningHandler(0)
	for _, emitter in emitters do
		assert(rawget(emitter, "Enabled") == false, `{trail.id}: durunca parçacık kesilmeli`)
	end
	-- sadece Rainbow Legend ince şerit ekler (diğerleri düz şeritsiz)
	local hasRibbon = rawget(torso, "_children").TrailEffect ~= nil
	assert(hasRibbon == (trail.fx == "legend"), `{trail.id}: ince şerit sadece Rainbow Legend'de olmalı (şerit: {tostring(hasRibbon)})`)
	rawget(torso, "_children").TrailEffect = nil
	rawget(torso, "_children").TrailBack = nil
end

-- Tuğla konfetisi dört renk (her renk ayrı yayıcı), Rainbow Legend'de de konfeti + pırıltı var
local bricks = TrailService.build(character, Config.Trails[4])
assert(#bricks == 4, "Brick Confetti dört renkli olmalı (4 yayıcı): " .. #bricks)
local legend = TrailService.build(character, Config.Trails[9])
assert(#legend == 5, "Rainbow Legend: 4 renkli tuğla + 1 gökkuşağı pırıltısı: " .. #legend)
print("trail themes ok")
