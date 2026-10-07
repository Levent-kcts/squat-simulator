-- Sıralama panoları: iki bağımsız stand (kaide, çerçeve, başlık şeridi, sütunlar) hatasız kurulur; pcall'sız çağrılır ki hata gizlenmesin.
local S = require("./stubs")
rawset(S.workspace, "_children", {})
local Leaderboards = require("./Leaderboards")
Leaderboards.init()
local folder = rawget(S.workspace, "_children")["Leaderboards"]
assert(folder, "Leaderboards klasörü kurulmadı")
local names = rawget(folder, "_children")
for _, name in { "BoardPlinth", "BoardPlinthTop", "BoardFrameTop", "BoardFrameBottom", "BoardFrameSide", "BoardBrace", "BoardTrim", "BoardBanner", "LeaderboardPillar" } do
	assert(names[name], "stand parçası yok: " .. name)
end
local boards = 0
for name in names do
	if string.sub(name, 1, 6) == "Board_" then
		boards += 1
	end
end
assert(boards == 2, "iki pano yüzü olmalı, bulunan: " .. boards)
print("Leaderboards stand ok")
print("DONE")
