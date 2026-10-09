-- Yükleme ekranını başlatır (ReplicatedFirst'te oyundan önce çalışır). Mantık LoadingScreen modülündedir.
local ok, err = pcall(function()
	require(script.Parent:WaitForChild("LoadingScreen")).run()
end)
if not ok then
	warn(`[Loading] Loading screen failed: {err}`)
end
