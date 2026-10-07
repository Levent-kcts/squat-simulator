-- Günlük çark istemcisi: lobideki çarkın (server/WheelService) hareketi ve kullanımı. SADECE görsel/etkileşimdir; çevirme hakkını ve ödülü SUNUCU verir (PlayerStats.spinWheel).
--  * Çark beklerken yavaşça döner, kenar lambaları koşuşur (herkesin ekranında kendi kopyası döner).
--  * E ile (ProximityPrompt 'Panel' = 'Wheel') sunucuya 'SpinWheel' istenir; sunucu dilimi seçip ödülü verir, istemci çarkı o dilimde (ibrenin altında) duracak şekilde döndürür, sonra sonucu gösterir.
--  * Tabeladaki yazı her oyuncuya kendi durumunu söyler: 'FREE SPIN READY!' ya da kalan süre.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
-- Kutlama efekti ve ses (isteğe bağlı): yüklenemezse çark yine çalışır
local okJuice, Juice = pcall(require, script.Parent.Juice)
local okSfx, Sfx = pcall(require, script.Parent.Sfx)

local WheelClient = {}

local READY_COLOR = Color3.fromRGB(255, 235, 110)
local WAIT_COLOR = Color3.fromRGB(190, 200, 225)
local LAMP_ON = Color3.fromRGB(255, 250, 225)
local LAMP_OFF = Color3.fromRGB(255, 170, 60)

-- showToast(ok, mesaj): kısa bildirim. Dönüş: çarkı çevirmeyi deneyen fonksiyon (E ile aynı)
function WheelClient.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local wheel = Config.Wheel
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local sliceDegrees = 360 / #wheel.Prizes

	local model, basePivot, statusLabel, prompt
	local lamps = {}
	local angle = 0 -- derece, saat yönünde
	local spin = nil -- { start, delta, elapsed, index, message }
	local busy = false -- sunucudan yanıt bekleniyor ya da çark dönüyor

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

	local function refreshStatus()
		local ready = isReady()
		if statusLabel then
			if player:GetAttribute("DataLoaded") ~= true then
				statusLabel.Text = ""
			elseif ready then
				statusLabel.Text = "FREE SPIN READY!"
			else
				local left = math.max(0, math.floor(secondsLeft() or 0))
				statusLabel.Text = `Next free spin in {left // 3600}h {(left % 3600) // 60}m`
				statusLabel.TextColor3 = WAIT_COLOR
			end
		end
		if prompt then
			prompt.ActionText = if ready then "Spin (FREE)" else "Spin (used today)"
		end
	end

	-- Dönüş bitti: sonucu göster
	local function finishSpin()
		local result = spin
		spin = nil
		busy = false
		angle = angle % 360
		local prize = wheel.Prizes[result.index]
		showToast(true, result.message)
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
		task.spawn(function()
			local ok, message, index = shopFunction:InvokeServer("SpinWheel", "")
			if not ok or type(index) ~= "number" or not wheel.Prizes[index] then
				busy = false
				showToast(false, message or "The wheel is not available right now.")
				return
			end
			-- İndeks dilimi saat yönünde (index - 1) * dilim açısı kadar uzaktadır; çark -o kadar dönerse ibrenin altına gelir
			local target = -(index - 1) * sliceDegrees + (math.random() - 0.5) * sliceDegrees * 0.5
			local delta = ((target - angle) % 360) + 360 * 5
			spin = { start = angle, delta = delta, elapsed = 0, index = index, message = message }
		end)
	end

	ProximityPromptService.PromptTriggered:Connect(function(triggered, who)
		if who == player and triggered:GetAttribute("Panel") == "Wheel" then
			trigger()
		end
	end)

	-- Hareket: dönüş sırasında yavaşlayarak durur; bekleyince yavaş döner, lambalar koşuşur
	local lampClock, lampStep, statusClock = 0, 0, 0
	RunService.Heartbeat:Connect(function(dt)
		if not model or not basePivot then
			return
		end
		if spin then
			spin.elapsed += dt
			local progress = math.min(spin.elapsed / wheel.SpinSeconds, 1)
			angle = spin.start + spin.delta * (1 - (1 - progress) ^ 3.2)
			if progress >= 1 then
				finishSpin()
			end
		else
			angle = (angle + wheel.IdleSpeed * dt) % 360
		end
		model:PivotTo(basePivot * CFrame.Angles(0, 0, math.rad(angle)))

		lampClock += dt
		if lampClock >= (if spin then 0.07 else 0.18) then
			lampClock = 0
			lampStep += 1
			for index, lamp in lamps do
				lamp.Color = if (index + lampStep) % 3 == 0 then LAMP_ON else LAMP_OFF
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
				showToast(true, "🎡 Your free daily spin is ready! Find the wheel on the left side of the lobby.")
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
