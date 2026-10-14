-- POWER HOUR göstergesi (Config.PowerHour, server/ServerEvents): küçük bir hap üstte ortada. Sadece iki durumda görünür: başlamasına son 90 saniye ('POWER HOUR in 0:45') ve aktifken ('POWER HOUR x2: 3:21 left', altın nabız).
-- Başlarken tek bildirim ('POWER HOUR! x2 Leg Muscle for N minutes!'). Ekran sade kalsın: ortada büyük yazı yok, gerisinde gizli. Baskı/kıtlık dili yok (sadece bonus, kaçan bir şey yok).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)

local PowerHourHud = {}

local WARN_SECONDS = 90
local GOLD = Color3.fromRGB(255, 205, 60)

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function PowerHourHud.init(screenGui, showToast)
	local settings = Config.PowerHour
	if not settings or not settings.Enabled then
		return
	end
	local pill = create("Frame", {
		Name = "PowerHourPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 64),
		Size = UDim2.fromOffset(250, 32),
		BackgroundColor3 = Color3.fromRGB(34, 30, 52),
		BackgroundTransparency = 0.1,
		Visible = false,
	}, screenGui)
	UIStyle.anchorCenter(pill)
	create("UICorner", { CornerRadius = UDim.new(0, 16) }, pill)
	local stroke = create("UIStroke", { Thickness = 2.5, Color = GOLD }, pill)
	local label = create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "",
	}, pill)
	create("UITextSizeConstraint", { MaxTextSize = 18 }, label)
	create("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0) }, label)
	local scale = create("UIScale", { Scale = 1 }, pill)
	local pulse = UIStyle.loopTween(TweenService:Create(scale, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.06 }), scale, { Scale = 1 })
	local pulsing = false

	local announcedFor = nil -- hangi bitiş zamanı için 'başladı' bildirimi verildi

	local function serverNow()
		local now = Workspace:GetServerTimeNow()
		return if type(now) == "number" then now else os.time()
	end

	local function render()
		local active = Workspace:GetAttribute("PowerHourActive") == true
		local at = Workspace:GetAttribute("PowerHourAt")
		if type(at) ~= "number" then
			pill.Visible = false
			return
		end
		local remaining = at - serverNow()
		if active then
			pill.Visible = true
			stroke.Color = GOLD
			label.Text = `⚡ {settings.Name} x{settings.Multiplier}: {clock(remaining)} left`
			if not pulsing then
				pulsing = true
				pulse:Play()
			end
			if announcedFor ~= at and showToast then
				announcedFor = at
				showToast(true, `{settings.Name}! x{settings.Multiplier} Leg Muscle for {settings.DurationMinutes} minutes!`)
			end
		else
			if pulsing then
				pulsing = false
				pulse:Cancel()
				scale.Scale = 1
			end
			if remaining <= WARN_SECONDS then
				pill.Visible = true
				stroke.Color = Color3.fromRGB(150, 150, 190)
				label.Text = `⚡ {settings.Name} in {clock(remaining)}`
			else
				pill.Visible = false
			end
		end
	end

	Workspace:GetAttributeChangedSignal("PowerHourActive"):Connect(render)
	Workspace:GetAttributeChangedSignal("PowerHourAt"):Connect(render)
	task.spawn(function()
		while true do
			render()
			task.wait(0.5)
		end
	end)
end

return PowerHourHud
