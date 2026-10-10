-- Performans yöneticisi (client/Performance): lobideki ışık/parçacık/SurfaceGui'lerin kameraya uzaklığa göre kısılması ve hafif grafik modu
local S = require("../cstubs")
local Performance = require("./Performance")

local workspace = S.game:GetService("Workspace")
local folder = workspace:FindFirstChild("ShoeShop")
assert(folder, "taklitte ShoeShop klasörü olmalı")

local function decor(name, x)
	local part = S.newInstance("Part")
	part.Name = name
	part.Position = S.Vector3.new(x, 0, 0)
	part.Parent = folder
	local light = S.newInstance("PointLight")
	light.Parent = part
	local fx = S.newInstance("ParticleEmitter")
	fx.Parent = part
	local gui = S.newInstance("SurfaceGui")
	gui.Parent = part
	return { light = light, fx = fx, gui = gui }
end
local near, mid, far = decor("Near", 10), decor("Mid", 60), decor("Far", 400)
rawset(workspace, "CurrentCamera", { CFrame = { Position = S.Vector3.new(0, 0, 0) } })

assert(Performance.low == false, "masaüstü taklidinde hafif mod kapalı başlar")
Performance.init()
local function tick()
	for _, callback in S.heartbeat do
		callback(0.5)
	end
end
tick()
local function on(entry)
	return rawget(entry.light, "Enabled") ~= false, rawget(entry.fx, "Enabled") ~= false, rawget(entry.gui, "Enabled") ~= false
end
local lightOn, fxOn, guiOn = on(near)
assert(lightOn and fxOn and guiOn, "yakın süsler açık kalmalı")
lightOn, fxOn, guiOn = on(mid)
assert(lightOn and fxOn and guiOn, "orta mesafedeki (60 stud) süsler normal modda açık (ışık menzili 75)")
lightOn, fxOn, guiOn = on(far)
assert(not lightOn and not fxOn and guiOn == false, "400 stud uzaktaki ışık, parçacık ve tabela kısılmalı")

-- Kamera uzağa gidince yakın olan kapanır, uzak olan açılır
rawset(workspace, "CurrentCamera", { CFrame = { Position = S.Vector3.new(400, 0, 0) } })
tick()
lightOn, fxOn, guiOn = on(far)
assert(lightOn and fxOn and guiOn, "kamera yaklaşınca açılmalı")
lightOn = on(near)
assert(not lightOn, "kamera uzaklaşınca kapanmalı")

-- Hafif mod: ışık menzili 45'e iner (60 stud'daki ışık kapanır), yerel gölgeler kapanır
rawset(workspace, "CurrentCamera", { CFrame = { Position = S.Vector3.new(0, 0, 0) } })
tick()
local changed = 0
Performance.onChange(function()
	changed += 1
end)
Performance.setLow()
Performance.setLow() -- ikinci çağrı bir şey değiştirmez
assert(Performance.low and changed == 1, "hafif moda bir kez geçilmeli: " .. changed)
tick()
lightOn, fxOn = on(mid)
assert(not lightOn and fxOn, "hafif modda 60 stud'daki ışık kapanır, parçacık (menzil 75) açık kalır")
lightOn = on(near)
assert(lightOn, "hafif modda da yakındaki ışık açık")
-- Telefon yerleşimi (Config.UI.Phone): sayılar tanımlı; sol HUD sola/yukarı (eksi), teyp sola (eksi) kayar
local Config = require("./Config")
local phone = Config.UI.Phone
assert(type(phone.LeftShiftX) == "number" and phone.LeftShiftX < 0 and type(phone.LeftShiftY) == "number" and phone.LeftShiftY < 0, "sol HUD telefonda sola ve yukarı kayar")
assert(type(phone.MusicShiftX) == "number" and phone.MusicShiftX < 0, "teyp telefonda sola kayar")
print("performance culling ok")
print("DONE")
