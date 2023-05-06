--[[
Made by Striker2783
]]

local module: Crater = {}
module.__index = module
-- Things to ignore when raycasting
module.IgnoreList = {}

export type ICrater = {
	settings: Settings,
	create: (self: Crater, Position: Vector3, Radius: number, rockSize: number) -> (),
}

local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DefaultSettings = {
	-- Settings for Flying Debris
	FlyingDebris = {
		-- Enabled/Disabled
		On = true,
		-- The Rocks match the ground
		AccurateRepresentation = true,
		-- Collision on those Rocks
		Collision = false,
		-- CanTouch on those Rocks
		Touch = false,
		-- Minimum amount of rocks
		MinAmount = 10,
		-- Maximum amount of rocks
		MaxAmount = 20,
		-- Whether to add the rocks to the ignore list
		IgnoreList = true,
		-- Despawn time for the rocks
		DespawnTime = 2,
		-- Parent for those rocks
		Parent = workspace,
		-- Force of those rocks
		Force = {
			MinX = -50,
			MaxX = 50,
			MinY = 50,
			MaxY = 100,
			MinZ = -50,
			MaxZ = 50,
		},
		-- Force of Spin of those rocks
		AngularForce = {
			MinX = -100,
			MaxX = 100,
			MinY = -100,
			MaxY = 100,
			MinZ = -100,
			MaxZ = 100,
		},
		-- Default Representation of the rock
		DefaultRep = {
			Color = Color3.fromRGB(68, 68, 68),
			Material = Enum.Material.Rock,
			Transparency = 0,
		},
	},
	-- Settings for the crater
	Crater = {
		-- Turns on the crater
		On = true,
		-- Makes the rocks match the ground
		AccurateRepresentation = true,
		-- Automatically adjusts rock amount based on RocksPerRockSize
		AutomaticRockAmount = true,
		-- The number of rocks per size specified
		RocksPerRockSize = 1.5,
		-- Whether to add the rocks to the ignore list
		IgnoreList = true,
		-- Crater Rocks Collide
		Collide = false,
		-- Can Touch For Rocks
		Touch = false,
		-- Number of rocks if automatic is disabled
		CraterRockAmount = 10,
		-- Despawn Time For the Rocks
		DespawnTime = 2,
		-- Crater is always on the ground
		AlwaysOnGround = true,
		-- Max elevation to check for the crater
		MaxElevation = 20,
		-- Parent of the rocks
		Parent = workspace,
		-- Orientation of the rocks
		Orientation = {
			MinX = -90,
			MaxX = 90,
			MinY = -90,
			MaxY = 90,
			MinZ = -90,
			MaxZ = 90,
		},
		-- Default crater representation
		DefaultRep = {
			Color = Color3.fromRGB(68, 68, 68),
			Material = Enum.Material.Rock,
			Transparency = 0,
		},
	},
	-- Other settings
	General = {
		-- Default Representation in general
		DefaultRep = {
			Color = Color3.fromRGB(68, 68, 68),
			Material = Enum.Material.Rock,
			Transparency = 0,
		},
		-- Whether the ray cast ignores humanoid or not
		RayCastIgnoresHumanoids = true,
		Ray = true,
		RayDirection = Vector3.new(0, -1, 0),
		RayLength = 100,
	},
}
local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end
-- Copies the settings of the crater module
function module:copySettings()
	return module.copySetting(self.settings)
end
-- Copies the settings
function module.copySetting(settings: Settings)
	return deepCopy(settings) :: Settings
end
-- Copies the default settings
function module.copyDefaultSettings(): Settings
	return deepCopy(DefaultSettings) :: Settings
end
-- Creates a new Crater object
function module.new(): ICrater
	local self: init = {
		settings = module.copyDefaultSettings(),
	}
	setmetatable(self, module)

	return self
end

-- Creates a new Crater object with the settings provided
function module.newWithSettings(settings: Settings): ICrater
	local self: init = {
		settings = settings,
	}
	setmetatable(self, module)

	return self
end
-- Loads the settings for the crater object
function module:loadSettings(settings: Settings)
	self.settings = settings
end
-- Creates the crater, flying debris, and other stuff
function module:create(Position: Vector3, Radius: number, rockSize: number, Ray: boolean?)
	self:ignorePlayerParts()
	if self.settings.General.Ray then
		Position = self:getRayPosition(Position)
	end

	if self.settings.Crater.On then
		self:startCrater(Position, Radius, rockSize)
	end
	if self.settings.FlyingDebris.On then
		self:startFlyingDebris(Position, Radius, rockSize)
	end
end
-- Ignores Player Parts
function module:ignorePlayerParts()
	for i, v in pairs(game.Players:GetPlayers()) do
		if not v.Character then
			continue
		end
		if table.find(self.IgnoreList, v.Character) then
			continue
		end
		table.insert(self.IgnoreList, v.Character)
	end
end
-- Ray Casts
function module:rayCast(Position: Vector3): RaycastResult?
	local RayCastParams = self:getRayCastParams()
	local Ray1 = workspace:Raycast(
		Position + Vector3.new(0, self.settings.Crater.MaxElevation, 0),
		self.settings.General.RayDirection * self.settings.General.RayLength,
		RayCastParams
	)
	if Ray1 then
		if
			self.settings.General.RayCastIgnoresHumanoids
			and Ray1.Instance:IsA("BasePart")
			and self.hasHumanoid(Ray1.Instance)
		then
			self:ignoreHumanoid(Ray1.Instance)
			return self:rayCast(Position)
		end
		return Ray1
	end
	return
end
-- Gets the position of RayCast
function module:getRayPosition(Position: Vector3): Vector3
	local Ray1 = self:rayCast(Position)
	if Ray1 then
		return Ray1.Position
	else
		return Position
	end
end
-- Ignores humanoid
function module:ignoreHumanoid(Hit: BasePart)
	local Model = self.hasHumanoid(Hit)
	if not Model then
		return
	end
	assert(Model)

	self.addToIgnoreList(Model)
end
-- Checks whether the part has a humanoid or not
function module.hasHumanoid(Hit: BasePart): Model?
	if Hit.Parent and Hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		return Hit.Parent :: Model
	end
	return
end
-- Gets a new RayCastParams
function module:getRayCastParams(): RaycastParams
	local RayCastParams = RaycastParams.new()
	RayCastParams.FilterType = Enum.RaycastFilterType.Blacklist
	RayCastParams.FilterDescendantsInstances = self.IgnoreList

	return RayCastParams
end
-- Starts the crater
function module:startCrater(Position: Vector3, Radius: number, rockSize: number)
	local rockAmount = self:getRockAmount(Radius, rockSize)
	local representation = self:getCraterRepresentation(Position)

	for i = 1, rockAmount do
		local pos = self:getCraterRockPosiiton(Position, i, rockAmount, Radius)
		if self.settings.Crater.AlwaysOnGround then
			representation = self:getCraterRepresentation(pos)
			local Ray1 = self:rayCast(pos)
			if Ray1 then
				pos = Vector3.new(pos.X, Ray1.Position.Y, pos.Z)
			end
		end
		self:createCraterRock(pos, rockSize, representation)
	end
end
-- Gets the rock pos based on its arguments
function module:getCraterRockPosiiton(Position: Vector3, ith: number, rockNumber: number, Radius: number)
	local percent = ith / rockNumber
	local revolution = 2 * math.pi
	local X = math.cos(revolution * percent) * Radius
	local Z = math.sin(revolution * percent) * Radius
	local newPos = Position + Vector3.new(X, 0, Z)
	return newPos
end
-- Gets the amount of crater rocks to make
function module:getRockAmount(Radius: number, rockSide: number): number
	local CraterSeetings = self.settings.Crater

	if CraterSeetings.AutomaticRockAmount then
		return self:calculateRockAmount(Radius, rockSide)
	else
		return CraterSeetings.CraterRockAmount
	end
end
-- Creates the FlyingDebris
function module:startFlyingDebris(Position: Vector3, Radius: number, rockSize: number)
	local FlyingDebrisSettings = self.settings.FlyingDebris

	local Amount = self:calculateFlyingDebrisAmount()
	local Representation = self:getFlyingDebrisRepresentaiton(Position)

	local newPosiiton = Position + Vector3.new(0, rockSize, 0)

	for i = 1, Amount do
		local FlyingDebris = self:createFlyingDebris(newPosiiton, rockSize, Representation)
	end
end
-- Creates a FlyingDebris rock
function module:createFlyingDebris(Position: Vector3, Size: number, Representation: Representation): Part
	local FlyingDebrisSettings = self.settings.FlyingDebris

	local AngularForce = self.createRandVector3(FlyingDebrisSettings.AngularForce)
	local Force = self.createRandVector3(FlyingDebrisSettings.Force)

	local newPart = self:createPartWithRepresentation(Position, Size, Representation)
	newPart.Anchored = false
	newPart.CanCollide = FlyingDebrisSettings.Collision
	newPart.CanTouch = FlyingDebrisSettings.Touch
	newPart.Name = "Debris"
	newPart.Massless = true

	newPart.Parent = FlyingDebrisSettings.Parent

	newPart:ApplyImpulse(Force * newPart:GetMass())
	newPart:ApplyAngularImpulse(AngularForce * newPart:GetMass())

	Debris:AddItem(newPart, FlyingDebrisSettings.DespawnTime)

	if FlyingDebrisSettings.IgnoreList then
		self.addToIgnoreList(newPart)
	end

	return newPart
end
-- Creates a crater rock
function module:createCraterRock(Position: Vector3, Size: number, Representation: Representation)
	local CraterSettings = self.settings.Crater

	local newPart = self:createPartWithRepresentation(Position, Size, Representation)
	newPart.Anchored = true
	newPart.CanCollide = CraterSettings.Collide
	newPart.CanTouch = CraterSettings.Touch
	newPart.Name = "Debris"
	newPart.Massless = true
	newPart.Orientation = self.createRandVector3(CraterSettings.Orientation)

	newPart.Parent = CraterSettings.Parent

	Debris:AddItem(newPart, CraterSettings.DespawnTime)

	if CraterSettings.IgnoreList then
		self.addToIgnoreList(newPart)
	end
end
-- Creates a part with the representation
function module:createPartWithRepresentation(Position: Vector3, Size: number, Representation: Representation): Part
	local newPart = self:createDefaultPart(Position, Size)
	newPart.Material = Representation.Material
	newPart.Color = Representation.Color
	newPart.Transparency = Representation.Transparency

	return newPart
end
local function floatRandom(min, max)
	return math.random() * (max - min) + min
end
-- Creates a random vector3 value based on Vect3
function module.createRandVector3(Table: Vect3): Vector3
	local X = floatRandom(Table.MinX, Table.MaxX)
	local Y = floatRandom(Table.MinY, Table.MaxY)
	local Z = floatRandom(Table.MinZ, Table.MaxZ)

	return Vector3.new(X, Y, Z)
end
-- Creates a part with default settings
function module:createDefaultPart(Position: Vector3, Size: number): Part
	local newPart = Instance.new("Part")
	newPart.Position = Position
	newPart.TopSurface = Enum.SurfaceType.Smooth
	newPart.BottomSurface = Enum.SurfaceType.Smooth
	newPart.CanCollide = false
	newPart.CanTouch = false
	newPart.Anchored = true

	newPart.Size = Vector3.new(Size, Size, Size)

	return newPart
end
-- Calculates number of rocks in the crater
function module:calculateRockAmount(Radius: number, rockSize: number): number
	local circumference = Radius * 2 * math.pi
	return math.ceil(circumference * self.settings.Crater.RocksPerRockSize / rockSize)
end
-- Adds this to the ignoreList
function module.addToIgnoreList(Part: Instance)
	table.insert(module.IgnoreList, Part)
end

function module:calculateFlyingDebrisAmount(): number
	local Settings = self.settings.FlyingDebris
	return math.random(Settings.MinAmount, Settings.MaxAmount)
end

function module:getFlyingDebrisRepresentaiton(Posiiton: Vector3): Representation
	local FlyingDebrisSettings = self.settings.FlyingDebris

	if FlyingDebrisSettings.AccurateRepresentation then
		return self:getRepresentation(Posiiton, "FlyingDebris")
	else
		return self:getDefaultRepresentation("FlyingDebris")
	end
end

function module:getCraterRepresentation(Position: Vector3)
	local CraterSettings = self.settings.Crater

	if CraterSettings.AccurateRepresentation then
		return self:getRepresentation(Position, "Crater")
	else
		return self:getDefaultRepresentation("Crater")
	end
end

function module:getRepresentation(Position: Vector3, Part: string): Representation
	local RayResult = self:rayCast(Position)
	if RayResult and RayResult.Instance:IsA("BasePart") then
		return {
			Material = RayResult.Instance.Material,
			Color = RayResult.Instance.Color,
			Transparency = RayResult.Instance.Transparency,
		}
	end

	return self:getDefaultRepresentation(Part)
end

function module:getDefaultRepresentation(Part: string): Representation
	if Part == "Crater" then
		return self.settings.Crater.DefaultRep
	elseif Part == "FlyingDebris" then
		return self.settings.FlyingDebris.DefaultRep
	end

	return self.settings.General.DefaultRep
end

export type Vect3 = typeof(DefaultSettings.FlyingDebris.Force)

export type Representation = {
	Material: Enum.Material,
	Color: Color3,
	Transparency: number,
}

export type Settings = typeof(DefaultSettings)

export type init = {
	settings: Settings,
}

export type Crater = typeof(module) & init

return {
	copyDefaultSettings = module.copyDefaultSettings,
	copySettings = module.copySetting,
	new = module.new,
	newWithSettings = module.newWithSettings,
	addToIgnoreList = module.addToIgnoreList,
}
