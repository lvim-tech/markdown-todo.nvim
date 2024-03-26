local config = require("markdown-todo.config")
local utils = require("markdown-todo.utils")
local ui = require("markdown-todo.ui")

local ns_id = vim.api.nvim_create_namespace("lvim-markdown-utils")

local M = {}

M.toggle = function()
	if config.enabled then
		config.enabled = false
		vim.schedule(ui.clear)
	else
		config.enabled = true
		vim.schedule(ui.refresh)
	end
end

M.is_lead_char = function(line)
	for _, lead_char in ipairs(config.lead_chars) do
		local start, finish = line:find("^%s*" .. lead_char)
		if start then
			return start, finish
		end
	end
	return nil, nil
end

M.has_todo_indicator = function(line)
	local start, finish = line:find("%(%s?[%s%-_=xy!+?o]%s?%)")
	return start, finish
end

M.add_todo_indicator = function(line, itemType)
	local start, finish = M.is_lead_char(line)
	if start then
		line = line:sub(1, finish) .. " (" .. config.indicators[itemType].literal .. ")" .. line:sub(finish + 1)
	end
	return line
end

M.update_todo_indicator = function(line, itemType)
	local todo_indicator_index = M.has_todo_indicator(line)
	if todo_indicator_index then
		line = line:sub(1, todo_indicator_index - 1)
			.. "("
			.. config.indicators[itemType].literal
			.. ")"
			.. line:sub(todo_indicator_index + 3)
	end
	return line
end

M.should_hide_icons = function()
	local line_num = vim.fn.line(".") - 1
	return line_num
end

M.hide_virtual_icons = function(line_num)
	local extmarks = vim.api.nvim_buf_get_extmarks(0, ns_id, { line_num, 0 }, { line_num + 1, 0 }, {})
	for _, extmark in ipairs(extmarks) do
		vim.api.nvim_buf_del_extmark(0, ns_id, extmark[1])
	end
end

M.set_virtual_icon = function(indicator_index, itemType, line_num)
	-- before setting new icons, clear existing ones
	M.hide_virtual_icons(line_num)
	vim.api.nvim_buf_set_extmark(0, ns_id, line_num, indicator_index, {
		-- virt_text = { { config.indicators[itemType].icon, config.indicators[itemType].hl } },
		virt_text = { { config.indicators[itemType].icon } },
		hl_mode = "combine",
		virt_text_pos = "overlay",
	})
end

M.bind_keys = function()
	vim.keymap.set("n", config.keys.undone, function()
		require("markdown-todo").make_todo("undone")
	end, { buffer = 0, desc = "Mark as Undone" })
	vim.keymap.set("n", config.keys.pending, function()
		require("markdown-todo").make_todo("pending")
	end, { buffer = 0, desc = "Mark as Pending" })
	vim.keymap.set("n", config.keys.done, function()
		require("markdown-todo").make_todo("done")
	end, { buffer = 0, desc = "Mark as Done" })
	vim.keymap.set("n", config.keys.on_hold, function()
		require("markdown-todo").make_todo("on_hold")
	end, { buffer = 0, desc = "Mark as On Hold" })
	vim.keymap.set("n", config.keys.cancelled, function()
		require("markdown-todo").make_todo("cancelled")
	end, { buffer = 0, desc = "Mark as Cancelled" })
	vim.keymap.set("n", config.keys.important, function()
		require("markdown-todo").make_todo("important")
	end, { buffer = 0, desc = "Mark as Important" })
	vim.keymap.set("n", config.keys.recurring, function()
		require("markdown-todo").make_todo("recurring")
	end, { buffer = 0, desc = "Mark as Recurring" })
	vim.keymap.set("n", config.keys.ambiguous, function()
		require("markdown-todo").make_todo("ambiguous")
	end, { buffer = 0, desc = "Mark as Ambiguous" })
	vim.keymap.set("n", config.keys.on_going, function()
		require("markdown-todo").make_todo("on_going")
	end, { buffer = 0, desc = "Mark as On Going" })
end

M.set_hl = function()
	for _, indicator in pairs(config.indicators) do
		vim.fn.matchadd(indicator.hl, "(\\V" .. indicator.literal .. ")")
	end
end

M.set_virtual_icons = function()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for i, line in ipairs(lines) do
		local indicator_index = M.has_todo_indicator(line)
		if indicator_index then
			local indicator_char = line:sub(indicator_index + 1, indicator_index + 1)
			for itemType, indicator in pairs(config.indicators) do
				if indicator.literal == indicator_char then
					M.set_virtual_icon(indicator_index, itemType, i - 1)
					break
				end
			end
		end
	end
end

M.augroup = function(name)
	return vim.api.nvim_create_augroup("markdown-todo_" .. name, { clear = true })
end

M.make_todo = function(itemType)
	local line = vim.api.nvim_get_current_line()
	local start = M.is_lead_char(line)
	if start then
		if M.has_todo_indicator(line) then
			line = M.update_todo_indicator(line, itemType)
		else
			line = M.add_todo_indicator(line, itemType)
		end
		vim.api.nvim_set_current_line(line)
		local indicator_index = M.has_todo_indicator(line)
		if not indicator_index then
			vim.api.nvim_err_writeln("Failed to add todo indicator")
			return false
		end
		local line_num = vim.fn.line(".") - 1
		M.set_virtual_icon(indicator_index, itemType, line_num)
		return true
	else
		return false
	end
end

M.setup = function(user_config)
	if user_config ~= nil then
		utils.merge(config, user_config)
	end

	config.enabled = true
	config.md_query = vim.treesitter.query.parse("markdown", config.markdown_query)

	vim.schedule(ui.refresh)

	vim.api.nvim_create_autocmd({
		"FileChangedShellPost",
		"ModeChanged",
		"Syntax",
		"TextChanged",
		"WinResized",
	}, {
		group = vim.api.nvim_create_augroup("RenderMarkdown", { clear = true }),
		callback = function()
			vim.schedule(ui.refresh)
		end,
	})

	vim.api.nvim_create_user_command(
		"RenderMarkdownToggle",
		M.toggle,
		{ desc = "Switch between enabling & disabling render markdown plugin" }
	)
	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		group = M.augroup("set_hl"),
		pattern = { "*.md" },
		callback = M.set_hl,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = M.augroup("bind_keys"),
		pattern = { "*.md" },
		callback = M.bind_keys,
	})

	vim.api.nvim_create_autocmd({
		"InsertEnter",
	}, {
		group = M.augroup("hide_virtual_icons"),
		pattern = { "*.md" },
		callback = function()
			local line = M.should_hide_icons()
			if line then
				M.hide_virtual_icons(line)
			end
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = M.augroup("set_virtual_icons"),
		pattern = { "*.md" },
		callback = M.set_virtual_icons,
	})
end

return M
