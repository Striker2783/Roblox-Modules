--!strict

local module = {}


function module.createPart(Parent: Instance, Position: Vector3)
	local newPart: Part = Instance.new("Part")
	newPart.Anchored = true
	newPart.Size = Vector3.new(1, 1, 1)
	newPart.Position = Position
	newPart.Transparency = .5
	newPart.Parent = Parent
	
	return newPart
end

return module
