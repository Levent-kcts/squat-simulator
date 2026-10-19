-- Takip kamerası: _G.cfg = { base (derece), spd (rad/sn), dist (boy katı), hgt (boy katı), look (ileri bakış z), focus (boy katı) }
_G.camOn = false
task.wait(0.15)
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
_G.camOn = true
_G.cfg = _G.cfg or {}
task.spawn(function()
	local t0 = os.clock()
	local rs = game:GetService("RunService")
	while _G.camOn do
		local c = _G.cfg
		local ch = game.Players.LocalPlayer.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			local h = c.fixedH or ch:GetExtentsSize().Y
			local a = math.rad(c.base or 150) + (os.clock() - t0) * (c.spd or 0)
			local d = h * (c.dist or 1.6) + 4
			local center = hrp.Position + Vector3.new(0, h * (c.focus or 0.05), 0)
			cam.FieldOfView = c.fov or 70
			cam.CFrame = CFrame.lookAt(center + Vector3.new(math.sin(a) * d, h * (c.hgt or 0.35), math.cos(a) * d), center + Vector3.new(0, 0, c.look or 0))
		end
		rs.RenderStepped:Wait()
	end
	cam.CameraType = Enum.CameraType.Custom
end)
return "cam on"
