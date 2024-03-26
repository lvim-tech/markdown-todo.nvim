local M = {}

M.cycle = function(values, index)
	return values[((index - 1) % #values) + 1]
end

M.clamp_last = function(values, index)
	return values[math.min(index, #values)]
end

return M
