local M = {}

M.merge = function(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k] or false) == "table") then
			if M.is_array(t1[k]) then
				t1[k] = M.concat(t1[k], v)
			else
				M.merge(t1[k], t2[k])
			end
		else
			t1[k] = v
		end
	end
	return t1
end

M.concat = function(t1, t2)
	for i = 1, #t2 do
		table.insert(t1, t2[i])
	end
	return t1
end

M.is_array = function(t)
	local i = 0
	for _ in pairs(t) do
		i = i + 1
		if t[i] == nil then
			return false
		end
	end
	return true
end

M.parser_installed = function(name)
	local ok = pcall(vim.treesitter.query.parse, name, "")
	if ok then
		vim.health.ok(name .. " parser installed")
	else
		vim.health.error(name .. " parser not found")
	end
end

M.check_parser = function()
	vim.health.start("Checking required treesitter parsers")
	M.parser_installed("markdown")
end

return M
