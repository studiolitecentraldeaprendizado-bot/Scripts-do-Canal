-- DYNO BUILD TRANSFER v1
-- LocalScript em StarterPlayerScripts
-- o sistema e totalmente comitado para aqueles que quiserem fazer novas versões do sistema.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Tamanho de cada parte no modo normal (a TextBox aceita no máximo 200.000 caracteres)
local CHUNK_LIMIT = 60000
local TEXTBOX_MAX = 190000

-- Classes que o Instance.new consegue recriar fielmente
local EXACT = {
	Part = true,
	WedgePart = true,
	CornerWedgePart = true,
	TrussPart = true,
	SpawnLocation = true,
	Seat = true,
	VehicleSeat = true,
}

-- Objetos filhos das peças que o scanner também exporta
-- Cada item: {propriedade, tipo}. Tipos: n número, s texto, b booleano,
-- c cor, v3 vetor, e:NomeDoEnum
local CHILD_PROPS = {
	Decal = { {"Texture","s"}, {"Face","e:NormalId"}, {"Transparency","n"}, {"Color3","c"}, {"ZIndex","n"} },
	Texture = { {"Texture","s"}, {"Face","e:NormalId"}, {"Transparency","n"}, {"Color3","c"}, {"ZIndex","n"},
		{"StudsPerTileU","n"}, {"StudsPerTileV","n"}, {"OffsetStudsU","n"}, {"OffsetStudsV","n"} },
	PointLight = { {"Brightness","n"}, {"Color","c"}, {"Range","n"}, {"Shadows","b"}, {"Enabled","b"} },
	SpotLight = { {"Brightness","n"}, {"Color","c"}, {"Range","n"}, {"Angle","n"}, {"Face","e:NormalId"},
		{"Shadows","b"}, {"Enabled","b"} },
	SurfaceLight = { {"Brightness","n"}, {"Color","c"}, {"Range","n"}, {"Angle","n"}, {"Face","e:NormalId"},
		{"Shadows","b"}, {"Enabled","b"} },
	SpecialMesh = { {"MeshId","s"}, {"TextureId","s"}, {"MeshType","e:MeshType"}, {"Scale","v3"},
		{"Offset","v3"}, {"VertexColor","v3"} },
	SurfaceAppearance = { {"ColorMap","s"}, {"NormalMap","s"}, {"MetalnessMap","s"}, {"RoughnessMap","s"},
		{"AlphaMode","e:AlphaMode"} },
	Fire = { {"Color","c"}, {"SecondaryColor","c"}, {"Size","n"}, {"Heat","n"}, {"Enabled","b"} },
	Smoke = { {"Color","c"}, {"Size","n"}, {"Opacity","n"}, {"RiseVelocity","n"}, {"Enabled","b"} },
}

-- Código que roda no outro Studio (vai dentro de cada parte exportada)
local LOADER = [==[
local root = workspace:FindFirstChild(rootName) or Instance.new("Folder")
root.Name = rootName
root.Parent = workspace

local cache = {}
local function container(pi)
	if cache[pi] then return cache[pi] end
	local cur = root
	local p = paths[pi]
	for i = 1, #p, 2 do
		local class = "Folder"
		if p[i] == "M" then class = "Model" end
		local nxt = nil
		for _, c in ipairs(cur:GetChildren()) do
			if c.Name == p[i + 1] and c.ClassName == class then
				nxt = c
				break
			end
		end
		if not nxt then
			nxt = Instance.new(class)
			nxt.Name = p[i + 1]
			nxt.Parent = cur
		end
		cur = nxt
	end
	cache[pi] = cur
	return cur
end

local AssetService = nil
pcall(function()
	AssetService = game:GetService("AssetService")
end)

local function applyProps(inst, props)
	for _, pr in ipairs(props) do
		local name = pr[1]
		local kind = pr[2]
		local v = pr[3]
		pcall(function()
			if kind == "c" then
				v = Color3.fromHex(v)
			elseif kind == "v3" then
				v = Vector3.new(v[1], v[2], v[3])
			elseif string.sub(kind, 1, 2) == "e:" then
				v = Enum[string.sub(kind, 3)][v]
			end
			inst[name] = v
		end)
	end
end

local meshFalhou = 0

for i, r in ipairs(rows) do
	local ex = r[19]
	local p = nil
	if r[1] == "MeshPart" then
		if AssetService and ex and ex.m then
			local ok, mp = pcall(function()
				return AssetService:CreateMeshPartAsync(ex.m)
			end)
			if ok and mp then
				p = mp
			end
		end
		if not p then
			p = Instance.new("Part")
			meshFalhou = meshFalhou + 1
		end
	else
		p = Instance.new(r[1])
	end
	p.Name = r[2]
	if r[17] then p.Shape = Enum.PartType[r[17]] end
	p.Size = Vector3.new(r[3], r[4], r[5])
	p.CFrame = CFrame.new(r[6], r[7], r[8]) * CFrame.fromOrientation(r[9], r[10], r[11])
	p.Color = Color3.fromHex(r[12])
	p.Transparency = r[13]
	p.Anchored = (r[14] == 1)
	p.CanCollide = (r[15] == 1)
	p.Material = Enum.Material[r[16]]
	if ex then
		if ex.p then applyProps(p, ex.p) end
		if ex.k then
			for _, k in ipairs(ex.k) do
				local ok, child = pcall(Instance.new, k[1])
				if ok and child then
					child.Name = k[2]
					applyProps(child, k[3])
					child.Parent = p
				end
			end
		end
	end
	p.Parent = container(r[18])
	if i % 200 == 0 then task.wait() end
end

print("Dyno Build Transfer: " .. #rows .. " pecas criadas")
if meshFalhou > 0 then
	print("Dyno Build Transfer: " .. meshFalhou .. " meshes viraram blocos (Studio sem acesso a malhas ou asset sem acesso)")
end
]==]

----------------------------------------------------------------
-- Helpers de interface
----------------------------------------------------------------
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function round(inst, r)
	new("UICorner", { CornerRadius = UDim.new(0, r) }, inst)
end

local gui = new("ScreenGui", {
	Name = "DynoBuildTransfer",
	ResetOnSpawn = false,
}, playerGui)

local frame = new("Frame", {
	Size = UDim2.new(0.78, 0, 0.8, 0),
	Position = UDim2.new(0.11, 0, 0.1, 0),
	BackgroundColor3 = Color3.fromRGB(16, 24, 18),
	BorderSizePixel = 0,
}, gui)
round(frame, 12)

local titleLabel = new("TextLabel", {
	Active = true,
	Size = UDim2.new(1, -100, 0, 40),
	Position = UDim2.new(0, 12, 0, 5),
	BackgroundTransparency = 1,
	Text = "DYNO BUILD TRANSFER",
	TextColor3 = Color3.fromRGB(100, 255, 122),
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
}, frame)

local close = new("TextButton", {
	Size = UDim2.new(0, 38, 0, 38),
	Position = UDim2.new(1, -46, 0, 6),
	Text = "X",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	BackgroundColor3 = Color3.fromRGB(55, 70, 58),
}, frame)
round(close, 8)
close.Activated:Connect(function()
	gui:Destroy()
end)

local status = new("TextLabel", {
	Size = UDim2.new(1, -24, 0, 24),
	Position = UDim2.new(0, 12, 0, 46),
	BackgroundTransparency = 1,
	Text = "Pronto para escanear",
	TextColor3 = Color3.fromRGB(200, 220, 203),
	TextSize = 13,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
}, frame)

local scopeBox = new("TextBox", {
	Size = UDim2.new(1, -24, 0, 34),
	Position = UDim2.new(0, 12, 0, 74),
	BackgroundColor3 = Color3.fromRGB(25, 38, 28),
	PlaceholderText = "Nome do modelo/pasta (vazio = Workspace inteiro)",
	PlaceholderColor3 = Color3.fromRGB(120, 150, 125),
	Text = "",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
	Font = Enum.Font.Gotham,
	ClearTextOnFocus = false,
}, frame)
round(scopeBox, 8)

local scan = new("TextButton", {
	Size = UDim2.new(0.55, -16, 0, 40),
	Position = UDim2.new(0, 12, 0, 114),
	BackgroundColor3 = Color3.fromRGB(36, 130, 54),
	Text = "ESCANEAR",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 15,
	Font = Enum.Font.GothamBold,
}, frame)
round(scan, 8)

local partyBtn = new("TextButton", {
	Size = UDim2.new(0.45, -16, 0, 40),
	Position = UDim2.new(0.55, 4, 0, 114),
	BackgroundColor3 = Color3.fromRGB(55, 70, 58),
	Text = "MODO FESTA: OFF",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 12,
	Font = Enum.Font.GothamBold,
}, frame)
round(partyBtn, 8)

local prevBtn = new("TextButton", {
	Size = UDim2.new(0.25, -8, 0, 34),
	Position = UDim2.new(0, 12, 0, 160),
	BackgroundColor3 = Color3.fromRGB(55, 70, 58),
	Text = "< Anterior",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 12,
	Font = Enum.Font.GothamBold,
}, frame)
round(prevBtn, 8)

local pageLabel = new("TextLabel", {
	Size = UDim2.new(0.5, -8, 0, 34),
	Position = UDim2.new(0.25, 4, 0, 160),
	BackgroundTransparency = 1,
	Text = "Parte 0/0",
	TextColor3 = Color3.fromRGB(200, 220, 203),
	TextSize = 13,
	Font = Enum.Font.GothamBold,
}, frame)

local nextBtn = new("TextButton", {
	Size = UDim2.new(0.25, -8, 0, 34),
	Position = UDim2.new(0.75, -4, 0, 160),
	BackgroundColor3 = Color3.fromRGB(55, 70, 58),
	Text = "Próxima >",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 12,
	Font = Enum.Font.GothamBold,
}, frame)
round(nextBtn, 8)

local output = new("TextBox", {
	Size = UDim2.new(1, -24, 1, -208),
	Position = UDim2.new(0, 12, 0, 200),
	BackgroundColor3 = Color3.fromRGB(25, 38, 28),
	TextColor3 = Color3.fromRGB(150, 255, 165),
	TextSize = 12,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = false,
	MultiLine = true,
	ClearTextOnFocus = false,
	TextEditable = true,
	Text = "-- O código aparecerá aqui",
}, frame)
round(output, 8)

----------------------------------------------------------------
-- Painel flutuante: arrastar pelo título e minimizar
----------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")

local dragging = false
local dragStart = nil
local startPos = nil

titleLabel.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local d = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y
		)
	end
end)

local minBtn = new("TextButton", {
	Size = UDim2.new(0, 38, 0, 38),
	Position = UDim2.new(1, -90, 0, 6),
	Text = "-",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	BackgroundColor3 = Color3.fromRGB(55, 70, 58),
}, frame)
round(minBtn, 8)

local bodyItems = { status, scopeBox, scan, partyBtn, prevBtn, pageLabel, nextBtn, output }
local fullSize = frame.Size
local minimized = false

minBtn.Activated:Connect(function()
	minimized = not minimized
	for _, item in ipairs(bodyItems) do
		item.Visible = not minimized
	end
	if minimized then
		frame.Size = UDim2.new(0.4, 0, 0, 50)
		minBtn.Text = "+"
	else
		frame.Size = fullSize
		minBtn.Text = "-"
	end
end)

----------------------------------------------------------------
-- Páginas (partes do código exportado)
----------------------------------------------------------------
local pages = {}
local current = 0

local function showPage(i)
	if #pages == 0 then
		return
	end
	current = math.clamp(i, 1, #pages)
	output.Text = pages[current]
	pageLabel.Text = "Parte " .. current .. "/" .. #pages
end

prevBtn.Activated:Connect(function()
	showPage(current - 1)
end)

nextBtn.Activated:Connect(function()
	showPage(current + 1)
end)

----------------------------------------------------------------
-- Modo festa
----------------------------------------------------------------
local partyMode = false

partyBtn.Activated:Connect(function()
	partyMode = not partyMode
	if partyMode then
		partyBtn.Text = "MODO FESTA: ON"
		partyBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 160)
		status.Text = "Modo festa: tudo num script só. Pode travar ou ser cortado em construções grandes."
	else
		partyBtn.Text = "MODO FESTA: OFF"
		partyBtn.BackgroundColor3 = Color3.fromRGB(55, 70, 58)
		status.Text = "Modo normal: código dividido em partes."
	end
end)

----------------------------------------------------------------
-- Funções do scanner
----------------------------------------------------------------

-- Número compacto (sem zeros desnecessários)
local function n(x, d)
	local s = string.format("%." .. (d or 3) .. "f", x)
	if s:find("%.") then
		s = s:gsub("0+$", "")
		s = s:gsub("%.$", "")
	end
	if s == "-0" or s == "" then
		s = "0"
	end
	return s
end

-- Ignora personagens de jogadores e NPCs (qualquer Model com Humanoid)
local function isCharacter(part)
	local m = part:FindFirstAncestorOfClass("Model")
	while m do
		if m:FindFirstChildOfClass("Humanoid") then
			return true
		end
		local parent = m.Parent
		if parent then
			m = parent:FindFirstAncestorOfClass("Model")
		else
			m = nil
		end
	end
	return false
end

-- Cadeia de Models/Folders entre o escopo e a peça
local function chainOf(part, scope)
	local chain = {}
	local cur = part.Parent
	while cur and cur ~= scope and cur ~= workspace do
		table.insert(chain, 1, cur)
		cur = cur.Parent
	end
	return chain
end

local function newChunk()
	return { rows = {}, paths = {}, index = {}, len = 0 }
end

-- Devolve o índice do caminho (Models/Folders) dentro do chunk
local function getPathIndex(chunk, chain)
	local flat = {}
	local keyParts = {}
	for _, anc in ipairs(chain) do
		local kind = "F"
		if anc:IsA("Model") then
			kind = "M"
		end
		table.insert(flat, kind)
		table.insert(flat, anc.Name)
		table.insert(keyParts, kind .. anc.Name)
	end
	local key = table.concat(keyParts, "\n")
	local pi = chunk.index[key]
	if not pi then
		table.insert(chunk.paths, flat)
		pi = #chunk.paths
		chunk.index[key] = pi
		chunk.len = chunk.len + #key + 20
	end
	return pi
end

-- Converte um valor para texto de código Lua
local function enc(kind, v)
	if kind == "n" then
		return n(v, 3)
	elseif kind == "s" then
		return string.format("%q", tostring(v))
	elseif kind == "b" then
		if v then
			return "true"
		end
		return "false"
	elseif kind == "c" then
		return string.format("%q", v:ToHex())
	elseif kind == "v3" then
		return "{" .. n(v.X) .. "," .. n(v.Y) .. "," .. n(v.Z) .. "}"
	end
	return string.format("%q", v.Name)
end

local function propEntry(name, kind, v)
	return "{" .. string.format("%q", name) .. "," .. string.format("%q", kind) .. "," .. enc(kind, v) .. "}"
end

local function propsString(inst, defs)
	local out = {}
	for _, d in ipairs(defs) do
		local ok, v = pcall(function()
			return inst[d[1]]
		end)
		if ok and v ~= nil then
			table.insert(out, propEntry(d[1], d[2], v))
		end
	end
	return "{" .. table.concat(out, ",") .. "}"
end

-- Extras da peça: malha, propriedades extras e filhos (decals, luzes...)
local function buildExtras(part, isMesh)
	local pp = {}
	if part.Reflectance ~= 0 then
		table.insert(pp, propEntry("Reflectance", "n", part.Reflectance))
	end
	if part.CastShadow == false then
		table.insert(pp, propEntry("CastShadow", "b", false))
	end
	if part.CanTouch == false then
		table.insert(pp, propEntry("CanTouch", "b", false))
	end
	if part.CanQuery == false then
		table.insert(pp, propEntry("CanQuery", "b", false))
	end

	local meshId = nil
	if isMesh then
		meshId = tostring(part.MeshId)
		if meshId ~= "" and tostring(part.TextureID) ~= "" then
			table.insert(pp, propEntry("TextureID", "s", part.TextureID))
		end
	end

	local kids = {}
	for _, ch in ipairs(part:GetChildren()) do
		local defs = CHILD_PROPS[ch.ClassName]
		if defs then
			table.insert(kids, "{" .. string.format("%q", ch.ClassName) .. ","
				.. string.format("%q", ch.Name) .. "," .. propsString(ch, defs) .. "}")
		end
	end

	local hasMesh = (meshId ~= nil and meshId ~= "")
	if #pp == 0 and #kids == 0 and not hasMesh then
		return nil
	end

	local fields = {}
	if hasMesh then
		table.insert(fields, "m=" .. string.format("%q", meshId))
	end
	if #pp > 0 then
		table.insert(fields, "p={" .. table.concat(pp, ",") .. "}")
	end
	if #kids > 0 then
		table.insert(fields, "k={" .. table.concat(kids, ",") .. "}")
	end
	return "{" .. table.concat(fields, ",") .. "}"
end

-- Monta a linha de dados de uma peça. Devolve a linha, se foi aproximada e se é mesh.
local function buildRow(part, pi)
	local exact = (EXACT[part.ClassName] == true)
	local isMesh = (part.ClassName == "MeshPart")
	local class = "Part"
	if exact then
		class = part.ClassName
	elseif isMesh then
		class = "MeshPart"
	end

	local shape = "false"
	if class == "Part" or class == "SpawnLocation" then
		local shapeName = "Block"
		if exact then
			shapeName = part.Shape.Name
		end
		shape = string.format("%q", shapeName)
	end

	local anchored = 0
	if part.Anchored then
		anchored = 1
	end
	local collide = 0
	if part.CanCollide then
		collide = 1
	end

	local s = part.Size
	local pos = part.Position
	local rx, ry, rz = part.CFrame:ToOrientation()

	local row = string.format(
		"{%q,%q,%s,%s,%s,%s,%s,%s,%s,%s,%s,%q,%s,%d,%d,%q,%s,%d",
		class,
		part.Name,
		n(s.X), n(s.Y), n(s.Z),
		n(pos.X), n(pos.Y), n(pos.Z),
		n(rx, 4), n(ry, 4), n(rz, 4),
		part.Color:ToHex(),
		n(part.Transparency, 2),
		anchored,
		collide,
		part.Material.Name,
		shape,
		pi
	)

	local extras = buildExtras(part, isMesh)
	if extras then
		row = row .. "," .. extras
	end
	row = row .. "}"

	return row, (not exact and not isMesh), isMesh
end

local function chunkToText(chunk, i, total, rootName, party)
	local pathLines = {}
	for _, p in ipairs(chunk.paths) do
		local q = {}
		for _, v in ipairs(p) do
			table.insert(q, string.format("%q", v))
		end
		table.insert(pathLines, "{" .. table.concat(q, ",") .. "}")
	end

	local titulo = "-- DYNO BUILD TRANSFER | parte " .. i .. "/" .. total
	if party then
		titulo = "-- DYNO BUILD TRANSFER | MODO FESTA (script inteiro)"
	end

	return table.concat({
		titulo,
		"-- Cole num Script (servidor) no outro Studio e rode.",
		"-- Se tiver várias partes, rode todas, em qualquer ordem.",
		"-- Rodou duas vezes? Apague a pasta '" .. rootName .. "' antes.",
		"local rootName = " .. string.format("%q", rootName),
		"local paths = {" .. table.concat(pathLines, ",") .. "}",
		"local rows = {",
		table.concat(chunk.rows, ",\n"),
		"}",
		LOADER,
	}, "\n")
end

-- Escaneia e devolve: textos, total, aproximadas, ignoradas
local function scanScope(scopeText, party, onProgress)
	local name = scopeText:match("^%s*(.-)%s*$")
	local scope = workspace
	if name ~= "" then
		scope = workspace:FindFirstChild(name, true)
		if not scope then
			error("Não achei '" .. name .. "' no Workspace", 0)
		end
	end

	local rootName = "MapaImportado"
	if name ~= "" then
		rootName = name
	end

	local limit = CHUNK_LIMIT
	if party then
		limit = math.huge
	end

	local list = {}
	for _, o in ipairs(scope:GetDescendants()) do
		if o:IsA("BasePart") and not o:IsA("Terrain") then
			table.insert(list, o)
		end
	end

	local chunks = {}
	local chunk = newChunk()
	local total = 0
	local approx = 0
	local meshes = 0
	local skipped = 0

	for i, part in ipairs(list) do
		if isCharacter(part) then
			skipped = skipped + 1
		else
			local chain = chainOf(part, scope)
			local pi = getPathIndex(chunk, chain)
			local row, wasApprox, isMesh = buildRow(part, pi)

			table.insert(chunk.rows, row)
			chunk.len = chunk.len + #row + 2
			total = total + 1
			if wasApprox then
				approx = approx + 1
			end
			if isMesh then
				meshes = meshes + 1
			end

			if chunk.len >= limit then
				table.insert(chunks, chunk)
				chunk = newChunk()
			end
		end

		if i % 300 == 0 then
			onProgress(i, #list)
			task.wait()
		end
	end

	if #chunk.rows > 0 then
		table.insert(chunks, chunk)
	end

	local texts = {}
	for i, ch in ipairs(chunks) do
		table.insert(texts, chunkToText(ch, i, #chunks, rootName, party))
	end

	return texts, total, approx, skipped, meshes
end

----------------------------------------------------------------
-- Botão de escanear
----------------------------------------------------------------
local busy = false

local function onProgress(i, total)
	status.Text = "Processando: " .. i .. " / " .. total
end

scan.Activated:Connect(function()
	if busy then
		return
	end
	busy = true
	scan.Text = "ESCANEANDO..."
	status.Text = "Procurando peças..."

	local ok, texts, total, approx, skipped, meshes = pcall(scanScope, scopeBox.Text, partyMode, onProgress)

	if ok then
		if #texts == 0 then
			pages = {}
			current = 0
			pageLabel.Text = "Parte 0/0"
			output.Text = "-- Nenhuma peça encontrada"
			status.Text = "Nenhuma peça encontrada"
		else
			pages = texts
			showPage(1)
			local msg = "Concluído: " .. total .. " peças"
				.. " | meshes: " .. meshes
				.. " | aproximadas (union): " .. approx
				.. " | ignoradas (personagens): " .. skipped
			if #texts[1] > TEXTBOX_MAX then
				msg = msg .. " | AVISO: passa de 200 mil caracteres, o texto pode ser cortado. Use o modo normal."
			end
			status.Text = msg
		end
	else
		status.Text = "Erro: " .. tostring(texts)
	end

	busy = false
	scan.Text = "ESCANEAR NOVAMENTE"
end)
