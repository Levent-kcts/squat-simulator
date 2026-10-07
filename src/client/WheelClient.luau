-- Günlük çark istemcisi: lobideki çarkın (server/WheelService) hareketi ve kullanımı. SADECE görsel/etkileşimdir; çevirme hakkını ve ödülü SUNUCU verir (PlayerStats.spinWheel).
--  * Çark beklerken yavaşça döner, kenar lambaları koşuşur (herkesin ekranında kendi kopyası döner).
--  * E ile (ProximityPrompt 'Panel' = 'Wheel') karartılmış arka planlı çark arayüzü açılır (client/WheelPanel); 'Spin!' düğmesi sunucudan 'SpinWheel' ister.
--  * Sunucu dilimi seçip ödülü verir; istemci hem arayüzdeki hem lobideki çarkı o dilim İBRENİN altında duracak şekilde döndürür, sonra sonucu gösterir.
--  * Tabeladaki yazı her oyuncuya kendi durumunu söyler: 'FREE SPIN READY!' ya da kalan süre.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
-- Arayüz, kutlama efekti ve ses (isteğe bağlı): yüklenemezse lobideki çark yine çalışır
local okPanel, WheelPanel = pcall(require, script.Parent.WheelPanel)
local okJuice, Juice = pcall(require, script.Parent.Juice)
local okSfx, Sfx = pcall(require, script.Parent.Sfx)

local WheelClient = {}

local READY_COLOR = Color3.fromRGB(255, 235, 110)
local WAIT_COLOR = Color3.fromRGB(190, 200, 225)
local LAMP_ON = Color3.fromRGB(255, 250, 225)
local LAMP_OFF = Color3.fromRGB(255, 170, 60)

-- showToast(ok, mesaj): kısa bildirim. Dönüş: çarkı çevirmeyi deneyen fonksiyon (arayüzdeki Spin düğmesiyle aynı)
function WheelClient.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local wheel = Config.Wheel
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local sliceDegrees = 360 / #wheel.Prizes

	local model, basePivot, statusLabel, prompt
	local lamps = {}
	local worldAngle = 0 -- lobideki çarkın açısı (derece, saat yönü); beklerken yavaş döner
	local uiAngle = 0 -- arayüzdeki çarkın açısı; beklerken durur, sadece çevirirken döner
	local spin = nil -- { worldStart, worldDelta, uiStart, uiDelta, elapsed, index, message }
	local busy = false -- sunucudan yanıt bekleniyor ya da çark dönüyor
	local panel = nil
	local showingResult = false -- arayüzde sonuç yazısı duruyor: kapanıp yeniden açılana kadar durum yazısı üzerine yazılmaz

	-- Çark dünyaya sunucudan gelir: gelince parçalarını bul
	task.spawn(function()
		model = Workspace:WaitForChild("DailyWheel", 60)
		local stand = Workspace:WaitForChild("DailyWheelStand", 60)
		if not model or not stand then
			return
		end
		basePivot = model:GetPivot()
		for _, part in model:GetChildren() do
			if part.Name == "WheelLamp" then
				table.insert(lamps, part)
			end
		end
		statusLabel = stand:FindFirstChild("SpinLabel", true)
		prompt = stand:FindFirstChildWhichIsA("ProximityPrompt", true)
	end)

	-- Hak durumu: sunucunun yayınladığı 'WheelReady' ya da gece yarısı (UTC) geçtiyse hazır
	local function secondsLeft()
		local nextTime = player:GetAttribute("WheelNext")
		if type(nextTime) ~= "number" then
			return nil
		end
		return nextTime - Workspace:GetServerTimeNow()
	end
	local function isReady()
		if player:GetAttribute("WheelReady") == true then
			return true
		end
		local left = secondsLeft()
		return left ~= nil and left <= 0
	end
	local function waitText()
		local left = math.max(0, math.floor(secondsLeft() or 0))
		return `Next free spin in {left // 3600}h {(left % 3600) // 60}m`
	end

	local function refreshStatus()
		local ready = isReady()
		if statusLabel then
			if player:GetAttribute("DataLoaded") ~= true then
				statusLabel.Text = ""
			elseif ready then
				statusLabel.Text = "FREE SPIN READY!"
			else
				statusLabel.Text = waitText()
				statusLabel.TextColor3 = WAIT_COLOR
			end
		end
		if prompt then
			prompt.ActionText = if ready then "Spin (FREE)" else "Spin (used today)"
		end
		-- Arayüz açıkken düğme ve durum yazısı (dönüş sırasında sonuç yazısı korunur)
		if panel and panel.isOpen() then
			panel.setStatus(ready, if busy or showingResult then nil elseif ready then "Your free daily spin is ready!" else waitText(), busy)
		end
	end

	-- Dönüş bitti: sonucu göster
	local function finishSpin()
		local result = spin
		spin = nil
		busy = false
		worldAngle = worldAngle % 360
		uiAngle = uiAngle % 360
		local prize = wheel.Prizes[result.index]
		showToast(true, result.message)
		showingResult = true
		if panel then
			panel.setStatus(false, nil, false)
			panel.showResult(result.message, prize.color)
		end
		if okJuice then
			pcall(Juice.banner, "DAILY WHEEL", prize.color, result.message)
			pcall(Juice.celebrate, prize.color, if prize.kind == "jackpot" then 160 else 70)
		end
		if okSfx then
			pcall(Sfx.play, "Rare")
		end
	end

	-- Çarkı çevir: sunucudan hak ve sonuç iste, hak varsa dilimin ibrenin (yukarı) altında duracağı şekilde döndür
	local function trigger()
		if busy then
			return
		end
		busy = true
		if panel then
			panel.setStatus(true, "", true)
		end
		task.spawn(function()
			local ok, message, index = shopFunction:InvokeServer("SpinWheel", "")
			if not ok or type(index) ~= "number" or not wheel.Prizes[index] then
				busy = false
				showToast(false, message or "The wheel is not available right now.")
				if panel then
					panel.setStatus(isReady(), message, false)
				end
				return
			end
			-- Dilim i, [(i-1), i] x dilim açısı aralığındadır (ortası (i - 0.5) x dilim açısı); çark -o kadar dönerse dilim ibrenin altına gelir, biraz sapma ekle
			local target = -(index - 0.5) * sliceDegrees + (math.random() - 0.5) * sliceDegrees * 0.6
			spin = {
				worldStart = worldAngle,
				worldDelta = ((target - worldAngle) % 360) + 360 * 5,
				uiStart = uiAngle,
				uiDelta = ((target - uiAngle) % 360) + 360 * 5,
				elapsed = 0,
				index = index,
				message = message,
			}
			if panel then
				panel.showResult("", nil)
			end
		end)
	end

	if okPanel then
		local okInit, result = pcall(WheelPanel.init, screenGui, trigger)
		if okInit then
			panel = result
		else
			warn(`[WheelClient] Çark arayüzü kurulamadı: {result}`)
		end
	end

	ProximityPromptService.PromptTriggered:Connect(function(triggered, who)
		if who ~= player or triggered:GetAttribute("Panel") ~= "Wheel" then
			return
		end
		if panel then
			showingResult = false
			panel.open()
			panel.place(uiAngle)
			refreshStatus()
		else
			trigger()
		end
	end)

	-- Hareket: dönüş sırasında yavaşlayarak durur; bekleyince lobideki çark yavaş döner, lambalar koşuşur
	local lampClock, lampStep, statusClock = 0, 0, 0
	RunService.Heartbeat:Connect(function(dt)
		if spin then
			spin.elapsed += dt
			local progress = math.min(spin.elapsed / wheel.SpinSeconds, 1)
			local eased = 1 - (1 - progress) ^ 3.2
			worldAngle = spin.worldStart + spin.worldDelta * eased
			uiAngle = spin.uiStart + spin.uiDelta * eased
			if progress >= 1 then
				finishSpin()
			end
		else
			worldAngle = (worldAngle + wheel.IdleSpeed * dt) % 360
		end
		if panel and panel.isOpen() then
			panel.place(uiAngle)
		end

		if model and basePivot then
			model:PivotTo(basePivot * CFrame.Angles(0, 0, math.rad(worldAngle)))

			lampClock += dt
			if lampClock >= (if spin then 0.07 else 0.18) then
				lampClock = 0
				lampStep += 1
				for index, lamp in lamps do
					lamp.Color = if (index + lampStep) % 3 == 0 then LAMP_ON else LAMP_OFF
				end
			end
		end

		statusClock += dt
		if statusClock >= 0.5 then
			statusClock = 0
			refreshStatus()
		end
		if statusLabel and isReady() and player:GetAttribute("DataLoaded") == true then
			statusLabel.TextColor3 = READY_COLOR:Lerp(Color3.new(1, 1, 1), (math.sin(os.clock() * 5) + 1) / 2)
		end
	end)

	-- Hatırlatma: eğitimi bitirmiş oyuncu girince hak hazırsa bir kez haber ver (yeni oyuncuya yönerge karışmasın)
	local reminded = false
	local function remind()
		if reminded or player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("TutorialDone") ~= true then
			return
		end
		if player:GetAttribute("WheelReady") == true then
			reminded = true
			task.delay(8, function()
				showToast(true, "🎡 Your free daily spin is ready! Find the wheel in the back-right corner of the lobby.")
			end)
		end
	end
	for _, name in { "DataLoaded", "TutorialDone", "WheelReady" } do
		player:GetAttributeChangedSignal(name):Connect(remind)
	end
	remind()

	return trigger
end

return WheelClient
