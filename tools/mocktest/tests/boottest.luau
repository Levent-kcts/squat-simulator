-- Sunucu açılışı: init.server tüm modülleriyle (Hub, WallService, raflar, antrenman alanı, yumurtalar, izler, auralar...) hatasız kurulmalı,
-- sonra bir oyuncu girişi (PlayerAdded dinleyicileri) hatasız işlenmeli. Özellik/enum adı geçerliliğini DOĞRULAMAZ.
local S = require("./cstubs")
require("./Config").PowerHour.Enabled = false
local ok, err = pcall(require, "./serverMain")
print("server boot:", ok, err)
if not ok then
	print("ERROR server boot failed: " .. tostring(err))
end
local player = S.newInstance("Player")
player.Name = "BootPlayer"
player.UserId = 99
rawset(player, "Parent", S.newInstance("Players"))
for index, handler in S.playerAdded do
	local handled, message = pcall(handler, player)
	if not handled then
		print("ERROR PlayerAdded handler " .. index .. ": " .. tostring(message))
	end
end
for index, handler in S.playerRemoving do
	local handled, message = pcall(handler, player)
	if not handled then
		print("ERROR PlayerRemoving handler " .. index .. ": " .. tostring(message))
	end
end
print("DONE")
