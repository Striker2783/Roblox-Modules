--!strict

local module = {}
module.__index = module
module.IgnoreList = {}

local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DefaultSettings = {

	FlyingDebris = {
		On = true;
		AccurateRepresentation = true;
		Collision = false;
		Touch = false;
		MinAmount = 10;
		MaxAmount = 20;
		IgnoreList = true;
		DespawnTime = 2;

		Parent = workspace;

		Force = {
			MinX = -50;
			MaxX = 50;
			MinY = 50;
			MaxY = 100;
			MinZ = -50;
			MaxZ = 50;
		};

		AngularForce = {
			MinX = -100;
			MaxX = 100;
			MinY = -100;
			MaxY = 100;
			MinZ = -100;
			MaxZ = 100;
		};

		DefaultRep = {
			Color = Color3.fromRGB(68, 68, 68);
			Material = Enum.Material.Rock;
			Transparency = 0;
		}
	};

	Crater = {
		On = true;
		AccurateRepresentation = true;
		AutomaticRockAmount = true;
		RocksPerRockSize = 1.5;
		IgnoreList = true;

		Collide = false;
		Touch = false;

		CraterRockAmount = 10;
		DespawnTime = 2;

		Parent = workspace;

		Orientation = {
			MinX = -90;
			MaxX = 90;
			MinY = -90;
			MaxY = 90;
			MinZ = -90;
			MaxZ = 90;
		};

		DefaultRep = {
			Color = Color3.fromRGB(68, 68, 68);
			Material = Enum.Material.Rock;
			Transparency = 0;
		}
	};

	General = {
		DefaultRep = {
			Color = Color3.fromRGB(68, 68, 68);
			Material = Enum.Material.Rock;
			Transparency = 0;
		};
		
		RayCastIgnoresHumanoids = true
	}
}
function module.copyDefaultSettings() : Settings

	local function loop(original)
		local copy = {}
		for k, v in pairs(original) do
			if type(v) == "table" then
				v = loop(v)
			end
			copy[k] = v
		end
		return copy
	end

	return loop(DefaultSettings) :: Settings
end

function module.new()
	local self: newCrater = {
		Settings = module.copyDefaultSettings();
	};
	setmetatable(self, module)

	return self
end

function module.create(self: Crater, Position: Vector3, Radius: number, rockSize: number, RayDown: boolean?)
	self:ignorePlayerParts()
	if RayDown then
		Position = self:getRayDownPosition(Position)
	end
	
	if self.Settings.Crater.On then
		self:startCrater(Position, Radius, rockSize)
	end

	if self.Settings.FlyingDebris.On then
		self:startFlyingDebris(Position, Radius, rockSize)
	end
end

function module.ignorePlayerParts(self: Crater)
	for i,v in pairs(game.Players:GetPlayers()) do
		if not v.Character then continue end
		if table.find(self.IgnoreList, v.Character) then continue end
		table.insert(self.IgnoreList, v.Character)
	end
end

function module.rayCastDown(self: Crater, Position: Vector3) : RaycastResult?
	local RayCastParams = self:getRayCastParams()
	local Ray1 = workspace:Raycast(Position + Vector3.new(0, 1, 0), Vector3.new(0, -100, 0), RayCastParams)
	if Ray1 then
		if self.Settings.General.RayCastIgnoresHumanoids and Ray1.Instance:IsA("BasePart") and self.hasHumanoid(Ray1.Instance) then
			self:ignoreHumanoid(Ray1.Instance)
			return self:rayCastDown(Position)
		end
		return Ray1
	end
	return
end

function module.getRayDownPosition(self: Crater, Position: Vector3) : Vector3
	
	local Ray1 = self:rayCastDown(Position)
	if Ray1 then
		return Ray1.Position
	else
		return Position
	end
end

function module.ignoreHumanoid(self: Crater, Hit: BasePart)
	local Model = self.hasHumanoid(Hit)
	if not Model then return end
	assert(Model)
	
	self.addToIgnoreList(Model)
end

function module.hasHumanoid(Hit: BasePart) : Model?
	if Hit.Parent and Hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		return Hit.Parent :: Model
	end
	return
end

function module.getRayCastParams(self: Crater) : RaycastParams
	local RayCastParams = RaycastParams.new()
	RayCastParams.FilterType = Enum.RaycastFilterType.Blacklist
	RayCastParams.FilterDescendantsInstances = self.IgnoreList
	
	return RayCastParams
end

function module.startCrater(self: Crater, Position: Vector3, Radius: number, rockSize: number)

	local RockAmount = self:getRockAmount(Radius, rockSize)
	local Representation = self:getCraterRepresentation(Position)

	for i = 1, RockAmount do
		local Pos = self:getCraterRockPosiiton(Position, i, RockAmount, Radius, rockSize)

		self:createCraterRock(Pos, rockSize, Representation)
	end
end

function module.getCraterRockPosiiton(self: Crater, Position: Vector3, Number: number, rockNumber: number, Radius: number, Size: number)
	local X = math.cos(Number * Size * 360 / rockNumber) * Radius
	local Z = math.sin(Number * Size * 360 / rockNumber) * Radius
	return Position + Vector3.new(X, 0, Z)
end

function module.getRockAmount(self: Crater, Radius: number, rockSide: number) : number
	local CraterSeetings = self.Settings.Crater

	if CraterSeetings.AutomaticRockAmount then
		return self:calculateRockAmount(Radius, rockSide)
	else
		return CraterSeetings.CraterRockAmount
	end

end

function module.startFlyingDebris(self: Crater, Position: Vector3, Radius: number, rockSize: number)
	local FlyingDebrisSettings = self.Settings.FlyingDebris

	local Amount = self:calculateFlyingDebrisAmount()
	local Representation = self:getFlyingDebrisRepresentaiton(Position)

	local newPosiiton = Position + Vector3.new(0, rockSize, 0)

	for i = 1, Amount do

		local FlyingDebris = self:createFlyingDebris(newPosiiton, rockSize, Representation)

	end
end

function module.createFlyingDebris(self: Crater, Position: Vector3, Size: number, Representation: Representation) : Part
	local FlyingDebrisSettings = self.Settings.FlyingDebris

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

function module.createCraterRock(self: Crater, Position: Vector3, Size: number, Representation: Representation)
	local CraterSettings = self.Settings.Crater

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

function module.createPartWithRepresentation(self:Crater, Position: Vector3, Size: number, Representation: Representation) : Part
	local newPart = self:createDefaultPart(Position, Size)
	newPart.Material = Representation.Material
	newPart.Color = Representation.Color
	newPart.Transparency = Representation.Transparency

	return newPart
end

function module.createRandVector3(Table: Vect3) : Vector3
	local X = math.random(Table.MinX, Table.MaxX)
	local Y = math.random(Table.MinY, Table.MaxY)
	local Z = math.random(Table.MinZ, Table.MaxZ)

	return Vector3.new(X, Y, Z)
end

function module.createDefaultPart(self: Crater, Position: Vector3, Size: number) : Part
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

function module.calculateRockAmount(self: Crater, Radius: number, rockSize: number) : number
	local circumference = Radius * 2 * math.pi
	return math.ceil(circumference * self.Settings.Crater.RocksPerRockSize / rockSize)
end

function module.addToIgnoreList(Part: Instance)
	table.insert(module.IgnoreList, Part)
end

function module.calculateFlyingDebrisAmount(self: Crater) : number
	local Settings = self.Settings.FlyingDebris
	return math.random(Settings.MinAmount, Settings.MaxAmount)
end

function module.getFlyingDebrisRepresentaiton(self: Crater, Posiiton: Vector3) : Representation
	local FlyingDebrisSettings = self.Settings.FlyingDebris

	if FlyingDebrisSettings.AccurateRepresentation then
		return self:getRepresentation(Posiiton, "FlyingDebris")
	else
		return self:getDefaultRepresentation("FlyingDebris")
	end
end

function module.getCraterRepresentation(self: Crater, Position: Vector3)
	local CraterSettings = self.Settings.Crater

	if CraterSettings.AccurateRepresentation then
		return self:getRepresentation(Position, "Crater")
	else
		return self:getDefaultRepresentation("Crater")
	end
end

function module.getRepresentation(self: Crater, Position: Vector3, Part: string) : Representation
	local RayResult = self:rayCastDown(Position)
	if RayResult and RayResult.Instance:IsA("BasePart") then
		return {
			Material = RayResult.Instance.Material;
			Color = RayResult.Instance.Color;
			Transparency = RayResult.Instance.Transparency;
		}
	end

	return self:getDefaultRepresentation(Part)
end

function module.getDefaultRepresentation(self: Crater, Part: string) : Representation
	if Part == "Crater" then
		return self.Settings.Crater.DefaultRep
	elseif Part == "FlyingDebris" then
		return self.Settings.FlyingDebris.DefaultRep
	end

	return self.Settings.General.DefaultRep
end

export type Vect3 = typeof(DefaultSettings.FlyingDebris.Force)

export type Representation = {
	Material: Enum.Material;
	Color: Color3;
	Transparency: number;
}

export type Settings = typeof(DefaultSettings)

export type newCrater = {
	Settings: Settings
}

export type Crater = typeof(module.new())

return module
