-- Yükleme ekranını başlatır (ReplicatedFirst'te oyundan önce çalışır). Mantık ReplicatedStorage.Shared.LoadingScreen modülündedir
-- (init.client'taki yedek de aynı modülü çağırır; run() ikinci çağrıda kendiliğinden çıkar, iki ekran açılmaz).
-- Shared gelene kadar Roblox'un kendi yükleme ekranı görünmeye devam eder.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ok, err = pcall(function()
	local shared = ReplicatedStorage:WaitForChild("Shared", 20)
	require(shared:WaitForChild("LoadingScreen", 20)).run()
end)
if not ok then
	warn(`[Loading] Loading screen failed: {err}`)
end
