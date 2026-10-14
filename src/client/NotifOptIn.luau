-- BİLDİRİM İZNİ (büyüme planı 3.3): ilk rebirth'ten sonra oyuncuya Roblox'un kendi 'bildirim al' penceresi (ExperienceNotificationService:PromptOptIn) BİR KEZ sorulur;
-- böylece 'günlük çark hazır' gibi kişisel bildirimle geri çağırabiliriz. Sadece Roblox'un izin verdiği hesaplarda (CanPromptOptInAsync) ve oyuncu başına tek seferlik (kayıtlı 'notif' işareti, 'NotifAsked' özniteliği).
-- Ekran sade kalır: kendi arayüzümüz yok, Roblox'un penceresi çıkar. Hata verirse sessizce atlanır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotifOptIn = {}

local DELAY = 12 -- rebirth kutlaması bittikten sonra (sn)

function NotifOptIn.init(screenGui)
	local player = Players.LocalPlayer
	local started = false
	local function consider()
		if started or player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("NotifAsked") == true then
			return
		end
		local leaderstats = player:FindFirstChild("leaderstats")
		local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
		if not rebirths or rebirths.Value < 1 then
			return
		end
		started = true
		task.delay(DELAY, function()
			-- Welcome Back (çevrimdışı kazanç) ya da Neler Yeni kartı açıksa onlar kapanana kadar bekle (en çok 60 sn): iki pencere üst üste çıkmasın
			for _ = 1, 60 do
				local busy = false
				if screenGui then
					for _, name in { "OfflineEarnings", "WhatsNewCard" } do
						local frame = screenGui:FindFirstChild(name, true)
						if frame and frame.Visible then
							busy = true
						end
					end
				end
				if not busy then
					break
				end
				task.wait(1)
			end
			local ok, service = pcall(function()
				return game:GetService("ExperienceNotificationService")
			end)
			if ok and service then
				local canOk, can = pcall(function()
					return service:CanPromptOptInAsync()
				end)
				if canOk and can == true then
					pcall(function()
						service:PromptOptIn()
					end)
				end
			end
			-- Sorulmuş sayılır (izin verilmese de tekrar sorma)
			pcall(function()
				ReplicatedStorage:WaitForChild("Shop"):InvokeServer("NotifAsked")
			end)
		end)
	end
	player:GetAttributeChangedSignal("DataLoaded"):Connect(consider)
	player:GetAttributeChangedSignal("NotifAsked"):Connect(consider)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	if rebirths then
		rebirths:GetPropertyChangedSignal("Value"):Connect(consider)
	end
	consider()
end

return NotifOptIn
