local module = {}

function module.randomFloat(min: number, max: number)
	return math.random() * (max - min) - min
end

return {
	randomFloat = module.randomFloat,
}
