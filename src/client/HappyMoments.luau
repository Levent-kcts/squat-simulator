-- MUTLU ANLAR (2026-10-20, pazarlama planı Faz B; research/07_PAZARLAMA_PLANI.md): oyuncunun en sevindiği anlarda iki küçük, ödülsüz istem:
--  1) KLİP: an olduğu gibi ekran görüntüsü olarak yakalanır (CaptureService:TakeScreenshotCaptureAsync, arayüz dahil), sağda küçük
--     '📸 Save this moment' kartı çıkar; SAVE = Roblox'un kendi 'galeriye kaydet' penceresi (oradan Moments'ta paylaşılabilir: 16+ akışı,
--     her klipte Join düğmesi). Kart 9 sn sonra kendiliğinden gider. Oturumda en çok MAX_CLIPS kez, her tür bir kez; eğitim bitmeden yok;
--     PolicyService 'IsContentSharingAllowed' false olan hesapta hiç yok.
--  2) FAVORİ: oturumda en az FAV_AFTER sn oynamış oyuncuya, bir evrim ya da Epic+ pet anında Roblox'un favori penceresi
--     (AvatarEditorService:PromptSetFavorite) oturumda BİR KEZ; ödül YOK (ödül karşılığı favori Roblox kuralına takılabilir).
--     Favorilerse sunucu 'FavDone' kaydeder, bir daha sorulmaz (Shop 'FavoritePrompt').
-- Tetikleyiciler: Juice (evrim anı), Reveal (Epic/Legendary/Mythic), rebirth sayacı (ilk rebirth'te klip; favori değil: NotifOptIn o anda).
-- Ekran sade kuralı: kart küçük, ortada değil; hata verirse sessizce atlanır (init.client safeInit).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIStyle = require(script.Parent.UIStyle)

local HappyMoments = {}

local MAX_CLIPS = 2 -- oturumda en çok klip önerisi
local CARD_SECONDS = 9
local FAV_AFTER = 240 -- sn: oturumun ilk 4 dakikasında favori sorulmaz
local DELAY = { evolve = 2.2, rebirth = 5, epic = 3.2, legendary = 3.2, mythic = 3.2 } -- kutlama görüntüsü otursun diye yakalama gecikmesi
local FAV_KINDS = { evolve = true, epic = true, legendary = true, mythic = true }
local FONT = Enum.Font.FredokaOne

local state = {
	ready = false,
	screenGui = nil,
	showToast = nil,
	started = os.clock(),
	clips = 0,
	clipKinds = {},
	favAsked = false,
	sharingAllowed = nil, -- nil = henüz bilinmiyor
	card = nil,
	busy = false,
}
HappyMoments._state = state -- testler için

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function player()
	return Players.LocalPlayer
end

local function sharingAllowed()
	if state.sharingAllowed ~= nil then
		return state.sharingAllowed
	end
	local ok, info = pcall(function()
		return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(player())
	end)
	-- Sorgu başarısızsa güvenli taraf: paylaşma önerme
	state.sharingAllowed = ok and type(info) == "table" and info.IsContentSharingAllowed == true
	return state.sharingAllowed
end

local function hideCard()
	local card = state.card
	state.card = nil
	if card then
		pcall(function()
			card:Destroy()
		end)
	end
end

local function saveCapture(capture)
	hideCard()
	pcall(function()
		game:GetService("CaptureService"):PromptSaveCapturesToGallery({ capture }, function(results)
			local saved = false
			if type(results) == "table" then
				for _, accepted in results do
					if accepted then
						saved = true
					end
				end
			end
			if saved and state.showToast then
				state.showToast(true, "Saved! Share it from your Roblox Captures to Moments.")
			end
		end)
	end)
end

local function showCard(capture)
	hideCard()
	local root = state.screenGui
	if not root then
		return
	end
	local card = create("Frame", {
		Name = "MomentCard",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.78, 0), -- FREE REWARD kutusunun altında, teybin üstünde
		Size = UDim2.fromOffset(250, 64),
		BackgroundColor3 = Color3.fromRGB(34, 38, 60),
		Active = true, -- karta tıklamak squat sayılmasın
		ZIndex = 40,
	}, root)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, card)
	pcall(UIStyle.soften, card, { radius = 14, strength = 0.2, shine = false })
	local text = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -118, 1, -12),
		Font = FONT,
		Text = "📸 Save this moment!",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 41,
	}, card)
	create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, text)
	local save = create("TextButton", {
		Name = "SaveMoment",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -40, 0.5, 0),
		Size = UDim2.fromOffset(64, 38),
		BackgroundColor3 = Color3.fromRGB(70, 200, 100),
		Text = "",
		ZIndex = 41,
	}, card)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, save)
	pcall(UIStyle.soften, save, { radius = 12, strength = 0.28 })
	local saveText = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.1, 0.15),
		Size = UDim2.fromScale(0.8, 0.7),
		Font = FONT,
		Text = "SAVE",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		ZIndex = 42,
	}, save)
	create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, saveText)
	local close = create("TextButton", {
		Name = "CloseMoment",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Color3.fromRGB(235, 40, 70),
		Font = FONT,
		Text = "X",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		ZIndex = 41,
	}, card)
	create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, close)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, close)
	save.MouseButton1Click:Connect(function()
		saveCapture(capture)
	end)
	close.MouseButton1Click:Connect(hideCard)
	state.card = card
	-- Küçük giriş: sağdan kayarak (Calm UI'da anında)
	if not UIStyle.calm() then
		local home = card.Position
		card.Position = home + UDim2.fromOffset(280, 0)
		pcall(function()
			TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = home }):Play()
		end)
	end
	task.delay(CARD_SECONDS, function()
		if state.card == card then
			hideCard()
		end
	end)
end

-- Bir pencere açıkken (sol menü/Quests vb. ya da çevrimdışı kazanç penceresi) an yakalanmaz: görüntüye pencere girer, kart da üstüne biner
local function windowOpen()
	local ok, open = pcall(function()
		return require(script.Parent.PanelManager).anyOpen()
	end)
	if ok and open then
		return true
	end
	local playerGui = player():FindFirstChildOfClass("PlayerGui")
	local offline = playerGui and playerGui:FindFirstChild("OfflineEarnings", true)
	return offline ~= nil and offline:IsA("GuiObject") and offline.Visible
end

local function offerClip(kind)
	if state.clips >= MAX_CLIPS or state.clipKinds[kind] or state.card or windowOpen() or not sharingAllowed() then
		return false
	end
	state.clips += 1
	state.clipKinds[kind] = true
	local ok = pcall(function()
		game:GetService("CaptureService"):TakeScreenshotCaptureAsync(function(result, capture)
			if result == Enum.ScreenshotCaptureResult.Success and capture then
				showCard(capture)
			end
		end, { UICaptureMode = Enum.UICaptureMode.All })
	end)
	return ok
end

local function askFavorite()
	state.favAsked = true
	local ok, service = pcall(function()
		return game:GetService("AvatarEditorService")
	end)
	if not ok or not service then
		return false
	end
	local connection
	connection = service.PromptSetFavoriteCompleted:Connect(function(result)
		connection:Disconnect()
		local done = result == Enum.AvatarPromptResult.Success
		pcall(function()
			ReplicatedStorage:WaitForChild("Shop"):InvokeServer("FavoritePrompt", done)
		end)
	end)
	local prompted = pcall(function()
		service:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
	if not prompted then
		connection:Disconnect()
	end
	return prompted
end

-- Ortak giriş noktası (Juice, Reveal, rebirth sayacı çağırır). kind: evolve | rebirth | epic | legendary | mythic
function HappyMoments.trigger(kind)
	if not state.ready or state.busy then
		return
	end
	local p = player()
	if not p or p:GetAttribute("DataLoaded") ~= true or p:GetAttribute("TutorialDone") ~= true then
		return -- eğitim sırasında rehber kartlarıyla çakışmasın
	end
	state.busy = true
	task.delay(DELAY[kind] or 3, function()
		state.busy = false
		local wantFav = FAV_KINDS[kind] and not state.favAsked and p:GetAttribute("FavDone") ~= true and os.clock() - state.started >= FAV_AFTER
		if wantFav then
			askFavorite()
			return -- aynı anda iki istem olmasın: klip bir sonraki ana kalır
		end
		offerClip(kind)
	end)
end

function HappyMoments.init(screenGui, showToast)
	state.screenGui = screenGui
	state.showToast = showToast
	state.started = os.clock()
	state.ready = true
	-- Rebirth sayacı: rebirth anı (ilk rebirth dahil) klip önerir
	local p = player()
	task.spawn(function()
		local leaderstats = p:WaitForChild("leaderstats", 30)
		local rebirths = leaderstats and leaderstats:WaitForChild("Rebirths", 30)
		if not rebirths then
			return
		end
		local last = rebirths.Value
		rebirths:GetPropertyChangedSignal("Value"):Connect(function()
			local gained = rebirths.Value > last
			last = rebirths.Value
			if gained then
				HappyMoments.trigger("rebirth")
			end
		end)
	end)
	return HappyMoments
end

return HappyMoments
