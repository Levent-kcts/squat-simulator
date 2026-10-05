-- Lobideki FREE REWARD sandığının oyuncuya özel davranışı (sandığı sunucu kurar, server/RewardChest):
--  * Üstünde başlık ve geri sayım ("02:15") görünür; süresi dolan ödül varsa kapak AÇILIR, sandık parlar, kıvılcım saçar ve "READY!" yazar.
--  * Hazırken sandığa yaklaşınca (üstüne/yanına basınca) hazır olan tüm ödüller sırayla alınır (sunucu doğrular, PlayerStats.claimGift).
--  * Hazır değilken yaklaşınca kısa bir mesajla sıradaki ödüle kalan süre söylenir.
-- Kapak, ışık ve kıvılcım değişiklikleri sadece bu oyuncunun ekranındadır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GiftState = require(script.Parent.GiftState)

-- Efekt ve ses isteğe bağlıdır (yüklenemezse sandık yine çalışır)
local okJuice, Juice = pcall(require, script.Parent.Juice)
local okSfx, Sfx = pcall(require, script.Parent.Sfx)

local RewardChest = {}

local FONT = Enum.Font.FredokaOne
local OPEN_ANGLE = math.rad(108) -- kapağın açılma açısı
local TOUCH_RANGE = 6.5 -- sandığa bu kadar (yatay, stud) yaklaşınca ödül alınır
local GOLD = Color3.fromRGB(255, 215, 70)
local GREEN = Color3.fromRGB(110, 255, 140)

local function label(parent, props)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local text = Instance.new("TextLabel")
	for key, value in props do
		text[key] = value
	end
	text.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = text
	return text
end

function RewardChest.init(_screenGui, showToast)
	local player = Players.LocalPlayer
	local folder = Workspace:WaitForChild("RewardChest", 20)
	if not folder then
		return
	end
	local hinge = folder:WaitForChild("Hinge")
	local body = folder:WaitForChild("Body")
	local ring = folder:WaitForChild("Ring")
	local glow = folder:WaitForChild("Glow")
	local light = glow:FindFirstChildOfClass("PointLight")
	local sparkles = glow:FindFirstChildOfClass("ParticleEmitter")

	-- Kapakla birlikte dönen parçalar (menteşeye göre göreli konumlarıyla)
	local lidParts = {}
	for _, child in folder:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("LidPart") then
			table.insert(lidParts, { part = child, offset = hinge.CFrame:ToObjectSpace(child.CFrame) })
		end
	end

	-- Sandığın üstündeki başlık ve durum yazısı
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(9, 3.6)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 6.2, 0)
	gui.MaxDistance = 80
	gui.Adornee = body
	gui.Parent = body
	label(gui, { Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 0.46), Text = "FREE REWARD", TextColor3 = GOLD })
	local status = label(gui, { Position = UDim2.fromScale(0, 0.46), Size = UDim2.fromScale(1, 0.54), Text = "", TextColor3 = Color3.new(1, 1, 1) })

	local openness = 0 -- 0 kapalı, 1 açık (yumuşak geçiş)
	local target = 0
	local ready = false
	local claiming = false
	local lastAttempt = 0
	local lastHint = 0

	-- Kapak animasyonu
	RunService.RenderStepped:Connect(function(dt)
		if math.abs(target - openness) < 0.002 then
			return
		end
		openness += (target - openness) * math.min(1, dt * 7)
		local rotation = CFrame.Angles(OPEN_ANGLE * openness, 0, 0)
		for _, entry in lidParts do
			entry.part.CFrame = hinge.CFrame * rotation * entry.offset
		end
	end)

	local function setReady(value)
		ready = value
		target = if value then 1 else 0
		if light then
			light.Enabled = value
		end
		if sparkles then
			sparkles.Enabled = value
		end
		ring.Material = if value then Enum.Material.Neon else Enum.Material.SmoothPlastic
		ring.Color = if value then GREEN else GOLD
	end

	-- Hazır olan ödülleri sırayla alır (sunucu her birini doğrular)
	local function claimReady()
		claiming = true
		local gotAny = false
		for _, index in GiftState.ready() do
			local ok, message = GiftState.claim(index)
			showToast(ok, message)
			if ok then
				gotAny = true
			else
				-- Envanter dolu vb.: bir süre tekrar deneme
				lastAttempt = os.clock() + 6
				break
			end
		end
		if gotAny then
			if okJuice then
				pcall(Juice.burst, body.Position + Vector3.new(0, 3, 0), Vector3.new(5, 3, 4), GOLD, 70)
				pcall(Juice.celebrate, GOLD, 40)
			end
			if okSfx then
				pcall(Sfx.play, "Buy")
			end
		end
		claiming = false
	end

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0

		local readyList = GiftState.ready()
		local remaining = GiftState.nextRemaining()
		local isReady = #readyList > 0
		if isReady ~= ready then
			setReady(isReady)
		end
		if isReady then
			status.Text = if #readyList > 1 then `READY! x{#readyList}` else "READY!"
			status.TextColor3 = GREEN
		elseif remaining then
			status.Text = GiftState.formatTime(remaining)
			status.TextColor3 = Color3.new(1, 1, 1)
		else
			status.Text = "ALL CLAIMED"
			status.TextColor3 = Color3.fromRGB(190, 195, 215)
		end

		-- Yaklaşma: sandığın yatay uzaklığı
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local delta = root.Position - body.Position
		local near = Vector3.new(delta.X, 0, delta.Z).Magnitude <= TOUCH_RANGE and math.abs(delta.Y) <= 10
		if not near then
			return
		end
		if isReady and not claiming and os.clock() - lastAttempt > 1 then
			lastAttempt = os.clock()
			task.spawn(claimReady)
		elseif not isReady and remaining and os.clock() - lastHint > 8 then
			lastHint = os.clock()
			showToast(true, `Next free reward in {GiftState.formatTime(remaining)}`)
		end
	end)
end

return RewardChest
