-- Tıklama hareketleri: duvara yakınken tekme, uzakken squat.
-- Hazır animasyon dosyası (asset) gerekmesin diye eklemlerin (Motor6D) C0 değerleri kodla oynatılır.
-- Bu sadece görseldir: her istemci hareketi kendi ekranında oynatır (diğer oyuncularınki sunucudan haber gelince).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Moves = {}

-- Hareketler çalışmıyorsa true yap: Output penceresine ne olduğunu yazar
local DEBUG = false

-- Pozlar derece cinsindendir. Anahtar eksikse eklem dinlenme pozisyonunda kalır.
-- Bacak/kol için + = öne doğru, belden + = geriye yaslanma, - = öne eğilme. Drop = gövdenin çökme oranı (0-1).
local KICK_END = {
	RightHip = 95, RightKnee = 0, LeftHip = 8, LeftKnee = -12,
	Waist = 10, RightShoulder = -30, LeftShoulder = 40,
}
local SQUAT_DOWN = {
	RightHip = 85, LeftHip = 85, RightKnee = -95, LeftKnee = -95,
	Waist = -20, RightShoulder = 80, LeftShoulder = 80, Drop = 1,
}

local MOVES = {
	Kick = {
		duration = 0.4,
		keys = {
			{ t = 0, pose = {} },
			{ t = 0.10, pose = { RightHip = 30, RightKnee = -85, LeftHip = 8, LeftKnee = -12, Waist = 4, RightShoulder = -25, LeftShoulder = 35 } },
			{ t = 0.20, pose = KICK_END },
			{ t = 0.28, pose = KICK_END },
			{ t = 0.40, pose = {} },
		},
	},
	Squat = {
		duration = 0.5,
		keys = {
			{ t = 0, pose = {} },
			{ t = 0.18, pose = SQUAT_DOWN },
			{ t = 0.30, pose = SQUAT_DOWN },
			{ t = 0.50, pose = {} },
		},
	},
}

-- Süreleri Config.MoveDuration belirler (sunucu da aynı süreyi kullanır). Anahtar kare zamanları bu süreye göre ölçeklenir.
for name, move in MOVES do
	local last = move.keys[#move.keys].t
	local duration = Config.MoveDuration[name]
	for _, key in move.keys do
		key.t = key.t / last * duration
	end
	move.duration = duration
end

-- Eklem adları: R15 adı önce, R6 adı sonra denenir
local JOINTS = {
	Root = { "RootJoint" },
	Waist = { "Waist" },
	RightHip = { "RightHip", "Right Hip" },
	LeftHip = { "LeftHip", "Left Hip" },
	RightKnee = { "RightKnee" },
	LeftKnee = { "LeftKnee" },
	RightShoulder = { "RightShoulder", "Right Shoulder" },
	LeftShoulder = { "LeftShoulder", "Left Shoulder" },
}

local active = {} -- [character] = { move, start, rig }

-- Karakterin boyut ölçeği değişti mi anlamak için (seviye atlayınca karakter büyür, eklem konumları değişir)
local function scaleKey(humanoid)
	if not humanoid then
		return 0
	end
	local height = humanoid:FindFirstChild("BodyHeightScale")
	local width = humanoid:FindFirstChild("BodyWidthScale")
	return (height and height.Value or 1) * 1000 + (width and width.Value or 1)
end

-- Eklem bilgileri her harekette yeniden okunur (karakter boyutu değişmiş olabilir, eski değerler geçersiz kalır)
local function getRig(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rig = {
		scaleKey = scaleKey(humanoid),
		joints = {},
		drop = 0.3,
		humanoid = humanoid,
		hip = humanoid and humanoid.HipHeight or 0,
		isLocal = character == Players.LocalPlayer.Character,
	}
	for key, names in JOINTS do
		for _, name in names do
			local joint = character:FindFirstChild(name, true)
			-- Yeni avatarlar AnimationConstraint, eski avatarlar Motor6D kullanır; ikisinde de C0 vardır
			if joint and joint:IsA("Motor6D") then
				rig.joints[key] = { motor = joint, c0 = joint.C0 }
				break
			elseif joint and joint:IsA("AnimationConstraint") and joint.Attachment0 then
				-- AnimationConstraint.C0 salt okunurdur; asıl değer Attachment0.CFrame'dedir
				rig.joints[key] = { attachment = joint.Attachment0, c0 = joint.Attachment0.CFrame }
				break
			end
		end
	end

	-- R15'te dizler bükülür, gövde uyluk boyuna yakın çöker. R6'da bacaklar sabit, az çöker.
	local upperLeg = character:FindFirstChild("RightUpperLeg")
	if rig.joints.RightKnee and upperLeg then
		rig.drop = upperLeg.Size.Y * 0.9
	end

	return rig
end

local function smooth(x)
	return x * x * (3 - 2 * x)
end

-- Zaman t'deki pozu iki anahtar kare arasında yumuşakça hesaplar
local function sample(move, t)
	local keys = move.keys
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if t <= b.t then
			local s = smooth(math.clamp((t - a.t) / (b.t - a.t), 0, 1))
			local pose = {}
			for key, value in a.pose do
				pose[key] = value * (1 - s)
			end
			for key, value in b.pose do
				pose[key] = (pose[key] or 0) + value * s
			end
			return pose
		end
	end
	return {}
end

-- Eklemin Part0'a göre dönüş/konum ayarı: Motor6D için C0, AnimationConstraint için Attachment0.CFrame
local function setBase(joint, cframe)
	if joint.motor then
		joint.motor.C0 = cframe
	else
		joint.attachment.CFrame = cframe
	end
end

local function apply(rig, pose)
	-- Gövdenin çökmesi: kendi karakterimizde HipHeight azaltılır (ayaklar yerde kalır, gerçek fizikle iner).
	-- Diğer oyuncuların karakterinin konumu bizde simüle edilmediği için orada sadece kök eklem oynatılır.
	local dropAmount = rig.drop * (pose.Drop or 0)
	if rig.isLocal and rig.humanoid then
		rig.humanoid.HipHeight = math.max(0, rig.hip - dropAmount)
	end

	for key, joint in rig.joints do
		if key == "Root" then
			if not rig.isLocal then
				setBase(joint, CFrame.new(0, -dropAmount, 0) * joint.c0)
			end
		else
			local angle = math.rad(pose[key] or 0)
			-- Eklem konumu sabit kalır, dönüş karakterin X ekseni etrafında eklenir
			setBase(joint, CFrame.new(joint.c0.Position) * CFrame.Angles(angle, 0, 0) * joint.c0.Rotation)
		end
	end
end

-- Boyut ölçeği hareket sırasında değiştiyse: yeni konumları koru, sadece dönüşü eski hâline getir
local function restoreRotationOnly(rig)
	for key, joint in rig.joints do
		if key ~= "Root" then
			local current = if joint.motor then joint.motor.C0 else joint.attachment.CFrame
			setBase(joint, CFrame.new(current.Position) * joint.c0.Rotation)
		end
	end
end

local function restore(rig)
	if rig.isLocal and rig.humanoid then
		rig.humanoid.HipHeight = rig.hip
	end
	for _, joint in rig.joints do
		setBase(joint, joint.c0)
	end
end

function Moves.play(character, name)
	local move = MOVES[name]
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not move or not humanoid or humanoid.Health <= 0 then
		return
	end

	local state = active[character]
	if state and state.name == name then
		return -- aynı hareket zaten oynuyor, bitince yenisi başlar
	end

	local rig = getRig(character)
	if DEBUG then
		local count = 0
		for _ in rig.joints do
			count += 1
		end
		print(`[Moves] {name} on {character.Name}: {count} joints found, drop {rig.drop}`)
		if count == 0 then
			warn("[Moves] No joints found, the animation cannot play on this character")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			print(`[Moves] RigType: {humanoid and humanoid.RigType.Name}, children: {#character:GetChildren()}, descendants: {#character:GetDescendants()}`)
			for _, descendant in character:GetDescendants() do
				if descendant:IsA("JointInstance") or descendant:IsA("Constraint") then
					print(`[Moves] joint-like: {descendant.ClassName} "{descendant.Name}" in {descendant.Parent and descendant.Parent.Name}`)
				end
			end
		end
	end

	active[character] = { name = name, move = move, start = os.clock(), rig = rig }
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for character, state in active do
		local t = now - state.start
		local humanoid = state.rig.humanoid
		if state.rig.isLocal and humanoid and humanoid.FloorMaterial == Enum.Material.Air then
			-- Hareket sırasında zıpladı: bacak sallanması karakteri döndürmesin diye hareketi hemen bırak
			restore(state.rig)
			active[character] = nil
		elseif humanoid and scaleKey(humanoid) ~= state.rig.scaleKey then
			-- Karakter bu sırada büyüdü: hareketi bırak
			restoreRotationOnly(state.rig)
			active[character] = nil
		elseif t >= state.move.duration or not character.Parent then
			restore(state.rig)
			active[character] = nil
		else
			local ok, err = pcall(apply, state.rig, sample(state.move, t))
			if not ok then
				warn(`[Moves] Animation stopped: {err}`)
				active[character] = nil
			end
		end
	end
end)

return Moves
