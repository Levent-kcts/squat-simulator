"""Sunucunun kurduğu dünyadaki nesneleri SAYAR (parça, parçacık, ışık, billboard...): mobil performans için bütçe takibi.
Kullanım: python tools/perfcount.py
Oyunun sunucu açılışını (init.server) tools/mocktest taklitleriyle çalıştırır ve Workspace altındaki nesneleri sınıfa ve üst klasöre göre sayar.
Not: duvarlar oyuncuya özel ISTEMCİDE kurulur (client/WallClient), burada sayılmaz; sayılar tahmini ama karşılaştırma için tutarlıdır.
"""
import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
import mocktest  # noqa: E402

COUNT_LUAU = r'''
local S = require("./cstubs")
local ok, err = pcall(require, "./serverMain")
if not ok then
	print("boot hatası:", err)
end
local workspace = S.game:GetService("Workspace")
local byClass, byTop, parts = {}, {}, {}
local function walk(instance, top)
	for _, child in rawget(instance, "_children") do
		local className = rawget(child, "ClassName") or "?"
		byClass[className] = (byClass[className] or 0) + 1
		local group = top or rawget(child, "Name") or "?"
		byTop[group] = byTop[group] or { total = 0, parts = 0, emitters = 0, lights = 0, guis = 0 }
		local entry = byTop[group]
		entry.total += 1
		if className == "Part" or className == "MeshPart" or className == "WedgePart" or className == "UnionOperation" then
			entry.parts += 1
		elseif className == "ParticleEmitter" then
			entry.emitters += 1
		elseif className == "PointLight" or className == "SpotLight" or className == "SurfaceLight" then
			entry.lights += 1
		elseif className == "BillboardGui" or className == "SurfaceGui" then
			entry.guis += 1
		end
		walk(child, group)
	end
end
walk(workspace, nil)
local classes = {}
for name, count in byClass do
	table.insert(classes, { name, count })
end
table.sort(classes, function(a, b) return a[2] > b[2] end)
print("== SINIFA GÖRE")
for _, row in classes do
	print(string.format("%-20s %6d", row[1], row[2]))
end
local groups = {}
for name, entry in byTop do
	table.insert(groups, { name, entry })
end
table.sort(groups, function(a, b) return a[2].total > b[2].total end)
print("== ÜST KLASÖRE GÖRE (toplam, parça, parçacık, ışık, gui)")
for index, row in groups do
	if index <= 40 then
		print(string.format("%-28s %6d %6d %5d %5d %5d", row[1], row[2].total, row[2].parts, row[2].emitters, row[2].lights, row[2].guis))
	end
end
'''


def main():
    target = tempfile.mkdtemp(prefix="perfcount_")
    try:
        mocktest.build(target)
        with open(os.path.join(target, "perfcount.luau"), "w", encoding="utf-8") as f:
            f.write(COUNT_LUAU)
        result = subprocess.run([mocktest.LUAU, "perfcount.luau"], capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=target, timeout=180)
        print(result.stdout)
        if result.returncode != 0:
            print(result.stderr[-2000:])
    finally:
        shutil.rmtree(target, ignore_errors=True)


if __name__ == "__main__":
    main()
