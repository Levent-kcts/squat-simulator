-- İstemci modülleri için çok izin verici Roblox taklidi: bilinmeyen her özellik/olay/metot bir 'proxy' döndürür (Connect, çağrı, aritmetik hepsi çalışır).
-- Amaç: Luau mantık hatalarını (nil indeksleme, yanlış değişken, yanlış alan) çalıştırarak yakalamak; özellik adlarının geçerliliğini DOĞRULAMAZ.
local M = require("./stubs")

local proxyMT = {}
local function proxy()
	return setmetatable({}, proxyMT)
end
proxyMT.__index = function(_, k)
	if k == "Connect" then
		return function(self, f)
			return proxy()
		end
	end
	return proxy()
end
proxyMT.__call = function()
	return proxy()
end
proxyMT.__mul = function(a)
	return a
end
proxyMT.__add = function(a)
	return a
end
proxyMT.__sub = function(a)
	return a
end
proxyMT.__div = function(a)
	return a
end
proxyMT.__unm = function(a)
	return a
end
proxyMT.__lt = function()
	return false
end
proxyMT.__le = function()
	return false
end
proxyMT.__concat = function()
	return ""
end
proxyMT.__len = function()
	return 0
end
M.proxy = proxy

-- Vector3: aritmetik ve Magnitude destekler
local V3MT = {}
local function V3(x, y, z)
	return setmetatable({ X = x, Y = y, Z = z }, V3MT)
end
V3MT.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X ^ 2 + t.Y ^ 2 + t.Z ^ 2)
	end
	return nil
end
V3MT.__sub = function(a, b)
	return V3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3MT.__add = function(a, b)
	return V3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3MT.__mul = function(a, b)
	if type(b) == "number" then
		return V3(a.X * b, a.Y * b, a.Z * b)
	elseif type(a) == "number" then
		return V3(b.X * a, b.Y * a, b.Z * a)
	end
	return V3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3MT.__div = function(a, b)
	return V3(a.X / b, a.Y / b, a.Z / b)
end
M.Vector3 = { new = V3, zero = V3(0, 0, 0), one = V3(1, 1, 1) }
M.Vector2 = M.Vector3

-- Instance: kayıtlı özellikler okunur, kayıtsızlar proxy döner
local InstMT = {}
local function newInstance(className)
	local inst = { ClassName = className, _children = {}, _attrs = {}, Name = className }
	return setmetatable(inst, InstMT)
end
InstMT.__index = function(self, key)
	local attrs = rawget(self, "_attrs")
	local children = rawget(self, "_children")
	if key == "FindFirstChild" then
		return function(s, name)
			return children[name]
		end
	elseif key == "WaitForChild" then
		-- Roblox'ta gelene kadar bekler; taklitte eksikse boş bir örnek oluşturulur ve ebeveyne eklenir
		return function(s, name)
			local found = children[name]
			if not found then
				found = newInstance("Folder")
				found.Name = name
				found.Parent = s
			end
			return found
		end
	elseif key == "FindFirstChildOfClass" then
		return function(s, className)
			for _, child in children do
				if rawget(child, "ClassName") == className then
					return child
				end
			end
			return nil
		end
	elseif key == "SetAttribute" then
		return function(s, k, v)
			local old = attrs[k]
			attrs[k] = v
			local signals = rawget(self, "_signals")
			if signals and signals[k] and old ~= v then
				for _, f in signals[k] do
					f()
				end
			end
		end
	elseif key == "GetAttribute" then
		return function(s, k)
			return attrs[k]
		end
	elseif key == "GetAttributeChangedSignal" then
		return function(s, k)
			return {
				Connect = function(_, f)
					local signals = rawget(self, "_signals")
					if not signals then
						signals = {}
						rawset(self, "_signals", signals)
					end
					signals[k] = signals[k] or {}
					table.insert(signals[k], f)
					return proxy()
				end,
			}
		end
	elseif key == "GetChildren" or key == "GetDescendants" then
		return function()
			local list = {}
			for _, child in children do
				table.insert(list, child)
			end
			return list
		end
	elseif key == "Destroy" or key == "ClearAllChildren" then
		return function() end
	elseif key == "IsA" then
		return function(s, name)
			return rawget(s, "ClassName") == name or name == "GuiObject" or name == "BasePart"
		end
	elseif key == "AbsoluteSize" or key == "AbsolutePosition" then
		return { X = 600, Y = 400 }
	elseif key == "Character" or key == "Parent" then
		return nil -- ayarlanmadıysa yok (Roblox'ta da karakter henüz yokken nil)
	end
	local gray = M.Color3.new(0.5, 0.5, 0.5)
	local defaults = { BackgroundTransparency = 0, Transparency = 0, ZIndex = 1, TextTransparency = 0, Visible = true, Active = true, Rotation = 0, Thickness = 1, BackgroundColor3 = gray, TextColor3 = gray, ImageColor3 = gray, Color = gray }
	if defaults[key] ~= nil then
		return defaults[key]
	end
	return proxy()
end
InstMT.__newindex = function(self, key, value)
	rawset(self, key, value)
	if key == "Parent" and type(value) == "table" and rawget(value, "_children") then
		local children = rawget(value, "_children")
		local name = rawget(self, "Name")
		local unique = name
		local index = 1
		while children[unique] and children[unique] ~= self do
			index += 1
			unique = name .. "#" .. index
		end
		children[unique] = self
	end
end
local generic2 = setmetatable({}, { __index = function() return function() return proxy() end end })
M.UDim2 = generic2
M.UDim = generic2
M.CFrame = generic2
M.NumberSequence = generic2
M.NumberSequenceKeypoint = generic2
M.ColorSequence = generic2
M.NumberRange = generic2
M.TweenInfo = generic2
M.G = generic2
M.Instance = { new = newInstance }
M.newInstance = newInstance

-- Servisler: istemci için gereken kadar
local heartbeat = {}
M.heartbeat = heartbeat
local RunService = {
	Heartbeat = {
		Connect = function(_, f)
			table.insert(heartbeat, f)
			return proxy()
		end,
	},
	RenderStepped = { Connect = function() return proxy() end },
	IsStudio = function() return true end,
}
local localPlayer = newInstance("Player")
localPlayer.Name = "Local"
local root = newInstance("Part")
root.Position = V3(0, 3, 0)
local character = newInstance("Model")
character.Name = "Character"
rawget(character, "_children")["HumanoidRootPart"] = root
localPlayer.Character = character
M.localPlayer = localPlayer
M.root = root
local ReplicatedStorage = newInstance("ReplicatedStorage")
M.replicated = ReplicatedStorage
local remoteFunction = newInstance("RemoteFunction")
remoteFunction.InvokeServer = function(_, action, id)
	M.lastInvoke = { action, id }
	return true, "ok:" .. tostring(action)
end
M.remoteFunction = remoteFunction
rawget(ReplicatedStorage, "_children")["Shop"] = remoteFunction
M.playerAdded = {}
M.playerRemoving = {}
local services = {
	RunService = RunService,
	Players = { LocalPlayer = localPlayer, PlayerAdded = { Connect = function(_, f) table.insert(M.playerAdded, f) return proxy() end }, PlayerRemoving = { Connect = function(_, f) table.insert(M.playerRemoving, f) return proxy() end }, GetPlayers = function() return {} end, GetPlayerFromCharacter = function() return nil end },
	DataStoreService = { GetDataStore = function() return {
		GetAsync = function(_, key) return M.datastore[key] end,
		UpdateAsync = function(_, key, fn) M.datastore[key] = fn(M.datastore[key]) return M.datastore[key] end,
	} end },
	ReplicatedStorage = ReplicatedStorage,
	Workspace = (function()
		local ws = newInstance("Workspace")
		for _, name in { "ShoeShop", "SkinShop", "TrainingArea", "EggShop", "Hub", "Course", "Lobby" } do
			local folder = newInstance("Folder")
			folder.Name = name
			folder.Parent = ws
		end
		return ws
	end)(),
	HttpService = {
		JSONDecode = function()
			return M.jsonData
		end,
		JSONEncode = function(_, v)
			local function encode(x)
				if type(x) == "table" then
					local parts = {}
					if #x > 0 then
						for _, y in x do
							table.insert(parts, encode(y))
						end
						return "[" .. table.concat(parts, ",") .. "]"
					end
					for k, y in x do
						table.insert(parts, '"' .. tostring(k) .. '":' .. encode(y))
					end
					return "{" .. table.concat(parts, ",") .. "}"
				elseif type(x) == "string" then
					return '"' .. x .. '"'
				end
				return tostring(x)
			end
			return encode(v)
		end,
	},
}
M.game = {
	GetService = function(_, name)
		return services[name] or proxy()
	end,
	BindToClose = function() end,
}
M.workspace = {
	CurrentCamera = { ViewportSize = { X = 1534, Y = 862 }, GetPropertyChangedSignal = function() return { Connect = function() return proxy() end } end },
	GetServerTimeNow = function() return os.time() + 0.0 end,
}
M.Enum = setmetatable({}, {
	__index = function(_, enumName)
		return setmetatable({}, {
			__index = function(_, itemName)
				return enumName .. "." .. itemName
			end,
		})
	end,
})
return M
