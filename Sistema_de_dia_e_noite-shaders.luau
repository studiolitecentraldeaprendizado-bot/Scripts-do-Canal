

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- CONFIGURAÇÕES
local CICLO_SEGUNDOS = 600   -- duração de 1 dia completo (600 = 10 min)
local HORA_INICIAL = 17.0    --( começa quase no pôr do sol )
local FREQUENCIA = 1 / 30    -- atualizações por segundo (leve p/ mobile)

local C = Color3.fromRGB

--  KEYFRAMES (hora do dia → visual)
local KEYS = {
	-- 00:00 MEIA-NOITE
	{ h = 0,
		Amb = C(18, 22, 45), Out = C(35, 45, 90), Top = C(90, 110, 190), Bot = C(10, 12, 30),
		Fog = C(10, 14, 34), FogEnd = 2600, Bri = 0.6, Exp = -0.1,
		AD = 0.32, AO = 0, AC = C(40, 55, 115), ADe = C(15, 20, 50), AG = 0, AH = 1.2,
		CB = 0, CCo = 0.12, CS = 0.1, CT = C(205, 220, 255),
		BI = 0.7, BS = 30, BT = 1.1, RI = 0.0, RS = 0.4,
		Stars = 3000, SunSz = 21, CCov = 0.45, CDen = 0.4, CCol = C(45, 55, 100) },
	-- 04:30 ANTES DO AMANHECER
	{ h = 4.5,
		Amb = C(40, 40, 85), Out = C(75, 75, 130), Top = C(130, 105, 170), Bot = C(30, 30, 70),
		Fog = C(55, 55, 105), FogEnd = 3200, Bri = 0.8, Exp = 0,
		AD = 0.36, AO = 0.05, AC = C(95, 95, 160), ADe = C(130, 80, 130), AG = 0.2, AH = 1.5,
		CB = 0, CCo = 0.1, CS = 0.15, CT = C(225, 220, 255),
		BI = 0.8, BS = 34, BT = 1.0, RI = 0.03, RS = 0.6,
		Stars = 1600, SunSz = 22, CCov = 0.5, CDen = 0.45, CCol = C(120, 95, 150) },
	-- 05:40 ALVORADA
	{ h = 5.6,
		Amb = C(115, 80, 105), Out = C(155, 110, 125), Top = C(255, 150, 105), Bot = C(95, 60, 105),
		Fog = C(235, 150, 135), FogEnd = 4000, Bri = 1.4, Exp = 0.05,
		AD = 0.4, AO = 0.1, AC = C(255, 170, 135), ADe = C(255, 120, 100), AG = 0.7, AH = 2.2,
		CB = 0, CCo = 0.1, CS = 0.22, CT = C(255, 225, 215),
		BI = 1.0, BS = 40, BT = 0.9, RI = 0.15, RS = 0.85,
		Stars = 250, SunSz = 30, CCov = 0.55, CDen = 0.5, CCol = C(255, 150, 125) },
	-- 06:50 NASCER DO SOL DOURADO
	{ h = 6.8,
		Amb = C(140, 120, 125), Out = C(175, 150, 155), Top = C(255, 195, 125), Bot = C(120, 100, 115),
		Fog = C(255, 205, 165), FogEnd = 5500, Bri = 2.4, Exp = 0.05,
		AD = 0.36, AO = 0.15, AC = C(255, 205, 165), ADe = C(255, 150, 100), AG = 0.5, AH = 1.6,
		CB = 0, CCo = 0.08, CS = 0.2, CT = C(255, 238, 222),
		BI = 0.8, BS = 36, BT = 1.0, RI = 0.22, RS = 1.0,
		Stars = 0, SunSz = 26, CCov = 0.5, CDen = 0.55, CCol = C(255, 205, 175) },
	-- 09:00 MANHÃ
	{ h = 9,
		Amb = C(130, 140, 160), Out = C(160, 170, 190), Top = C(255, 245, 228), Bot = C(150, 160, 180),
		Fog = C(190, 212, 238), FogEnd = 7000, Bri = 3.0, Exp = 0,
		AD = 0.32, AO = 0.25, AC = C(190, 212, 242), ADe = C(255, 232, 205), AG = 0.2, AH = 1.0,
		CB = 0, CCo = 0.05, CS = 0.1, CT = C(255, 250, 242),
		BI = 0.35, BS = 24, BT = 1.8, RI = 0.08, RS = 0.6,
		Stars = 0, SunSz = 21, CCov = 0.5, CDen = 0.55, CCol = C(255, 255, 255) },
	-- 12:00 MEIO-DIA
	{ h = 12,
		Amb = C(150, 160, 180), Out = C(180, 190, 212), Top = C(255, 255, 250), Bot = C(170, 180, 200),
		Fog = C(200, 222, 248), FogEnd = 8500, Bri = 3.5, Exp = 0,
		AD = 0.3, AO = 0.25, AC = C(180, 206, 242), ADe = C(232, 238, 248), AG = 0, AH = 0.8,
		CB = 0, CCo = 0.05, CS = 0.12, CT = C(255, 255, 255),
		BI = 0.3, BS = 24, BT = 1.9, RI = 0.05, RS = 0.5,
		Stars = 0, SunSz = 21, CCov = 0.5, CDen = 0.6, CCol = C(255, 255, 255) },
	-- 16:00 TARDE
	{ h = 16,
		Amb = C(145, 150, 170), Out = C(175, 180, 200), Top = C(255, 248, 225), Bot = C(160, 165, 185),
		Fog = C(205, 215, 235), FogEnd = 7500, Bri = 3.1, Exp = 0,
		AD = 0.33, AO = 0.22, AC = C(195, 210, 238), ADe = C(250, 230, 200), AG = 0.2, AH = 1.0,
		CB = 0, CCo = 0.06, CS = 0.14, CT = C(255, 248, 235),
		BI = 0.4, BS = 26, BT = 1.7, RI = 0.08, RS = 0.6,
		Stars = 0, SunSz = 22, CCov = 0.5, CDen = 0.55, CCol = C(255, 252, 245) },
	-- 17:40 HORA DOURADA
	{ h = 17.6,
		Amb = C(150, 120, 112), Out = C(192, 152, 132), Top = C(255, 205, 135), Bot = C(140, 110, 122),
		Fog = C(255, 205, 155), FogEnd = 5500, Bri = 2.7, Exp = 0.05,
		AD = 0.38, AO = 0.18, AC = C(255, 205, 155), ADe = C(255, 145, 85), AG = 0.6, AH = 1.8,
		CB = 0, CCo = 0.1, CS = 0.26, CT = C(255, 236, 212),
		BI = 0.8, BS = 36, BT = 1.0, RI = 0.2, RS = 0.9,
		Stars = 0, SunSz = 27, CCov = 0.55, CDen = 0.55, CCol = C(255, 195, 145) },
	-- 18:30 PÔR DO SOL
	{ h = 18.5,
		Amb = C(125, 82, 102), Out = C(175, 112, 122), Top = C(255, 130, 82), Bot = C(92, 60, 102),
		Fog = C(255, 140, 112), FogEnd = 4200, Bri = 1.7, Exp = 0.1,
		AD = 0.42, AO = 0.2, AC = C(255, 150, 112), ADe = C(255, 90, 72), AG = 0.95, AH = 2.4,
		CB = 0, CCo = 0.13, CS = 0.32, CT = C(255, 215, 200),
		BI = 1.15, BS = 44, BT = 0.85, RI = 0.26, RS = 1.0,
		Stars = 100, SunSz = 34, CCov = 0.6, CDen = 0.6, CCol = C(255, 112, 92) },
	-- 19:25 CREPÚSCULO
	{ h = 19.4,
		Amb = C(70, 60, 112), Out = C(102, 80, 142), Top = C(205, 112, 152), Bot = C(50, 40, 92),
		Fog = C(152, 92, 132), FogEnd = 3400, Bri = 0.9, Exp = 0.05,
		AD = 0.4, AO = 0.1, AC = C(152, 102, 162), ADe = C(202, 82, 122), AG = 0.35, AH = 2.0,
		CB = 0, CCo = 0.12, CS = 0.22, CT = C(235, 215, 255),
		BI = 0.95, BS = 38, BT = 0.95, RI = 0.08, RS = 0.7,
		Stars = 1500, SunSz = 26, CCov = 0.55, CDen = 0.5, CCol = C(172, 102, 152) },
	-- 21:00 NOITE
	{ h = 21,
		Amb = C(20, 24, 48), Out = C(36, 46, 92), Top = C(92, 112, 192), Bot = C(10, 12, 30),
		Fog = C(11, 15, 36), FogEnd = 2600, Bri = 0.6, Exp = -0.1,
		AD = 0.32, AO = 0, AC = C(42, 57, 117), ADe = C(15, 20, 50), AG = 0, AH = 1.2,
		CB = 0, CCo = 0.12, CS = 0.1, CT = C(205, 220, 255),
		BI = 0.7, BS = 30, BT = 1.1, RI = 0.0, RS = 0.4,
		Stars = 3000, SunSz = 21, CCov = 0.45, CDen = 0.4, CCol = C(45, 55, 100) },
}

-- fecha o ciclo (24h = 0h)
do
	local primeiro = KEYS[1]
	local copia = {}
	for k, v in pairs(primeiro) do copia[k] = v end
	copia.h = 24
	table.insert(KEYS, copia)
end

--  CRIA / PEGA OS EFEITOS
local function pegar(classe, nome, pai)
	local obj = pai:FindFirstChildOfClass(classe)
	if not obj then
		obj = Instance.new(classe)
		obj.Name = nome
		obj.Parent = pai
	end
	return obj
end

local atmosfera = pegar("Atmosphere", "DynoAtmosphere", Lighting)
local cor = pegar("ColorCorrectionEffect", "DynoColor", Lighting)
local bloom = pegar("BloomEffect", "DynoBloom", Lighting)
local raios = pegar("SunRaysEffect", "DynoSunRays", Lighting)
local ceu = pegar("Sky", "DynoSky", Lighting)
local nuvens = pegar("Clouds", "DynoClouds", workspace.Terrain)

ceu.MoonAngularSize = 14
ceu.CelestialBodiesShown = true
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1
Lighting.ShadowSoftness = 0.35
Lighting.GeographicLatitude = 20
Lighting.FogStart = 0
atmosfera.Glare = 0

--  INTERPOLAÇÃO SUAVE
local function misturar(a, b, t)
	if typeof(a) == "Color3" then
		return a:Lerp(b, t)
	end
	return a + (b - a) * t
end

local function amostrar(hora)
	for i = 1, #KEYS - 1 do
		local a, b = KEYS[i], KEYS[i + 1]
		if hora >= a.h and hora <= b.h then
			local t = (hora - a.h) / (b.h - a.h)
			t = t * t * (3 - 2 * t) -- smoothstep
			local r = {}
			for k, v in pairs(a) do
				if k ~= "h" then
					r[k] = misturar(v, b[k], t)
				end
			end
			return r
		end
	end
	return KEYS[1]
end

local function set(obj, prop, valor)
	if obj[prop] ~= valor then
		obj[prop] = valor
	end
end

--  APLICA TUDO
local function aplicar(hora)
	local v = amostrar(hora)

	Lighting.ClockTime = hora
	Lighting.Ambient = v.Amb
	Lighting.OutdoorAmbient = v.Out
	Lighting.ColorShift_Top = v.Top
	Lighting.ColorShift_Bottom = v.Bot
	Lighting.FogColor = v.Fog
	Lighting.FogEnd = v.FogEnd
	Lighting.Brightness = v.Bri
	Lighting.ExposureCompensation = v.Exp

	atmosfera.Density = v.AD
	atmosfera.Offset = v.AO
	atmosfera.Color = v.AC
	atmosfera.Decay = v.ADe
	atmosfera.Glare = v.AG
	atmosfera.Haze = v.AH

	cor.Brightness = v.CB
	cor.Contrast = v.CCo
	cor.Saturation = v.CS
	cor.TintColor = v.CT

	bloom.Intensity = v.BI
	bloom.Size = v.BS
	bloom.Threshold = v.BT

	raios.Intensity = v.RI
	raios.Spread = v.RS

	-- estrelas em degraus de 50 (evita recriar o céu toda hora)
	set(ceu, "StarCount", math.floor(v.Stars / 50 + 0.5) * 50)
	ceu.SunAngularSize = v.SunSz

	nuvens.Cover = v.CCov
	nuvens.Density = v.CDen
	nuvens.Color = v.CCol
end

-- LOOP (sincronizado entre todos os jogadores)
local acumulado = 0
RunService.RenderStepped:Connect(function(dt)
	acumulado += dt
	if acumulado < FREQUENCIA then return end
	acumulado = 0

	local fixa = workspace:GetAttribute("HoraFixa")
	local hora
	if typeof(fixa) == "number" then
		hora = fixa % 24
	else
		local progresso = (workspace:GetServerTimeNow() / CICLO_SEGUNDOS) % 1
		hora = (HORA_INICIAL + progresso * 24) % 24
	end
	aplicar(hora)
end)
